=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class Member < Run
  
  # for *memberable polymorphic
  # *memberable is polymorphic entity having users; so, this model entity links entity:*memberable to entity:UserInfo
  # Root of STI
  
  set_table_name "members"
 
  def member_role
    # care for ArticlePerson case which is not STI of Member
    attribute_present?(:description) ? description : nil
  end
  
  def user(options = {})
    new_record? ?  
       (user_info_run_id.blank? ?  nil : UserInfo.find( :first, :scope => ":self", :conditions => "user_infos.run_id = #{user_info_run_id}")) :
      assoc_dependee(  "UserInfo", "<-  :self", options)  
  end
  
  def real_name
    user.real_name
  end
  
 protected
 
  # verify user_info
  def before_save
    if user_info_run_id.nil?
      errors.add_to_base "ユーザが指定されていません．"
      fail ActiveRecord::RecordInvalid.new(self)
    end
  end
end