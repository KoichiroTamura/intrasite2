=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


class ReportComment < Run
	set_table_name "report_comments"
  
  Commented = "済"
  Uncommented = "未了"
  
  define_association :report, :dependee,
                     "Report", "<< :self",
                     :assert_time => Self_Created_Time
  
  define_association :commentator, :dependee,
                     "UserInfo", "<< .created_by :self",
                     :assert_time => Self_Created_Time

end
