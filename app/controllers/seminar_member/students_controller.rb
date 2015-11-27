=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# for seminar enrollments by students

# enrollments to seminars

class SeminarMember::StudentsController < SeminarsController
  
  def accept
    div_id = params[:div_id]
    catch :flash_now do     
      @enrollment = Run.find_entity(params[:id])
      flash_now @enrollment.blank?, "この登録はすでに削除されています．"
      @enrollment.to_accept(params[:locked_states])
    end
    render :update do |page|
      page.replace_html div_id, "<span style='color:red'>採用</span>"
      page[div_id].visual_effect(:highlight)
    end
    return false
  rescue ActiveRecord::RecordInvalid => e
    render_error_messages(e)
  end
  
  private

  def find_collection
    if allow_to_display_summing_up?
      @def_items  = Def_Summing_Up_Items
      @list_items = Summing_Up_Items
      @queries    = [:teacher_name, :affiliation]
      
      ac_year_range_cond = Run.get_academic_year_range_cond("members")
      
      @collection = SeminarMember::Student.find :all, 
                                  :page => current_page,
                                  :scope => Summing_Up_A_Net,
                                  :select => select_items,
                                  :conditions => merge_conditions(query_cond, ac_year_range_cond),
                                  :order  => "student.name"
      @entity_template = "seminar_member/students/entity"
      @menu_name = "ゼミ登録：登録一覧"
    end    
  end
  
  def find_detail
    @def_items    = Def_Enrollment_Items
    @detail_items = Enrollment_Detail_Items
    allow_to_modify_enrollment?(@entity) and @detail_items += Base_Altering_Items
  end
    
  def find_history
    @def_items  = Def_Enrollment_Items
    @list_items = Enrollment_History_Items + [:id, :run_id]
    @collection = @entity.history :distinct => select_items(@def_items, @list_items)
  end
    
  def prepare_for_new
    @seminar = find_entity(@background_params[:seminar_id])
    @enrollment = @entity = SeminarMember::Student.new_run
    @enrollment.build_seminar @seminar
    @enrollment.build_student @current_user
    preparation_for_altering
  end
  
  def prepare_for_updating
    @enrollment = @entity
    preparation_for_altering
  end
  
  def preparation_for_altering
    @def_form_items = Def_Enrollment_Form_Items
    @form_items     = Enrollment_Form_Items
  end

  def before_put
    seminar = Run.find_entity(@background_params[:seminar_id])  
    content = @entity_ref.content;
    case @put_method
      when :create
        content.merge!(
          :till => Run.get_academic_year_range_for_time.end,  # limit valid span of enrollment
          :memberable_run_id => seminar.run_id,
          :memberable_type   => seminar.class.name,
          :user_info_run_id  => @current_user.run_id )
        @entity_ref.content = content
        flash_now already_accepted?(), "すでに他のゼミへのあなたの登録が採用されていますので，登録実行は無効にします．"
      when :update
        content.merge!(
          :till => Run.get_academic_year_range_for_time.end  # necessary for update, too
        )
    end   
  end
  
  def already_accepted?()
    student = UserInfo.find :first, 
                            :scope => :self, 
                            :conditions => "run_id = #{@entity_ref.content[:user_info_run_id]}"
    !SeminarMember::Student.not_accepted_yet(student)
  end
  
  def after_put
    case @put_method
      when :create, :update
        @confirmation_method = "find_detail"
        @confirmation_template = "detail"
    end        
  end

end
