=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

#=概要
#　メールを受信する。
#
#=動作概要
#　Net::POP3またしNet::APOPを使用してメールサーバからデータを取得する。
#  メールデータの分析はTMailを用いてメールの本体を構成している。
#
#  メールサーバにメールは残すので、前回との重複受信に注意。
#
#=使用例
#
#r = Mailer::Receive.new
#
#                           # インスタンス生成
#
#r.server = "dell.private.minfo-rela.net"
#
#                           # メールサーバの設定
#
#r.pop_auth_login_info=({:user=>"toshy",:password=>"ktns1740"})
#
#                           # ユーザ認証情報作成
#
#r.receive
#
#                           # メール取得を実行
#
#mail_hash = r.mails
#
#                           # メールデータの日本語化と整形
#
#=POP over TLS
# POP over TLSの場合は、enable_tlsをしてください。
# 
# このとき、tlsmailをコールするので、あらかじめ、インストールしてください。
# 
# gem install tlsmail
#
# http://d.hatena.ne.jp/zorio/20070318/1174226862
# 
class Mailer::Receive < Mailer::Base
  require "jcode"
  require 'net/pop'
  require "base64"
  require 'digest/md5'

  # POPのサーバを指定する
  @popServer
  
  # POPサーバのポート番号を指定する
  @popPort
  
  # ユーザ名を指定する
  @popUser
  
  # パスワードを指定する
  @popPassword

  # サーバの種類。通常はPOP
  @popSpec

  # サーバから読み取ったデータを格納する場所
  @mails
  
  # メールの削除をするか
  @delete

  #概要: インスタンスの生成。
  #
  #省略: 不可
  #
  #パラメータ: なし
  def initialize
    @popServer = "localhost"
    @popPort = 110
    @popAPOP = false
    @delete = false
    begin
    require "tlsmail" 
      Net::POP3.disable_tls()
    rescue
    end
  end

  #概要: POP3サーバを設定する。
  #
  #省略: 不可
  #
  #パラメータ: メールサーバ
  # 
  #instance.server = "dell.private.minfo-rela.net"
  #
  #この場合は、dell.private.minfo-rela.netをメールサーバとする。
  def server=(val)
    @popServer = val
  end

  #概要: SMTPサーバを確認する。
  def server
    @popServer
  end

  #概要: POP3サーバのポート番号を設定する。
  #
  #省略: 可
  #
  #パラメータ: メールサーバのポート番号 (Numeric)
  def port=(val)
    @popPort = val
  end

  #概要: POP3サーバのポート番号を表示する。
  #
  #戻り値: メールサーバのポート番号 (Numeric)
  def port
    @popPort
  end

  #概要: 認証情報の設定
  #
  #省略: 可能
  # 
  #パラメータ:  Hash (:user=>ユーザ名,:password=>パスワード)
  #
  #戻り値: Hash (:user=>ユーザ名,:password=>パスワード)
  def pop_auth_login_info=(hash)
    @popUser = hash[:user]
    @popPassword = hash[:password]
    pop_auth_login_info
  end

  #概要: pop AUTH情報の表示
  #
  #戻り値: Hash (:user=>ユーザ名,:password=>パスワード)
  def pop_auth_login_info
    {:user=>@popUser,
    :password=>@popPassword}
  end

  #概要: POP3用の設定に変更する
  #
  #省略: 可
  def enable_pop
    @popAPOP = false
  end
  
  #概要: APOP用の設定に変更する
  def enable_apop
    @popAPOP = true
  end
  
  #概要: POP3 over TLS に対応する
  #
  #パラメータ: なし
  #
  #戻り値: なし
  #
  #設定をPOP3 over TLS向けに修正します。
  #
  #ポート番号が995でないばあいは、port= メソッドで変更してください
  #
  # tlsmailが必要
  def enable_tls
  require "tlsmail" 
    Net::POP3.enable_ssl(OpenSSL::SSL::VERIFY_NONE) 
    @popPort=995
  end
  def enable_tls=(val)
  	enable_tls
  end

  #概要: SMTP over TLSを無効にする
  #
  #ポート番号が110でないばあいは、port= メソッドで変更してください
  #
  def disable_tls
  require "tlsmail" 
    Net::POP3.disable_ssl() 
    @popPort=110
  end
  def disable_tls=(val)
  	disable_tls
  end
  
  #概要: メールを受信する
  #
  #パラメータ: なし
  #
  #戻り値: Array
  #
  #失敗するとNet::POPの例外が発生する。
  # http://www.ruby-lang.org/ja/man/html/net_pop.html
  def receive
    @mails = Array.new
     Net::POP3.start(@popServer,@popPort,@popUser,@popPassword,@popAPOP) do |pop|
      pop.each_mail do |m|
        @mails.push(m.pop)
#        m.delete if @delete
        @delete and m.delete 
      end
     end
     @mails
  end

  #概要: 受け取ったメールは削除するように設定する
  #
  #パラメータ: なし
  #
  def mail_delete
    @delete=true
  end

  #概要: 受け取ったメールは保存するように設定する
  #
  #パラメータ: なし
  #
  #戻り値: Array (要素はString)
  def mail_save
    @delete=false
  end

  #概要: receiveで取得したメールの生データを取得する
  #
  #パラメータ: なし
  #
  #戻り値: Array (要素はString)
  def mails_rows
    @mails
  end

  #概要: receiveで取得したメールのデータをハッシュで取得する
  #
  #パラメータ: なし
  #
  #戻り値: Array (要素はHash)
  #
  #Message-ID:がないメールに対しては UUID@webapp を代入します。
  def mails
    array = Array.new
    @mails.each do |m_s|
      mail = TMail::Mail.parse(m_s)
      attached_datas = Array.new
      m = TMail::Mail.new
      if mail.multipart? 
        c = 0
        mail.parts.each do |ms|
          if c==0
            m = ms
          else
            attached_datas.push({:filename=>japanese_dec(File.basename(ms.disposition_param('filename').gsub(/\\/, '/'))),
                       :body=>Base64.decode64(ms.body)
                      })
          end
          c = c + 1 
        end
      else
          m = mail
          attached_datas = nil
      end
      
#      m.message_id = "<" + Digest::MD5.hexdigest(m.date.to_s + m.from.to_s + m.subject.to_s).to_s + "@webapp" + ">" if m.message_id.blank? 
      m.message_id.blank?  and m.message_id = "<" + Digest::MD5.hexdigest(m.date.to_s + m.from.to_s + m.subject.to_s).to_s + "@webapp" + ">"
      
      array.push({:from=>japanese_dec(a_to_s(m.from)).toutf8,
              :to=>japanese_dec(a_to_s(m.to)).toutf8,
              :cc=>japanese_dec(a_to_s(m.cc)).toutf8,
              :subject=>japanese_dec(m.subject).toutf8,
              :reply_to=>japanese_dec(a_to_s(m.reply_to)).toutf8,
              :in_reply_to=>m.in_reply_to,
              :references=>m.references,
              :body=>m.body.toutf8,
              :uniq_code=>m.message_id,
              :message_id=>m.message_id,
              :date=>m.date,
              :attached_files=>attached_datas
              })
    end
    array
  end
  
  private
  # Arrayで帰ってきたデータをもとのメールヘッダ風につなげる
  def a_to_s(v)
#     v = v.join(", ") if v.class == Array
     return v.class == Array ? v.join(", ")  : v
  end
end