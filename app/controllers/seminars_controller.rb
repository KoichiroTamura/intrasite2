=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# in old intrasite, 「ゼミ登録」
class SeminarsController < RunsController  
  before_filter :local_registered_only
  before_filter :set_action_timing, :except => [:set_action_timing]
  
  # allow committing actions for all teachers of the seminar instead of owner only.
  skip_before_filter :owner_only  
  before_filter :seminar_teachers_only => Owner_Only_Actions
  
  Header_Local_Info = ["学生が配属を希望するゼミを登録し，ゼミ担当教員が採否を決める場です．",
                       "操作は，スケジュール表に従ってください．詳細は「ゼミ配属の手引き」を見てください．",
                       "表示と操作はスケジュールの段階，教員と学生とで異なることに注意．"]

  A_Net = ":self [ (.affiliation_run_id >> affiliation:Affiliation)
                   ( *memberable <<  seminar_member__teachers:SeminarMember::Teacher[( >> teacher:UserInfo)] ] "
                   
  Simulation_Entities_For_Seminars = ["seminars", "seminar_member__teachers", "teacher"]
    
  Def_Items = item_struct   "Seminar",  [:id,        "",       ".id"], [:run_id, "", ".run_id"],
                             [:name, "テーマ",    ".name", :h],
                             [:content, "内容",    ".body"],
                             [:teachers, "指導教員", "GROUP_CONCAT(teacher.real_name SEPARATOR '，')"],        # for listing only
                             [:seminar_teachers, "指導教員", :seminar_teachers, :render_seminar_teachers],  # for detail only
                             [:query_teacher, "指導教員", "teacher.real_name"],
                             [:seminar_member__teachers,"指導教員", :seminar_member__teachers],     # for input form only
                             [:affiliation, "学科", "affiliation.name"],
                             [:enrollments, "希望登録", :enrollments_for_ac_year, :render_enrollments],
                             [:limit_of_enrollments, "予定者数", ".students_limit"],
                             [:n_of_enrollments, "登録者数", :n_of_enrollments],
                             [:n_of_accepted_enrollments,"既採用数", :n_of_accepted_enrollments],
                             *(Base_Def_History_Items + Base_Def_Altering_Items)
                             
  List_Items = [:teachers, :affiliation, :name, :limit_of_enrollments, :n_of_enrollments, :n_of_accepted_enrollments]
  
  Detail_Items = [:name, :seminar_teachers, :content, :enrollments] + Base_History_Items
  
  History_Items = [:name] + Base_History_Items
  
  Def_Form_Items = form_item_struct Def_Items, 
                            [:seminar_member__teachers, nil,  :render_association_to_put, [{:required => true, :collection_name => "members",
                                                                                            :show_items => [:representative]}]],
                            [:limit_of_enrollments, :students_limit, nil, [{:required => true, :size => 3}]],
                            [:affiliation, :affiliation_name, :render_value_per_se],
                            [:name, nil, nil, [{:required => true}]],
                            [:content, :body, :text_area, [{:required => true}]]

  Form_Items = [:seminar_member__teachers, :affiliation, :name, :limit_of_enrollments, :content]
  
  # enrollment（配属希望登録） item definitions
  
  Def_Enrollment_Items = item_struct   "SeminarMember::Student",  [:id,        "",       ".id"], [:run_id, "", ".run_id"],
                             [:reason, "希望理由",    ".reason"],
                             [:is_accepted, "採否",  ".is_accepted", :render_accept_button],
                             [:student_name, "登録者",  :student_name],  # enroller's real name and student code.
                             *(Base_Def_History_Items + Base_Def_Altering_Items) 
                             
  Enrollment_List_Items = [:is_accepted, :reason, :student]
  
  Enrollment_Detail_Items = [:created_at, :reason]
  
  Enrollment_History_Items = Base_History_Items
  
  Def_Enrollment_Form_Items = form_item_struct Def_Enrollment_Items, 
                            [:student_name, nil, :render_value_per_se],
                            [:reason, nil, :text_area, [{:required => true}]],
                            Def_Since_Form_Item
                            
  Enrollment_Form_Items = [:student_name, :reason]
    
  Summing_Up_A_Net = ":self [( >> student:UserInfo)
                             ( >> *memberable :Seminar [( *memberable << seminar_member__teachers:SeminarMember::Teacher >> teacher:UserInfo)
                                                        ( .affiliation_run_id >> affiliation:Affiliation)])]"

  Def_Summing_Up_Items = item_struct   "SeminarMember::Student",  [:id,        "",       ".id"], [:run_id, "", ".run_id"],
                             [:is_accepted, "採否",  ".is_accepted", :render_accept_enrollment],
                             [:student_realname, "登録者名",  "student.real_name"],  # enroller's real name
                             [:student_username, "学籍番号", "student.name"], 
                             [:affiliation, "所属", "affiliation.name"],
                             [:teacher_name, "主担当教員", "teacher.real_name"]
                             
  Summing_Up_Items     = [:student_username, :student_realname, :is_accepted, :affiliation, :teacher_name]
  
  # ゼミの新規立ち上げを許すか？
  def allow_to_create_seminar?
    @stage && @stage <= 0 && (teacher? || admin?)
  end
  
  # ゼミの更新を許すか？
  def allow_to_update_seminar?(seminar = @entity)
    seminar && (seminar.seminar_teacher?(@current_user) || admin?)
  end
  
  # ゼミの削除を許すか？
  def  allow_to_delete_seminar?(seminar = @entity)
    @stage or return true
    @stage <= 0 && allow_to_update_seminar?(seminar)
  end

  # 配属希望登録(enrolment)の表示を行うか？
  def allow_to_display_enrollment?(enrollment)
    @stage.blank? and return false
    if undergraduate_student?
      (1..2).include?(@stage) && enrollment.student?(@current_user) ||                          # 自分の登録だけ表示
      (3..5).include?(@stage) && (enrollment.student?(@current_user) || enrollment.is_accepted) # 自分以外は採用のみ表示
    else
      teacher? 
    end
  end
  
  # 配属希望の登録を許可するか？
  def allow_to_enroll?(seminar = nil)
    @stage && ([1,3].include?(@stage)) && 
    not_accepted_yet(@current_user)  && # すでに採用されていないか？
    undergraduate_student? && 
    !allready_enrolled?(seminar)   # このseminarへの登録ははじめてか？
  end
 
  # 配属希望届けの変更を許すか？
  def allow_to_modify_enrollment?(enrollment)
    @stage && ([1,3].include?(@stage)) && 
    not_accepted_yet(@current_user) &&  # すでに採用されていないか？
    enrollment && (enrollment.student?(@current_user) || admin?) 
  end

  # 配属希望登録の採用を許すか？
  def allow_to_accept_enrollment?(enrollment)
    enrollment && (enrollment.seminar.seminar_teacher?(@current_user) || admin?) && 
    not_accepted_yet(enrollment.student) 
  end
  
  #　配属希望登録一覧表の表示を許すか？
  def allow_to_display_summing_up?
    (admin? || teacher?) &&
    @stage && @stage >= 1 
  end
  
  # 補助
  def allow_to_add_new_entity?(options = {})
    @view_allowed.to_a.include?(:adding_new_call)
  end
  
  def summing_up
    allow_to_display_summing_up? or return false
    redirect_to :controller => "/seminar_member/students"
  end
 
  private
  
  def find_collection   
    @header_local_info = Header_Local_Info
    
    flash_now @stage.blank? || @stage <  0,  "ゼミ登録コーナーは現在開いておりません．"
