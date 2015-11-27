=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


class Lecture < Run
  
  set_table_name "lectures"
  
  define_association :course, :dependee, "Course", "<< :self"
  
  define_association :lecture_course_classes, :dependant, "LectureCourseClass", ">> :self"
                     
  define_association :lecture_member__teachers, :dependant,
                     "LectureMember::Teacher", " >> *memberable :self"
                                          
  define_association :lecture_member__t_as, :dependant,
                     "LectureMember::TA", ">> *memberable :self"
                                          
  define_association :lecture_member__students, :dependant,
                     "LectureMember::Student", " >> *memberable :self"
                     
  define_association :lecture_times, :dependant, "LectureTime", ">> :self"
  
  define_association :syllabus, :dependee, "Syllabus", "<< :self "
                     
                     
  def course_classes(options = {})
    associated_with "CourseClass", "[(<< :LectureCourseClass >> :self)(>> :Course)]", options
  end
  
  def teachers(options = {})
    associated_with "UserInfo", " << :LectureMember::Teacher >> *memberable :self ",
                    options.merge(:group => "user_infos.run_id", :order => "user_infos.name")
  end
  
  def teacher_of?(options = {})
    @@current_user or return false
    teachers.map(&:run_id).include?(@@current_user.run_id)
  end
     
  def students(options = {})
    associated_with "UserInfo", " << :LectureMember::Student  >>  *memberable :self ",
                   options.merge(:group => "user_infos.run_id", :order => "user_infos.name")
  end
 
  def n_students(options = {})
    associated_with( "UserInfo", " << :LectureMember::Student  >>  *memberable :self",                  
                     options.merge(:select => {:count => "COUNT(DISTINCT user_infos.id)"}) ).first
  end
    
  def tas(options = {})
    associated_with "UserInfo",  " << :LectureMember::TA >>  *memberable  :self ",
                    options.merge(:group => "user_infos.run_id", :order => "user_infos.name")
  end
  
  def lecture_members(options = {})
    associated_with "UserInfo", "<< :Member >> *memberable :self",
                    options.merge(:group => "user_infos.run_id", :order => "user_infos.name")
  end
  
  def lecture_member?(options = {})
    @@current_user or return false
    result = associated_with "UserInfo", "[(<< :Member >> *memberable :self)( .run_id = #{@@current_user.run_id} )]"
    !result.blank?
  end
  
  def lecture_course_class_with_cc(cc_run_id)
    associated_with "LectureCourseClass", ">> :self", 
                     :conditions => "lecture_course_classes.course_class_run_id = #{cc_run_id}"
  end
  
  def modifier!
    # syllabus_name is set as course name to inherit the way of old verision.
    self.syllabus_name = course.blank? ? "" : course.name
  end

end