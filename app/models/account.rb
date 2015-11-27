=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end



require 'digest/sha2'

# accounts for users in user_infos
# user can have multiple accounts if allowed
# account name is in many cases the same as user name, but not necessarily.
# for instance, "admin1" account may be given to a user with admin role and "test_student" with test role
class Account < Run
  set_table_name "accounts" # necessary for only script/console; don't know why.
  
  # real password given by user
  attr_accessor :password
  
  validates_presence_of   :name, :message => "アカウント名がありません．"
  
  Roles = %w{user test admin guest}
  
  define_association :user_info, :dependee, "UserInfo", "<< :self", :assert_time => :show_time
  
  def self.guest_account
    find :first, :scope => ":self", :conditions => {:role => "guest"}
  end
  
  # set salt when starting run
  def self.create_run!(attrs)
    super attrs.update( :salt => set_salt(attrs[:name]) )
  end
     
  def change_name_and_password
    if self.password.blank?
      errors.add :password,  "パスワードがありません．"
      fail ActiveRecord::RecordInvalid.new(self)
    end
    new_salt = Account.set_salt(self.name)
    update_run! :now, :name => self.name, :salt => new_salt, :passwd => hash_password(self.password, new_salt)
  rescue ActiveRecord::RecordInvalid => e
    record = e.record  # record with save validation errors
    record.set_of_all_errors = [e]
    fail ActiveRecord::RecordInvalid.new(record)
  end
  
  # authenticate by self.name and self.password
  def authenticate
    password.blank? and fail "パスワードがありません．"
    account = Account.find :first,
                 :scope      => :self,
                 :assert_time => DateTime.now,  # real present time
                 :select     => "id, passwd, salt" ,
                 :conditions => {:name => name}
    account && account.verify_password(password) ? account : fail("アカウント・パスワードが無効です．")
  end

  
  def self.set_salt(name = self.name)
    hash_pass("__#{DateTime.now.to_s}__#{name}__") 
  end
  
  def verify_password(password)
    passwd == hash_password(password)
  end
 
  def hash_password(password, salt = self.salt)
    val = (salt ? "__#{salt}__#{password}__" : password.to_s)
    Account.hash_pass(val)
  end
  
  def self.hash_pass(val)
    Digest::SHA512.hexdigest(val)
  end

  protected
  
  def after_save
    validate_uniqueness_as_run(:name)
  end
end
