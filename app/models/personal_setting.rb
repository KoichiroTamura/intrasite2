=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


class PersonalSetting < Run
  # in attribute "name", labels, "archive" are packed in to make use of SQL IN( ) function
  
  set_table_name "personal_settings"

end