#    flash_now @stage && @stage == 0 && undergraduate_student?, "準備中です。お待ちください。"  
    
    @def_items = Def_Items
    @list_items = List_Items
    @queries    = [:query_teacher, :content]
  
    @view_allowed = allow_to_create_seminar? ? @view_allowed.to_a << :adding_new_call : @view_allowd.to_a - [:adding_new_call]
    teacher_representative_cond = "seminar_member__teachers.representative IS NULL OR seminar_member__teachers.representative = 1"
    @seminars = Seminar.find :all,
            :scope      => A_Net,
            :select     => select_items(@def_items, @list_items + [:id, :run_id]),
            :conditions => merge_conditions(query_cond),
            :order      => "affiliation.fullseq, seminars.run_id",
            :group      => "seminars.id"
    @collection = @seminars
    @entity_template = "shared/entity_with_remote_detail_call" 
    flash_now @collection.blank?, "該当するゼミはありません．"   
  end

  def find_detail
    @def_items = Def_Items
    @detail_items = Detail_Items
    
    @entity = find_entity :scope  => A_Net, 
                          :assert_time => :anytime,
                          :select => select_items(@def_items, @detail_items + [:id, :run_id])
                          
    @enrollments = @entity.enrollments_for_ac_year
    @background_params.merge!(:seminar_id => @entity.to_param)
  end

  def set_action_timing
    @year = get_academic_year
    
    @schedules = SeminarEnrollmentSchedule.find_schedules(@year)

    state = @schedules.find do |sch|
      (sch.start_time..sch.end_time).include? @show_time
    end
    
    @stage = state ? state.stage : -1
  end
  
  def find_history
    @def_items  = Def_Items
    @list_items = History_Items + [:id, :run_id]
    @collection = @entity.history :distinct => select_items(@def_items, @list_items)
  end
  
    
  # creating seminar                
  def prepare_for_new(init = {})
    flash_now !allow_to_create_seminar?, "不的確なアクセスです．"
    # seminar's affiliation is main affiliaiton of seminar teacher(@current_user)
    affiliation = @current_user.main_affiliation
    @seminar = @entity = Seminar.new_run( :affiliation_run_id => affiliation.run_id )
    @seminar.seminar_member__teachers.build :user_info_run_id => @current_user.run_id, :representative => true
    preparation_for_altering
  end
  
  # updating seminar
  def prepare_for_updating
    @seminar = @entity
    flash_now !allow_to_update_seminar?(@seminar), "不的確なアクセスです．"
    preparation_for_altering
  end
  
  def preparation_for_altering
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
  end

  def allready_enrolled?(seminar = nil)
    seminar.nil? and return true
    # check on enrollments during academic year.
    seminar.enrollments_for_ac_year.map(&:student).include?(@current_user)
  end
  
  def not_accepted_yet(student)
    SeminarMember::Student.not_accepted_yet(student)
  end
  
  # for before filter
  def seminar_teachers_only
    render_flash_now_if !allow_to_update_seminar?, "このゼミの担当教員のみ許可されます．"
  end

end