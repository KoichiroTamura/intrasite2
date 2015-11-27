=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# in old intrasite, "subject"

class Syllabus < Run
	set_table_name "syllabuses"
  
  validates_presence_of :name, :goal, :teaching_goal, :teaching_style, :question, :detail, :judgment, :message => "必ず記入してください．"
  
  define_association :syllabus_books, :dependant,
                     "SyllabusBook", ">> :self"

  define_association :lectures, :dependant,
                     "Lecture", ">> :self"
                     
  def teacher_of?(options = {})
    !lectures.detect{|l| !l.teacher_of?}
  end

end
