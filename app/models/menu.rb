=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# 2010/10/05　田村作成
# Cornerと同じテーブルを使用し，Cornerの子となる．

class Menu < Run
  set_table_name  "corners"
  
  def before_save
      self.parameters.blank? and self.parameters = nil
      self.url.blank? and self.url = nil 
      return true
  end
  
end

