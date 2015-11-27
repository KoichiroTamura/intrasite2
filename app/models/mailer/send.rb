=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

#=概要
#　メールを送信する。
#
#=動作概要
#　TMailを用いてメールの本体を作成し、Net::SMTPを使用してメールサーバにデータを送る。
#
#　ActionMailerが中でやっていることとほぼ同じだが、コードの変更をしている。
#
#日本語メールを送信するためには、ヘッダの日本語(マルチバイト)対応と
#多くのメールサーバが8bit文字を受けると混乱して文字化けをすることから、
#回避のため、JIS文字に変換するのが通例である。
# 
#しかし、ActionMailerは本文のコード変更をせず、TMailでも行われていない。
#このため、自前で作成した。
#
#=使用例
#m = Mailer::Send.new
#
#m.server = "dell.private.minfo-rela.net"
#
#                     # SMTPサーバの指定 
#
#m.to="toshy@dell.private.minfo-rela.net"
#
#                     # 宛先を決める
#
#m.from="sys@dell.private.minfo-rela.net"
#
#                     # 宛先を決める
#
#m.subject= "IntraSite パスワード設定の確認"
#
#                     # 題名を決める
#
#m.body_with_template_file("template_password_missing",{:user_name=>"テスト",:auth_code=>"Test"})
#
#                                           # テンプレートファイルから、本文作成
#
#m.send
#
#                     # 送信する
#
#=SMTP over TLS
# SMTP over TLSの場合は、enable_tlsをしてください。
# 
# このとき、tlsmailをコールするので、あらかじめ、インストールしてください。
# 
# gem install tlsmail
#
# http://d.hatena.ne.jp/zorio/20070318/1174226862
# 
#=参考資料
# codeなにがし,:Rubyで日本語メールを送信(TMail編),http://code.nanigac.com/source/view/339 
# 
# 2010.01.13 機能拡張
#
class Mailer::Send < Mailer::Base
  require 'net/smtp'
  require "jcode"
  require "uuidtools"

  Template_Path = "#{RAILS_ROOT}/app/models/mailer/template/"

  # SMTPサーバを指定。インスタンスの初期値はlocalhost
  @smtpServer
  # ポート番号。インスタンスの初期値は25。
  @smtpPort
  # SMTPで認証が必要な場合、そのユーザ名
  # インスタンスの初期値はなし
  @smtpUser
  # SMTPで認証が必要な場合、そのパスワード
  # インスタンスの初期値はなし
  @smtpPassword
  # SMTPで認証が必要な場合、その認証方式。通常はPLAIN
  @smtpAuth
  # メール本体の部分。TMailを使用
  @TMailObj
  # HELOで使用するホスト名。通常は自ホスト名を利用するが、localhostでも可の場所が多い
  # インスタンスの初期値はlocalhost
  @hostName
  # 宛先 (配列可)
  # インスタンスの初期値はなし
  @sendTo
  # 送信元。存在するアドレスでないとSMTPサーバが蹴る可能性があるので注意
  # インスタンスの初期値はなし
  @sendFrom
  # SMTPで認証が必要な場合、そのユーザ名
  # インスタンスの初期値はなし

  #概要: インスタンスの生成。
  #
  #省略: 不可
  #
  #パラメータ: なし
  def initialize
    @smtpServer = "localhost"
    @smtpPort = 25
    @hostName = @smtpServer
    @TMailObj = TMail::Mail.new
    @TMailObj.content_type="text/plain; charset=iso-2022-jp"
    @TMailObj.content_transfer_encoding="7bit"
    begin
    require "tlsmail" 
      Net::SMTP.disable_tls()
    rescue
    end
  end
  
  #概要: SMTP orver TLSに対応する
  #
  #パラメータ: なし
  #
  #戻り値: なし
  #
  #設定をSMTP over TLS向けに修正します。
  #
  #ポート番号が465でないばあいは、port= メソッドで変更してください
  #
  # tlsmailが必要
  def enable_tls
      require "tlsmail" 
      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      @smtpPort=465
  end

  def enable_tls=(val)
  	enable_tls
  end
  
  #概要: SMTP over TLSを無効にする
  #
  #ポート番号が25でないばあいは、port= メソッドで変更してください
  #
  def disable_tls
    require "tlsmail" 
      Net::SMTP.disable_tls()
      @smtpPort=25
  end
  def disable_tls=(val)
  	disable_tls
  end
  
  #概要: メールを送信する
  #
  #省略: 可
  #
  #パラメータ: なし
  #
  #メールサーバにデータを送信する。
  #
  #失敗するとNet::SMTPの例外が発生する。
  # http://www.ruby-lang.org/ja/man/html/net_smtp.html
  def send
    @TMailObj.message_id = "<" + UUIDTools::UUID.timestamp_create.to_s+"@webapp."+@hostName + ">"
