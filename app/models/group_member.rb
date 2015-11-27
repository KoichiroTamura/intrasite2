=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# membership of group of users

class GroupMember < Member
	# STI
  
  def group
   assoc_dependee "Group", "*memberable << :self"
  end
  
  def user_info
   assoc_dependee "UserInfo", "<< :self"
  end
  
  def group_run_id
    group.run_id
  end
  
  # for group selection
  def group_run_id=(value)
    self.memberable_run_id = value
    self.memberable_type   = "Group"
  end
end
