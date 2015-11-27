=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class LectureCourseClass < Run
  set_table_name "lecture_course_classes"
  
  define_association :course_classes, :dependee, "CourseClass", "<< :self"
  
  def modifier!
    #  disconnect from lecture when not given at checkbox selection in updating page
    course_class_run_id.blank? and self.lecture_run_id = 0
  end

end