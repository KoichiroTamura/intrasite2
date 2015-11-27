=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module LectureTimeToRealTimesHelper
  # helpers for rendering lecture_time_to_real_times view
  
  def render_real_time_part(db_time)
    db_time.blank? and return nil
    db_time.to_s(:db).split(" ").last
  end

end