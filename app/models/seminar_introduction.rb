=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# 旧版での「ゼミ紹介」に対応

# 通常の共通のコラムのみ
# 旧版では，ファイルメーカのweb/seminars/に年度ごとのhtmlのファイルがおいてある．
# nameには年度ごとの呼び出しの(hrefの）file nameを置く．
# since, tillはそのファイルの該当年度に対応する．例．2008-04-01, 2009-03-31
# created_atは，旧版から移すものはすべて2001-04-01でよい．deleted_atはもちろんFuture

class SeminarIntroduction < Run
  set_table_name "seminar_introductions"
end