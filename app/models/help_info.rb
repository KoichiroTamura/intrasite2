=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


#  Table name : "help__infos"

#  content      text
#  name         string  # "利用ガイド", "セキュリティ方針", など
#  その他通常のrun用コラム

#  「利用ガイド」などをcontentに置く．書き換えしても変遷を残すために，Run形式にする．任意の表示時点の指定でその時点の状態を再現できる．
#   また，本体からの引用も（時間を同期して） 出来る．

class HelpInfo < Run
  set_table_name "help_infos"

 
end