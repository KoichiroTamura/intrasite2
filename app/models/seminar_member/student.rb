=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# student's enrollment to a seminar
class SeminarMember::Student < Member
  
  validates_presence_of :reason, :message => "希望理由が空欄です．"
	
  # STI 
  
  define_association :seminar, :dependee, "Seminar", "*memberable << :self",
                     :assert_time => Self_Created_Time
  
  # CAUTION: student of enrollment is not its creater, because enrollment could be updated by teacher to accept.
  define_association :student, :dependee, "UserInfo", "<< :self",
                     :assert_time => Self_Created_Time
  
  def seminar_run_id
    seminar.run_id
  end
  
  # accept enrollment to a seminar by teacher
  def to_accept(locked_states, span = Run.get_academic_year_range_for_time)
    transaction do
      update_run!( :now, {:is_accepted => true}, locked_states)
      other_enrollments(self.student, span).each do |enrll|
        enrll.delete_run!
      end
    end
  end 
  
  def student_name(options = {})
    student.blank? and return "不明(unknown)"
    student.name_and_code
  end
  
  def student?(user)
    student && student.run_id == user.run_id
  end
  
  def self.not_accepted_yet(student, span = Run.get_academic_year_range_for_time)
    all_enrollments_by_student(student, span).detect{|e| e.is_accepted.to_i == 1} ? false : true
  end
    
  protected
    
  def self.all_enrollments_by_student(student, span = Run.get_academic_year_range_for_time)
    cond = "(created_at BETWEEN '#{span.begin}' AND '#{span.end}') AND user_info_run_id = #{student.run_id}"
    entity_name = table_name
    normal_cond = "#{entity_name}.simulation_mode IS NULL" 
    simulation_cond = @@simulation_mode ? "#{normal_cond} OR #{entity_name}.simulation_mode" : normal_cond
    find :all,  :scope => :self, :conditions => merge_conditions(cond, simulation_cond)
  end
  
  def other_enrollments(student, span = Run.get_academic_year_range_for_time)
    self.class.all_enrollments_by_student(student, span) - [self]
  end

end