#    return "sendTo Unset : Where do I send mail ?" if @sendTo.blank?
    @sendTo.blank? and fail "sendTo Unset : Where do I send mail ?"
#    @hostName = @smtpServer if @hostName==nil
    @hostName==nil and @hostName = @smtpServer
    @TMailObj.date = Time.now
    Net::SMTP.start(@smtpServer, 
                    @smtpPort,
                    @hostName,
                    @smtpUser,
                    @smtpPassword,
                    @smtpAuth
                    ) do |smtp|
      smtp.send_message @TMailObj.encoded,
                        @sendFrom,
                        @sendTo
    end
  end


  #概要: メールの差出人を設定する。
  #
  #省略: 不可
  #
  #パラメータ: 差出人アドレス
  #
  #戻り値: 差出人アドレス
  # 
  #メールの差出人を指定する。通常は必須
  #ただし、一部のメールサーバではFromの省略が可能
  def from=(val)
    @sendFrom=val
    @TMailObj.from=val
  end

  # 概要 : メールの差出人を確認する
  # 戻り値 : String
  def from
    @TMailObj.from
  end

  #概要: メールの宛先を設定する。
  #
  #省略: 不可
  #
  #パラメータ: (String or Array) 宛先のメールアドレス
  #
  # 戻り値: (String) または (Array)
  # 
  #メールの宛先を指定する。配列で指定してもよい
  # 
  #instance.to=\["toshy.namimatsu@nifty.com","toshy@minfo-rela.net"\]
  def to=(*val)
    @sendTo=val
    @TMailObj.to=val
  end

  # 概要: メールの宛先を確認する
  # 
  # 戻り値: (String) または (Array)
  def to
    @TMailObj.to
  end

  #概要: メールの本文を設定する。
  #
  #省略: 可
  #
  #パラメータ: メール本文
  #
  #戻り値 : String
  #
  #メールの本文を指定する。
  #指定された文字はJIS化して格納される。
  def body=(val)
    @TMailObj.body=val.tojis
    body
  end


  #概要: メールの本文を確認する。
  #
  #パラメータ: メール本文
  #
  def body
    @TMailObj.body.toutf8
  end
  

  #概要: メールのタイトルを設定する。
  #
  #省略: メールサーバによる
  # 
  #パラメータ: 表題
  #
  #メールの表題を指定する。
  def subject=(val)
    @TMailObj.subject=japanese_enc(val)
    subject
  end
  
  #subject=のAlias
  def title=(val)
    subject=val
  end

  #概要: メールのタイトルを確認する
  #
  #パラメータ: String
  # 
  #値はエンコード前
  def subject
    japanese_dec(@TMailObj.subject)
  end

  #subjectのAlias
  def title
    title
  end

  #概要: メールのタイトル(生データ)を確認する
  #
  #戻り: String
  # 
  #値はエンコード前
  def subject_row
    @TMailObj.subject
  end

  # subject_rowのAlias
  def title_row
    subject_row
  end

  #概要: メールの返信先を確認する。
  #
  #戻り値: (String or Array) 返信先のメールアドレス
  def reply_to
    @TMailObj.reply_to
  end

  #概要: メールの返信先を設定する。
  #
  #省略: 可
  # 
  #パラメータ: (String or Array) 返信先のメールアドレス
  #
  #メールの返信先を指定する。
  #
  #メールソフトの多くはこのヘッダがあると、Fromではなく
  #ここで指定されたメールアドレスへ返信する。
  def reply_to=(val)
    @TMailObj.reply_to=val
  end

  #概要: SMTPサーバを設定する。
  #
  #省略: 不可
  #
  #パラメータ: メールサーバ
  # 
  #instance.server = "dell.private.minfo-rela.net"
  #
  #この場合は、dell.private.minfo-rela.netをメールサーバとする。
  def server=(val)
    @smtpServer = val
  end

  #概要: SMTPサーバを確認する。
  def server
    @smtpServer
  end

  #概要: SMTPに渡す自分のホスト名を設定する。
  #
  #省略: 可
  #
  #パラメータ: ホスト名(FQDN)
  #
  #SMTPサーバにアクセス元を示すもの。
  def host_name=(val)
    @hostName=val
  end

  #概要: SMTPに渡す自分のホスト名を表示する。
  # 
  #戻り値: ホスト名(FQDN)
  def host_name
    @hostName
  end

  #概要: SMTPサーバのポート番号を設定する。
  #
  #省略: 可
  #
  #パラメータ: メールサーバのポート番号 (Numeric)
  def port=(val)
    @smtpPort = val
  end

  #概要: SMTPサーバのポート番号を表示する。
  #
  #戻り値: メールサーバのポート番号 (Numeric)
  def port
    @smtpPort
  end

  #概要: SMTP AUTH情報の設定
  #
  #省略: 可能
  # 
  #パラメータ: Hash (:user=>ユーザ名,:password=>パスワード,:auth=>認証形式}
  # 
  #認証形式省略可能
  #(既定値 : PLAIN)
  # 
  # 
  #戻り値: Hash (:user=>ユーザ名,:password=>パスワード,:auth=>認証形式)
  #
  #SMTPサーバでユーザ認証が必要な場合は、
  #このメソッドをsendメソッドより前にコールしてください
  #
  #認証方法は以下参照
  #
  # PLAIN 
  #
  # 「認可識別子<NULL>認証識別子<NULL>パスワード」形式の平文によるユーザー認証方式です。BASE64でエンコードする場合もあります。 
  #  
  # LOGIN 
  #
  # PLAIN同様、平文を用いた認証形式です。標準仕様が存在していないので、各社製品間の互換性もあまり考慮されていません。 
  #
  # CRAM-MD5 
  #
  # クライアントは、接続先のMTAからあらかじめ示された任意の文字列（Challenge）にパスワードを含め MD5アルゴリズムで「メッセージダイジェスト」作成して MTAへ送信します。MTA側でも同様の方法で「メッセージダイジェスト」作成し、クライアントから送られてきたメッセージダイジェストと比較します。それで等しければログインを許可します。この方法では、パスワード自身がネットワークに流れることがないので PLAINや LOGIN より安全性が高くなります。（CRAM：Challenge-Response Authentication Mechanism）
  #  
  # DIGEST-MD5 
  # 
  # CRAM-MD5の欠点である辞書攻撃や総当たり攻撃に対する対処、Realm（ドメイン名）やURLの指定、および HMAC（keyed-Hashing for Message Authentication Code）による暗号化をサポートしています。
  # インスタンスの初期値はなし
  def smtp_auth_login_info=(hash)
