=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# for group of user_infos
class Group < Run
  set_table_name "groups"
  
  Affiliation_Default = "全員|中京大学|"
  Status_Default      = "ステータス|教職員|"

  validates_presence_of   :real_name, :name, :message => "必ず記入してください．"
  
  A_Net =  ":Group #{Organization_A_Net}"
  
  define_association :group_members, :dependant,  "GroupMember", ">> *memberable :self"
                                        
  List_Items = " affiliation.fullseq AS aff_fullseq, affiliation.fullname AS affiliation_name," + 
                         " status.fullseq AS sta_fullseq, status.fullname AS status_name," +
                         " groups.* "
  protected
  
  # for uniqueness validation of group code name avoiding racing.
  # failure causes rollback of saving by transaction set.
  def after_save
    validate_uniqueness_as_run(:name)
  end

end