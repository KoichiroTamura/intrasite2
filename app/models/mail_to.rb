=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class MailTo < Run
    set_table_name "mail_tos"
    define_association :mail, :dependee, "Mail", "<< :self", :assert_time => :show_time
end
