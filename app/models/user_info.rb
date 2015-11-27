=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# information about users as real people in the real world
class UserInfo < Run
	set_table_name "user_infos"    
  
  validates_presence_of :name, :real_name, :message => "必ず記入してください．"
  validates_format_of :email,
    :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
    :message => "メールアドレスが間違っています．"
  
  attr_accessor :category, :main_affiliation
 
  
  # a_net to get current account's user category
  A_Net =  ":self #{Organization_A_Net}"
                                        
  List_Items = " affiliation.fullseq AS aff_fullseq, affiliation.fullname AS affiliation_name," + 
               " affiliation.run_id AS affiliation_run_id, " +
               " affiliation.id AS affiliation_id, " +
               " status.fullseq AS sta_fullseq, status.fullname AS status_name, status.run_id AS status_run_id, " +
               " user_infos.* "
  
  User_Categories      = %w{教職員 学部生 院生 公開ユーザ} 
  
  Private_Items        = %w{real_name name_ruby country zipcode address address2 phone fax cellular_phone email} +
                         %w{room_no room_phone lab_no lab_phone url description}
                         
  define_association :group_members, :dependant,  "GroupMember", ">> :self"
  
  define_association :accounts, :dependant, "Account", ">> :self"
 
  def self.guest_user
    find :first, :scope => ":self", :conditions => "user_infos.name = 'guest'"
  end
  
  def category(options = {})
    if respond_to?(:status_name) 
      self.user_category_from_status()
    else
      current_state_in_organization(options).category
    end
  end
  
  def groups(options = {})
    associated_with "Group", " *memberable << :GroupMember >> :self", :order => "fullseq"
  end
  
  # current user state with category and main_affiliation
  def current_state_in_organization(options = {})
    result = UserInfo.find :first,
                  :scope      => A_Net,
                  :select     => List_Items,
                  :assert_time => :show_time,
                  :conditions  => "user_infos.run_id = #{self.run_id}",
                  :order      => "organizations.seq, aff_fullseq, sta_fullseq"   # order to obtain main organizational position of the user
    result.category = result.user_category_from_status()
    result.main_affiliation = Affiliation.find_entity(result.affiliation_id)
    return result
  end
  
  def user_category_from_status(status_name = self.status_name)
    (User_Categories - (User_Categories - status_name.split("|") )).first
  end
  
  def name_and_code
    "#{real_name}（#{name}）"
  end
  
  protected
  
  # for uniqueness validation of user_name avoiding racing.
  # when failed, expecting rollback saving by transaction set.
  def after_save
    validate_uniqueness_as_run(:name)
  end

end

