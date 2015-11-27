=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# CAUTION: 新設　2008/10/22 当面はデータ無し．

# columns
# 　user_info_run_id :integer
# 　プラス　他の共通コラム

# user defined label names for articles
class ArticleLabelName < Run
  set_table_name "article_label_names"

end