#    hash[:auth]="PLAIN" if hash[:auth]==nil || hash[:auth].blank?
    (hash[:auth]==nil || hash[:auth].blank?) and hash[:auth]="PLAIN"
    @smtpUser = hash[:user]
    @smtpPassword = hash[:password]
    @smtpAuth = hash[:auth]
    smtp_auth_login_info
  end

  #概要: SMTP AUTH情報の表示
  #
  #戻り値: Hash (:user=>ユーザ名,:password=>パスワード,:auth=>認証形式)
  def smtp_auth_login_info
    {:user=>@smtpUser,
    :password=>@smtpPassword,
    :auth=>@smtpAuth}
  end
  
  #概要: 本文をテンプレートファイルから作成する。
  #
  # テンプレートはapp/models/mailer/template に保存する
  #
  # 拡張子はtxt。コードはUTF8
  #  
  # パラメータ: (String) ファイル名, (Hash) {パラメータ名=>値,...}
  # 
  #例: body_with_template_file("template_password_missing",{:user_name=>"テスト",:auth_code=>"Test"})
  def body_with_template_file(template_file,hash={})
    template=""
    file = File.open(Template_Path + template_file+".txt")
    template = file.readlines(nil).to_s
    file.close
    body_with_template(template,hash)
  end  

  #概要: 本文をテンプレートから作成する。
  #
  # テンプレートはapp/models/mailer/template に保存する
  #  
  # パラメータ: (String) テンプレートフォーマット, (Hash) {パラメータ名=>値,...}
  # 
  #例: body_with_template("#{user_name}様のパスワードは #{auth_code}",{:user_name=>"テスト",:auth_code=>"Test"})
  # 
  #    => テスト様のパスワードは Test
  def body_with_template(template,hash={})    
    hash.each do |k,v|
      template = template.gsub(/\#\{#{k.to_s}\}/,v)
    end
    self.body = template.tojis
  end
  
  def bcc
  	  @TMailObj.bcc
  end

  def bcc=(v)
  	  @TMailObj.bcc=v
  end

  def cc
  	  @TMailObj.cc
  end

  def cc=(v)
  	  @TMailObj.cc=v
  end

  def priority=(field)
  	  @TMailObj['X-Priority']=field
  end

  def priority
  	  @TMailObj['X-Priority']
  end

  def disposition_notification=(field)
  	  @TMailObj['Disposition_Notification-To']=field
  end

  def disposition_notification
  	  @TMailObj['Disposition_Notification-To']
  end

  def content_type=(v)
    @TMailObj.content_type=v
  end

end

