=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


class Seminar < Run
	set_table_name "seminars"
  
  validates_presence_of :name, :students_limit, :body, :message => "記入してください．"
  
  define_association :org_affiliation, :dependee,
                     "Affiliation", "<< .affiliation_run_id :self"
  
  define_association :seminar_member__teachers, :dependant,
                     "SeminarMember::Teacher", ">> *memberable :self",
                     :group => "members.run_id"
                     
  define_association :enrollments, :dependant,
                     "SeminarMember::Student", ">> *memberable :self",
                     :order => "members.created_at",
                     :group => "members.run_id"
  
  # teachers of the seminar
  def seminar_teachers
    seminar_member__teachers.map(&:user)
  end
  
  def seminar_teacher?(user)
    seminar_teachers && seminar_teachers.map(&:run_id).include?(user.run_id)
  end
  
  def affiliation_name(options = {});
    org_affiliation.blank? ? "不明" : org_affiliation.name
  end
  
  # collection of enrollments during the academic year of @@show_time
  def enrollments_for_ac_year(time = @@show_time)
    associated_with( "SeminarMember::Student", ">> *memberable :self",
                           :conditions => get_academic_year_range_cond("members", :since, time),
                           :order => "members.created_at",
                           :group => "members.run_id"
  )
  end
  
  def n_of_enrollments
    limit_of_enrollments.blank? and return ""
    result = (enrollments_for_ac_year() || []).size
    limit_of_enrollments.to_i > result and return "未満"
    result
  end
  
  def n_of_accepted_enrollments
    (enrollments_for_ac_year.find_all{|e| e.is_accepted} || []).size
  end
  
  def get_academic_year_range_cond(table_name, attr_name = :since, time = @@show_time)
    academic_year_range = Run.get_academic_year_range_for_time(time)
    return "#{table_name}.#{attr_name} BETWEEN '#{academic_year_range.begin}' AND '#{academic_year_range.end}'"
  end
  
  def modifier!
    self.affiliation_run_id = Run.current_user.main_affiliation.run_id
  end
  
end
