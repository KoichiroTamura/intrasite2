=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module MailAccountsHelper
  def render_mail_account(object_name, method, options)
    from_array = Array.new
    from_array[0] = [@current_user.email.to_s+" (既定値)",0]
    
    mas = MailAccount.find(:all, :scope=>":self",:conditions=>["user_info_run_id=?",@current_user.run_id])
    if mas.size == 0 
     @current_user.email + 
       object_name.hidden_field(method,:value=>0)
   else
     mas.each do |ma|
       from_array.push([ma.address.to_s+" ("+ ma.smtp_server + ")",ma.run_id])
    end
      object_name.select(method,from_array,options)
    end
    
  end
end
