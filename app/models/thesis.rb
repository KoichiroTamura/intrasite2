=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


class Thesis < Run
	set_table_name "theses"
  
  # root of STI
  
    
  validates_presence_of :teacher, :title, :presentation_code, :abstract, :message => "必ず記入してください．"

  
  define_association :authors, :dependant,
                     "UserInfo",  "<< :ThesisMember::Author >> *memberable :self", 
                     :order => "user_infos.name"
                     
  define_association :author_members, :dependant,
                     "ThesisMember::Author", " >>  *memberable  :self"
  
  define_association :teachers, :dependant,
                     "UserInfo",  " << :ThesisMember::Teacher >> *memberable :self", 
                     :distinct => {:id => "user_infos.id ", :run_id => "user_infos.run_id",
                                   :name => "user_infos.real_name"}
                                   
  define_association :lecture_member__teachers, :dependant,
                     "ThesisMember::Teacher", " >> *memberable  :self"
                     
  def modifier!
    self.academic_year = Run.get_academic_year
  end
  
  def author_member_users
    author_members.map(&:user)
  end
  
  def author_member?(user)
    user && author_member_users && author_member_users.map(&:run_id).include?(user.run_id)
  end

end
