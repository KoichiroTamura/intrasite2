=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module LectureTimesHelper
    
  def render_lecture_season(season)
    season.to_s + "学期"
  end
  
  def render_lecture_time(lecture_time)
    lecture_time.to_s + "限"
  end
  
  WdayNames = %w{日曜 月曜 火曜 水曜 木曜 金曜 土曜}
  def render_day_of_week(day_of_week)
    WdayNames[day_of_week.to_i]
  end
  
  def render_lecture_room(room)
    room.to_s + "教室"
  end
end