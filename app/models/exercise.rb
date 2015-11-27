=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# レポート課題

class Exercise < Run
	set_table_name "exercises"
  
  validates_presence_of :title, :body, :message => "記入してください．"
  
  # for judgement to report by teacher
  DONE = "済"
  NOT_YET = "未了"
  
  define_association :lecture, :dependee,
                     "Lecture", "<< :self"
                     
  define_association :reports, :dependant,
                     "Report", ">> :self",
                     :assert_time => :anytime,
                     :group => "reports.run_id",
                     :order => "reports.since DESC"
                     
  def report_comment_statistics
    associated_with( "ReportComment", "-> :Report >> :self", 
                     :select      => {:count   => "COUNT(DISTINCT report_comments.run_id)",
                                      :average => "AVG(report_comments.point)",
                                      :stddev  => "STDDEV_POP(report_comments.point)"},
                     :conditions  => "report_comments.judgement = '#{DONE}'").first
  end
                     
  # submitter(current_user) related courses
  def related_courses
    Course.find :all, 
                :scope => ":self << :Lecture *memberable << :LectureMember::Teacher >>  :UserInfo .run_id = #{@@current_user.run_id}",
                :select => {:id => ".id",:run_id => ".run_id",
                            :name => ".name",
                            :lecture_run_id => "lectures.run_id"},
                :assert_time => :show_time
  end
  
  # for course selection
  def course_choices
    related_courses.map do |c|
      [c.name, c.lecture_run_id]
    end
  end
  
  # related teachers
  def teachers
    associated_with "UserInfo", " << :LectureMember::Teacher >> *memberable :Lecture << :self",
                                  :assert_time => Self_Created_Time,
                                  :select      => {:run_id => "user_infos.run_id"}
  end
  
  # related tas
  def tas
    associated_with "UserInfo", "<< :LectureMember::TA >> *memberable :Lecture << :self"   ,
                                  :assert_time => Self_Created_Time,
                                  :select      => {:run_id => "user_infos.run_id"}
  end
end
