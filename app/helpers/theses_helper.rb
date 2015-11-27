=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module ThesesHelper
  
  def get_current_affiliation
    UserInfo.find :first,
                  :scope=>":self *organized_entity << org:Organization.affiliation_run_id >> aff:Affiliation",
                  :distinct=>"aff.run_id",
                  :conditions=>"user_infos.run_id=#{@current_user.run_id}"
  end

end