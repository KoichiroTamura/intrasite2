=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

#=概要
# 添付ファイルの受信・送信を行う。
#
#=受信 (ダウンロード)
#==URL
# http://[hostname]/attached_files/show/[checksum]
#==制限
#===checksumの与え方
# [checksum]はUUIDTOOLSにより生成され、テーブルattached_files内で唯一の値となる。
# (時間無考慮)
#===セキュリティ
# ダウンロードさせるデータを配信する前に、ログインしているユーザ情報を検討し、
# ダウンロードを認めるかを判定する。詳しくはメソッドsecurity_check参照
#===日本語扱いの不適切にともなうもの
# 標準のRailsでは、日本語の扱いに誤りかあり、文字化けを引き起こす。
#
# 問題と対策は以下の通り。
#
# * 文字コードの変換が行えない。=> jcodeライブラリのinclude
#
# * ヘッダDispositionでファイル名の文法に誤りがあるため、ファイル名で日本語が使用できない。=> ヘッダ生成メソッドをオーバーライド
#
#=送信 (アップロード)
#==URL
# http://[hostname]/attached_files/create
#==フォーム値
# * id: ファイル標識数、必須
# * file: ファイル
#==フォームのタイプ(エンコードなど)
# * method: post
# * enctype: multipart/form-data
#==アップロード完了ファイル情報取得について
# progress 参照
#==他オブジェクトの連携(リレーション)について
# 本コントローラはファイルの送受信のみである。
#
# 各オブジェクトを生成するコントローラにprogressにより得られるchecksumを渡し、
# AttachedFilesを再検索して、値を適時変更ください。
#
#= 進捗状況確認メソッド + アップロード完了ファイル情報取得
#==URL
# http://[hostname]/attached_files/progress
#==フォーム値
# * id: ファイル標識数、必須
#==フォームのタイプ(エンコードなど)
# * method: post
#== 戻り値
# JSONで以下の値が戻る
# 
# * filename: ファイル名
# * size: アップロード済ファイルサイズ
# * fullsize: ファイルの全サイズ
# * checksum: ダウンロード用checksum
#==制限
#===Railsは通常Non-threadsafe (SingleThread)
# /config/environment/環境名.rb 内で config.threadsafe! を有効にしないと、
# 途中の進捗状況を得ることはできない。
#===ブラウザ側の処理は未反映
# ブラウザがローカルファイルを読みとり、サーバへ送信している間の処理は、進捗状況に反映できない。
# 
# progressで得られる進捗状況に反映されるのは、サーバに保存するまでの処理である。
#
#=ファイルの保存場所
# * production : RAILS_ROOT/data
# * development : C:\Windows\temp または /tmp
#
# upload_folder_change 参照
#
#=更新履歴
# 2009.08.28 追加　securiy_checkの追加
# 2009.09.20 変更  ソースの品質改善
# 2009.10.01 変更　フォーラムの閲覧権限チェックを強化
# 2010.01.12 変更　エラーメッセージ改訂
# 2010.02.14 追加  アップロード機能仮実装
# 2010.02.17 追加  アップロード機能実装
# 2011.09.09 修正 セキュリティホール対策＋添付ファイルを投稿者以外が見れないバグの修正

require 'base64'
require 'jcode'
require 'uuidtools'

class AttachedFilesController < ArticleThreadsController

  skip_before_filter :find_entity
  before_filter :admin_only, :only=>{:cleaner, :clean}
    
  before_filter :upload_folder_change

  ErrorMessage="添付ファイルが破損しているか、正しくアップロードされていません"

  @UploadFileRoot

  def cleaner
  end

  def clean
    Admin::AdminAttachedFile.cleaner(0)
  end

  # 原則Indexにきた場合はshowに割り当てる
  def index
    show
  end

  # 環境別にアップロードする場所を変更する処理
  #
  #ファイルの保存場所
  #
  # * production : RAILS_ROOT/data
  # * development : C:\Windows\temp または /tmp
  def upload_folder_change
    case ENV["RAILS_ENV"]
      when "development"
        if ENV["OS"] && ENV["OS"].include?("Windows")
          @UploadFileRoot="C:/windows/temp"
        else
          @UploadFileRoot="/tmp"
        end
      when "production"
        @UploadFileRoot = "#{RAILS_ROOT}/data"
    end
  end

  # データの配信部 (ダウンロード)
  #
  # 本来であれば、ファイル名は半角英数のみで構成されている。
  # 
  # 実際は全角文字で構成されているファイル名もある。
  # これをエラーにすると、大量のファイルがダウンロード不能になるため、
  # 文字コードを変更して、ファイルの捜索をするようにしている。
  # 
  # ファイルの捜索処理は、旧intrasiteのデータを継承するためであり、現行intrasite2では、発生しない。
  def show
