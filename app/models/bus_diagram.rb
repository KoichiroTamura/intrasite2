=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


class BusDiagram < Run
  set_table_name "bus_diagrams"

  # interprete wday of Ruby to name in Model
  Day_Type_Db = {6 => "土曜日", 0 => "日曜日"}; Day_Type_Db.default = "平日"

  Departure_Options = %w{大学 最寄り駅}

end
