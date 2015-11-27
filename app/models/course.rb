=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# course of lectures
class Course < Run
  set_table_name "courses"
  
  validates_presence_of :name, :message => "記入してください．"
  
  define_association :course_classes, :dependant, 
                     "CourseClass", 
                     "[(-> :self)(*organized_entity <- :Organization [(.affiliation_run_id -> affiliation:Affiliation)
                                                                      (.status_run_id      -> status:Status)]]", 
                     :order => "affiliation.fullseq, status.fullseq"
                     
  define_association :lectures, :dependant,
                     "Lecture", "[(>> :self)]", 
                     :order => "lectures.id"
  
end