=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

#  ゼミ登録スケジュール

class SeminarEnrollmentSchedule < Run  
  set_table_name "seminar_enrollment_schedules"
  
  # "year" is academic year
  def self.find_schedules(year)
    find :all, 
         :scope => ":self",
         :conditions => {:name => year},
         :order => "start_time"
  end
end
