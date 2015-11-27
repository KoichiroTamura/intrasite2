=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module SeminarsHelper

  
  def allow_to_update_seminar?(seminar)
    controller.allow_to_update_seminar?(seminar)
  end
  
  def allow_to_delete_seminar?(seminar)
    controller.allow_to_delete_seminar?(seminar)
  end

  def allow_to_display_enrollment?(enrollment)
    controller.allow_to_display_enrollment?(enrollment)
  end
  
  def allow_to_enroll?(seminar)
    controller.allow_to_enroll?(seminar)
  end 
  
  def allow_to_modify_enrollment?(enrollment)
    controller.allow_to_modify_enrollment?(enrollment)
  end
  
  def allow_to_accept_enrollment?(enrollment)
    controller.allow_to_accept_enrollment?(enrollment)
  end
  
  def allow_to_display_summing_up?
    controller.allow_to_display_summing_up?
  end
  
  def render_seminar_teachers_in_list(teachers = [])
    teachers.map do |teacher| 
                  teacher.real_name 
                 end.join('&nbsp;&nbsp;')
  end
  
  def render_seminar_teachers(teachers = [])
    teachers.map do |teacher| 
                  user_info_detail_link(teacher) 
                 end.join('<br />')
  end
  
  def render_enrollments(enrollments = [])
    seminar = enrollments.assoc_entity
    render :partial => "seminars/enrollments", 
           :locals => {:enrollments => enrollments, :seminar_id => seminar.to_param}
  end
    
  # remote link for studentes to enroll seminar membership
  def link_to_enrolling(seminar, div_id, options = {})
    link_to_remote_with_params("配属希望を登録する", 
      :url    => {:controller => "seminar_member/students",:action => :new},
      :params => {:base_div_id => div_id,
                  :background_params => @background_params})
  end
  
  def render_accept_button(enrollment)
    is_accepted = enrollment.new_record? ? nil : enrollment.is_accepted.to_i
    if is_accepted == 1
      "<span style='color:red'>採用</span>"
    elsif  allow_to_accept_enrollment?(enrollment)
      render( :partial => "/seminars/accept_button", :locals => {:enrollment => enrollment})
    else
      "未採用"
    end
  end
  
  def render_accept_enrollment(is_accepted)
    is_accepted.to_i == 1 ? "<span style='color:red'>採用</span>" : "未採用"
  end
  
  def enroll_system_test(enrollment,login_account)
    return (login_account.role!="test" && login_account.role!="admin") && 
            enrollment.role=="test"
  end
  
  def enroll_system_test_marker(entity)
#     return " style=\"color:red\"" if entity.role=="test"
#     return ""
     return entity.role=="test" ? " style=\"color:red\"" : ""
  end
 
  # make seminar index page up to date.
  def seminar_up_to_date(text)
    link_to text, seminars_path(:menu_name1 => "ゼミ関連：ゼミ登録")
  end
end