#   パラメータチェック
    flash_back params[:id].blank?,ErrorMessage
    
# 指定されたファイルを取得
    af=AttachedFile.find(:first,:conditions=>["checksum=?",params[:id]],:scope=>":self")
    flash_back af.blank?,ErrorMessage

# データファイルの特定
	if af.directory.include?("/")
		id = af.directory[0..af.directory.index("/")-1]
		file = af.directory[af.directory.index("/")..(af.directory).length]
	else
		id = af.directory
		file = ""
	end
    data="#{@UploadFileRoot}/#{af.directory}/#{af.filename}"
    data2="#{@UploadFileRoot}/#{id.downcase}#{file}/#{af.filename}"
    data3="#{@UploadFileRoot}/#{id.upcase}#{file}/#{af.filename}"

# セキュリティチェックに合格したら、データを配信する
    if security_check(af)
      fixed_filename=af.original_name
      begin 
        send_file(data, :type=>"application/octet-stream",:filename=>fixed_filename, :disposition=>"attachment" )
      rescue 
      # ルール違反ファイルが多すぎる !
      # いろいろと文字コードを変換して読み取る最大限の努力はすることにしよう(超力技)
        # 力技1 : 文字コードを変更してファイルをロードする ↓
        begin 
          logger.error("Can't load #{data}, so  try #{data} SJIS")
          send_file(data.tosjis,  :type=>"application/octet-stream",:filename=>fixed_filename, :disposition=>"attachment" )
        rescue 
          begin 
              logger.error("Can't load it, so  try it EUC")
              send_file(data.toeuc, :type=>"application/octet-stream", :filename=>fixed_filename, :disposition=>"attachment" )
          rescue 
            begin 
                logger.error("Can't load it, so  try it JIS")
                send_file(data.tojis, :type=>"application/octet-stream", :filename=>fixed_filename, :disposition=>"attachment" )
            rescue
		        begin 
                  logger.error("Can't load it, so  try #{data2} SJIS")
		          send_file(data2.tosjis,  :type=>"application/octet-stream",:filename=>fixed_filename, :disposition=>"attachment" )
		        rescue 
		          begin 
                      logger.error("Can't load it, so  try #{data2} EUC")
		              send_file(data2.toeuc, :type=>"application/octet-stream", :filename=>fixed_filename, :disposition=>"attachment" )
		          rescue 
		            begin 
                        logger.error("Can't load it, so  try #{data2} JIS")
		                send_file(data2.tojis, :type=>"application/octet-stream", :filename=>fixed_filename, :disposition=>"attachment" )
		            rescue
				        begin 
                          logger.error("Can't load it, so  try #{data3} SJIS")
				          send_file(data3.tosjis,  :type=>"application/octet-stream",:filename=>fixed_filename, :disposition=>"attachment" )
				        rescue 
				          begin 
                              logger.error("Can't load it, so  try #{data3} EUC")
				              send_file(data3.toeuc, :type=>"application/octet-stream", :filename=>fixed_filename, :disposition=>"attachment" )
				          rescue 
				            begin 
                                logger.error("Can't load it, so  try #{data3} JIS")
				                send_file(data3.tojis, :type=>"application/octet-stream", :filename=>fixed_filename, :disposition=>"attachment" )
				            rescue

				              # 力技2 : ファイルが読めるかどうかを確認する ↓
				              case false
				                when file_exist?(data)            
				                  logger.error("#{af.filename} not found : If this file was created at 2011 or older, please check intrasite1 https://intrasite.sist.chukyo-u.ac.jp/upload/files/#{af.directory}/#{af.filename}")
				                when file_read?(data)            
				                  logger.error("#{af.filename} not read")
				                else
				                  logger.error("send_file function error")
				              end
				              # 力技2 : ファイルが読めるかどうかを確認する ↑
				              flash_back true,ErrorMessage
		                    end
		                  end
				       end
	                end
	              end
                end
            end
          end
       end
	 end
       # 力技1 : 文字コードを変更してファイルをロードする ↑
    else
        flash_back true,ErrorMessage                   
    end
  end

  # アップロード用
  # 
  # 実際はcreate_or_update
  def create
    create_or_update
  end
  
  # これはテスト用
  def test
  end
  
  # 更新ってあるのだろうか ?
  def update
  end

  # 進捗状況または完了したファイル情報を返す
  def progress
    buf=""
    buf2=0
    param=""
