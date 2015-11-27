=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# メール共通部品
#
# 送信はMailer::Send、受信はMailer::Receive
#
# ヘッダに日本語をいれるための変換をする関数が現在は配置されている。
#
# RFC2047で定義されている。
#
# 本来はActionMailerやTMailがすべき仕事だが、
# やってくれないため自前で作成
class Mailer::Base
  require "jcode"
  # 日本語コードをRFC2047に従い、変換する。
  #
  # パラメータ: (String) 変換対象
  #
  # 戻り値: (String) 変換後対象
  def japanese_enc(val)
    "=?ISO-2022-JP?B?" + val.tojis.split(//,1).pack('m').chomp + "?="    
  end

  # RFC2047に従い変換されたものを、日本語コードに戻す
  #
  # パラメータ: (String) 変換対象
  #
  # 戻り値: (String) 変換後対象
  def japanese_dec(val)
#    return "" if val == nil || val.blank?
    (val == nil || val.blank?) and return ""
    val.gsub(/=\?(.*?)\?=/) { |m|    
      (dummy,charset,encode,body,dummy) = m.split("?")
#      body = body.unpack("M").toutf8 if encode=="Q"
#      body = body.unpack("m").toutf8 if encode=="B"
      encode=="Q" and body = body.unpack("M").toutf8
      encode=="B" and body = body.unpack("m").toutf8
    }
  end

end