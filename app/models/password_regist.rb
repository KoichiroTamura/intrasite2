=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

require 'uuidtools'

class PasswordRegist < Run
  set_table_name "password_regists"

# --------------------------------------------------------------- 2011.07.29 追加
  def self.admin_only
      true
  end
# -----------------------------------------------------------------------------
#  def delete
#		# 通常は本当に削除出来るのは管理者のみ
#		# ここでは特例とする
#    self.id or fail "ID IS NULL"
#    fail "ID IS NULL" if (self.id.blank?) || (self.id==0)
#    ((self.id.blank?) || (self.id==0)) and fail "ID IS NULL"
#    ActiveRecord::Base.connection.execute("delete from #{self.class.table_name} where id=#{self.id}")
#  end
# --------------------------------------------------------------- 2011.07.29 削除
# このコードはdestroy_run未完成時の回避措置であるため、削除する。
# ずっと残留していたが、意味不明なSQLが発行されるので、ないほうがよかろう 2011.8.22
  
  def password=(val)
    self.salt = self.class.set_salt("")
    self.passwd=hash_password(val)
  end

  def self.set_salt(name)
    hash_pass("__#{DateTime.now.to_s}__#{name}__") 
  end
  
  def verify_password(password)
    passwd == hash_password(password)
  end
 
  def hash_password(password)
    val = (salt ? "__#{salt}__#{password}__" : password.to_s)
    Account.hash_pass(val)
  end
  
  def self.hash_pass(val)
    Digest::SHA512.hexdigest(val)
  end

end