#    param=params[:id] if params[:id]
    params[:id] and param=params[:id]
    
    begin
      File.open("#{@UploadFileRoot}/#{@current_user.name}/uploading#{param}.txt","rb") do |f|
        buf=f.read().split(":")
        f.close()
      end
      
      buf2 = File.lstat("#{@UploadFileRoot}/#{@current_user.name}/#{buf[2]}").size
  #    File.unlink("#{@UploadFileRoot}/#{@current_user.name}/uploading#{param}.txt") if buf[1].to_i==buf2
      buf[1].to_i==buf2 and File.unlink("#{@UploadFileRoot}/#{@current_user.name}/uploading#{param}.txt")
  
      if buf==""
        render :json=>{:err=>"true"}
      else
        render :json=>{:checksum=>buf[0],:fullsize=>buf[1],:size=>buf2,:original_name=>buf[3]}
      end
    rescue
        render :json=>{:err=>"true"}
    end
  end
  
  def af
#    render :partial=>"af"
    render :text=>""
  end

private
  # アップロード用の内部メソッド
  # 
  # 
  def create_or_update
    read_buf = 1024*1024;
    path = ""
    file = params[:file]      # ActionController::UploadedFIle
    filename = UUIDTools::UUID.random_create.to_s
    checksum = UUIDTools::UUID.random_create.to_s

    param = ""
    param = params[:id] if params[:id]

    begin
     Dir.mkdir("#{@UploadFileRoot}/#{@current_user.name}")
    rescue
    end
  
    File.open("#{@UploadFileRoot}/#{@current_user.name}/uploading#{param}.txt","wb") do |f|
        f.write("#{checksum}:#{file.size}:#{filename}:#{file.original_filename}")
        f.close()
    end

    AttachedFile.transaction do
#      af = AttachedFile.find(:all,:scope=>":self",:conditions=>["checksum=?",params[:checksum]]) if params[:checksum]
#      unless af 
#        af = AttachedFile.new
#      end
      params[:checksum] and af = AttachedFile.find(:all,:scope=>":self",:conditions=>["checksum=?",params[:checksum]])
    	!af and af = AttachedFile.new
    	
      new_af = af.attributes
    
      new_af[:original_name] = file.original_filename
      new_af[:filename] = filename
      new_af[:directory] = @current_user.name

      path = "#{@UploadFileRoot}/#{@current_user.name}/#{new_af[:filename]}"
      new_af[:checksum] = checksum

      if af.new_record?
        AttachedFile.create_run!(new_af)
      else
        af.update(@action_time,new_af)
      end
    end

   	ws = 0
    while ws.to_i < file.size.to_i do
	    File.open("#{path}","ab") { |f|
	        f.write(file.read(read_buf));
	    }
      ws = ws + read_buf
      ws = file.size.to_i unless ws.to_i < file.size.to_i
    end

