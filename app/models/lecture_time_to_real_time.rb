=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# correspondence of lecture time to real time

class LectureTimeToRealTime < Run

  set_table_name "lecture_time_to_real_time"
  
  def self.real_time(lecture_time, campus = nil)
    time_cond = {:lecture_time => lecture_time.to_i}
    campus_cond = campus.nil? ?  "campus IS NULL" : {:campus => campus}
    r_time = find(:first, :scope => ":self", :conditions => merge_conditions(time_cond, campus_cond)) 
    r_time or return ["00:00", "23:59"] # all day long
    # CAUTION: datetime type in DB is changed to a funny style in RAILS
    return [r_time.real_start_time, r_time.real_end_time].map do |rt| rt.to_s(:db).split(" ").last end
  end
  
end