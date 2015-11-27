=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# students' report to exercise
class Report < Run
	set_table_name "reports"
  
  validates_presence_of :title, :body, :message => "必ず記入すること．"
  
  define_association :author_student, :dependee,
                     "UserInfo", " << .created_by :self ",
                     :assert_time => Self_Created_Time
                     
  define_association :exercise, :dependee,
                     "Exercise", " << :self",
                     :assert_time => Self_Created_Time
                     
  define_association :report_comments, :dependant,
                     "ReportComment", "-> :self",
                     :assert_time => :anytime,
                     :group => "report_comments.run_id",
                     :order => "report_comments.since DESC"
                     
  def report_comment(options = {})
    report_comments(options).first
  end
  
  def has_judged?
   (comment =  report_comments.first) && comment.judgement == ReportComment::Commented ? "済み" : "未了"
  end
  
end