#    File.unlink("#{@UploadFileRoot}/#{@current_user.name}/uploading#{param}.txt")

    render :text=>"ok"
  end

  # ファイルが存在するか。読み込みは問わない
  def file_exist?(file_name)
    result = 
      FileTest.exist?(file_name) &&
      FileTest.exist?(file_name.tosjis) && 
      FileTest.exist?(file_name.toeuc) &&
      FileTest.exist?(file_name.tojis)
    
    unless result
      result_count = Dir.glob(file_name).length +
      Dir.glob(file_name.tosjis).length + 
      Dir.glob(file_name.toeuc).length + 
      Dir.glob(file_name.tojis).length 
      
#      if result_count == 0
#        result=false
#      else
#        result=true
#      end
#      
#      return result
      return result_count!=0
    end
  end

  # ファイルが読み込めるか。
  def file_read?(file_name)
      begin
        file_utf8 = File.open(file_name)
        file_utf8.close();
      rescue
        begin
          file_sjis = File.open(file_name.tosjis)
          file_sjis.close();
        rescue
          begin
            file_euc = File.open(file_name.toeuc)
            file_euc.close();
          rescue
            begin
              file_jis = File.open(file_name.tojis)
              file_jis.close();
            rescue
              return false;
            end
          end
        end
      end
     return true;
  end

  def basic_cond(user = @current_user)    
    return receiver_cond(user), destination_cond(user), nil, nil, nil, nil,  nil
  end

#セキュリティチェック
#
#アドミンは無条件に閲覧可能
#
#=Article
# ArticleControllerに従い、送信者または宛先にある場合は送信する
#=Report
# 作成者、教員、院生は閲覧可能
#
# ただし、レポートが全公開の場合は、内部のみ全員
#=未定
# アップロードした直後は、作成者のみ閲覧可能
# 
#=その他
# ゲスト以外は閲覧可能
  def security_check(af)
    # アドミンは無条件に閲覧可能
#    return true if @current_account.role == "admin"
    @current_account.role == "admin" and return true

    case af.file_attachable_type
      when "Article"
# ArticleThreadのfind_collectionをそのまま使用
        @def_items = Def_Thread_Items 
        @attr_items = [:id, :run_id, :sender_name, :send_time,
                        :title, :content, :no_of_articles]
        @receive_mode  = ALL
        @collection = ArticleThread.find :all,
                :assert_time => "articles.created_at",
                :page       => current_page,
                :scope      => Basic_A_Net,
                :distinct   => select_items(@def_items, @attr_items),
                :order      => "articles.created_at DESC",
                :conditions => merge_conditions(nil, *basic_cond())+ " and articles.run_id=#{af.file_attachable_run_id}"    

#        if @collection.blank?
#          return false 
#        else
#          return true
#        end
        return !@collection.blank?

      when "Report"
      # レポート
      #
      # ・作成者は、原則閲覧可能。
      # ・教員は、だれでも閲覧できる。
      # ・院生は、TAということがありえるので、だれでも、閲覧できる。
      # 
      # もしかすると、TA担当外の院生がファイルを閲覧する可能性はあるが、
      # 実害はないであろう。
      # 
      # ・学生は、課題が公開されていれば、閲覧できるが、
      # 公開されていない場合は閲覧不能

        record_obj=eval("#{af.file_attachable_type}.find(:first,:conditions=>\"run_id='#{af.file_attachable_run_id}'\")")
        exercise_obj=eval("Exercise.find(:first,:conditions=>\"run_id='#{record_obj.exercise_run_id}'\")")
        unless @current_account.blank?
          if record_obj.created_by==@current_user.run_id
            return true  
          else
            case @current_user.category
              when "教職員"
                return true  
              when "院生"
                return true  
              when "学部生" 
#                if exercise_obj.is_open=true 
#                  return true
#                else
#                  return false  
#                end
                 return exercise_obj.is_open
              else
                  return false
             end
          end
        end
      when nil
      # 接続先がないトいうことはドラフト段階とおもわれる。
      # 
      # この場合は作成者のみとする。
        return af.created_by==@current_user.run_id       
      else 
     # 卒論のデータ、シラバス、課題、ユーザ情報などは、ゲスト以外であれば、取得を許可する。
       return !guest? 
    end
  end


