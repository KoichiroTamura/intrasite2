=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# time and place for lectures
# SyResouces in old IntraSite
class LectureTime < Run
  set_table_name "lecture_times"

  def season_name
    self.season + "学期"
  end

  Wday_Name = %w(日曜 月曜 火曜 水曜 木曜 金曜 土曜)

  # for select choices
  Lecture_Times = %w{1 2 3 4 5 6 7 8}.map(&:to_i)
  Lecture_Time_Range = (1..8)
  Days_Of_Week = Wday_Name.zip(%w{0 1 2 3 4 5 6}.map(&:to_i))
  Seasons      = %w{春 秋 春,秋}
  Campus       = %w{A学舎 B学舎}

  def wday
    Wday_Name[day_of_week]
  end

  def lecture_time_name
    lecture_time.to_s + "限"
  end

  def lecture_time_and_room
    campus ||= ""
    [season_name, wday, lecture_time_name, campus, room].join(" : ")
  end


end