def illegal_browser
# ブラウザがまともな実装をしてくれていれば、本当は分岐擦る必要はないが、
# IEは誤った実装をしていて、一部のブラウザがそれにひきづられている。
# このための対応 (ここから)
      if (request.env["HTTP_USER_AGENT"].include?"MSIE") && (request.env["HTTP_USER_AGENT"].include?"Win")
         # Internet Explorer for Win はシフトファイルをそのまま受け取っている。
         # 文字化けしていないことが不思議な実装であるが、これを標準と思っている節がある。
	       return true
      end
      if (request.env["HTTP_USER_AGENT"].include?"Opera") && (request.env["HTTP_USER_AGENT"].include?"Win")
         # Opera for Win もシフトファイルをそのまま受け取っている。
         # おそらく、IEコンポーネントをそのまま引きずってしまったが故とおもわれる
	       return true
      end
      return false
# (ここまで)
end

 # ファイル名の文字化け対策
  def filename_for_filename(filename)
#  	 return filename.tosjis if illegal_browser
#    return filename
    return illegal_browser ? filename.tosjis : filename 
  end

  def filename_for_rfc2311(filename)
#    flag = 3
#    flag = 1 if illegal_browser

    flag = illegal_browser ? 1 : 3

    case flag
	    when 1
	      # RFC2616通り、""で囲った文字列にする。文字コードはShiftJIS
	      # 
	      # IEがこの方式を採用しているが、マルチバイトへの対応としては間違っていると思う。
	      # 
	      # この方式に対応しているブラウザ
	      # * Microsoft Internet Explorer および 互換ブラウザ
	      # * FireFox および 互換ブラウザ
	       return filename.tosjis
	    when 2
	      # RFC2047準拠での送信方式にする．
	      # 
	      # この方式はメール用で、Webで採用しているとしたら、間違い
	      #
	      # この方式に対応しているブラウザ
	      # * Microsoft Internet Explorer および 互換ブラウザ
	      # * FireFox および 互換ブラウザ
	      return '=?UTF-8?B?'+Base64.encode64(filename).tr("\n","")+'?='
	    when 3
	      # RFC2231準拠での送信方式にする．
	      # 
	      # 本当であれば、この方式になっているべきだと考える。
	      #
	      # この方式に対応しているブラウザ
	      # * FireFox および 互換ブラウザ
	      return "UTF-8'ja'"+URI.encode(filename)
    end
  end


# ActionController::Steam にバグあり discrition マルチバイト(RFC2231)未対応
# 
# オーバーライドで対応
      def send_file_headers!(options)
        options.update(DEFAULT_SEND_FILE_OPTIONS.merge(options))
        [:length, :type, :disposition].each do |arg|
          raise ArgumentError, ":#{arg} option required" if options[arg].nil?
        end

        disposition = options[:disposition].dup || 'attachment'

		if options[:filename]
	        disposition <<= %(; filename=\"#{filename_for_filename(options[:filename])}\")
	        disposition <<= %(; filename*="#{filename_for_rfc2311(options[:filename])}") 
		end
		
        content_type = options[:type]
        if content_type.is_a?(Symbol)
          raise ArgumentError, "Unknown MIME type #{options[:type]}" unless Mime::EXTENSION_LOOKUP.has_key?(content_type.to_s)
          content_type = Mime::Type.lookup_by_extension(content_type.to_s)
        end
        content_type = content_type.to_s.strip # fixes a problem with extra '\r' with some browsers

        headers.merge!(
          'Content-Length'            => options[:length].to_s,
          'Content-Type'              => content_type,
          'Content-Disposition'       => disposition,
          'Content-Transfer-Encoding' => 'binary'
        )

        # Fix a problem with IE 6.0 on opening downloaded files:
        # If Cache-Control: no-cache is set (which Rails does by default),
        # IE removes the file it just downloaded from its cache immediately
        # after it displays the "open/save" dialog, which means that if you
        # hit "open" the file isn't there anymore when the application that
        # is called for handling the download is run, so let's workaround that
        headers['Cache-Control'] = 'private' if headers['Cache-Control'] == 'no-cache'
      end

end