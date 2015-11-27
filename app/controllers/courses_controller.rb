=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# 旧版では syllabusに相当
# 通常「科目」と呼ばれる．
class CoursesController < RunsController
    
  skip_before_filter :login_required, :only => [:index, :search, :show, :set_academic_year, :set_academic_season, :update_tree_select]
  
  skip_before_filter :owner_only
  
  # courses are total representation so only admin is allowed to change
  #  (lectures may be changed by their teacher members and syllabuses by their owners.)
  before_filter      :admin_only, :only => Committing_Actions + Commitment_Actions
  
  Course_Header_Local_Info = ["カリキュラム・シラバス関連のコーナーです．",
                              "科目名一覧から，それぞれの授業詳細，シラバスなどを知ることが出来ます．",
                              "教職員は，（許可される範囲で）新規作成，更新が行えます．"]
                              
  Lec_Schedule_Local_Info = ["授業の時間割を表示します．"]
   
  # parents in fullnames of affiliation and status queries
  Root_Of_Affiliation = "全員|中京大学|"
  Root_Of_Status      = "ステータス|"
        
  # range of day of week as wday
  # exclude sunday(wday == 0)
  Wday_Range = 1..6   
  
  # lesson time(時限)
  Lecture_Time_Range = LectureTime::Lecture_Time_Range
  
  # exclude from list of selection for affiliations which have no lecture courses
  Out_Of_Selection_For_Aff = %w{学外 事務局本部 その他学部 人工知能高等研究所 事務室 スタッフ}
  Out_Of_Selection_For_Sta = %w{教職員 公開ユーザ 学部研究生等 大学院研究生等 卒業}
  
  # exclude from hierarchy expression of affiliation and status to simplify.
  Affiliations_To_Neglect = %w{中京大学 学外 学部 大学院}
  Status_To_Neglect       = %w{学部生 院生}
  
  Must_Or_Choice    = %w{必修 選択 必修選択}
  Additional_Or_Not = %w{本履修 他学科履修}
  Open_Or_Not       = %w{開講 不開講}
  Do_Or_Dont        = [["する", 1], ["しない", 0]]

  Queries = [:teacher_name, :ta_name, :student, :title, :abstract] 
  
  # SyClass in old version
  # Note: organization is one to one.
  Course_Class_Assocs = " :CourseClass 
                                *organized_entity <- :Organization [( .affiliation_run_id -> affiliation:Affiliation)
                                                                    ( .status_run_id -> status:Status)] "
                                                                    
  # portal for SyResourse in old intrasite
  Lecture_Time_Assocs   = "( << :LectureTime)"  
  # Subject association in old intrasite
  Syllabus_Assoc = "(  >> :Syllabus)"
  # portal for SyTeachers in old intrasite
  Teacher_Member = "( *memberable << lec_teach:LectureMember::Teacher >> teachers:UserInfo )"  
  # association to TAs in old intrasite
  TA_Member      = "( *memberable << lec_ta:LectureMember::TA >> tas:UserInfo )"
  # portal for SyStudent in old intrasite
  Student_Member = "( *memberable << lec_stud:LectureMember::Student >> students:UserInfo )"
  
  # display items
  
  Def_Course_Items_List =  [:title,        "科目名", ".name", :h],
                           [:subtitle,     "副題", ".subtitle", :h],
                           [:english_name, "Course name", ".english_name", :h],
                           [:seq, "科目順コード", ".seq", :h], # 科目表示の順を与える（旧版にはない）．
                           [:course_classes, "対象クラス", :course_classes, "course_class_list_entity"],
                           [:lectures,       "授業",      :lectures,       "lecture_list_entity"],
                           *(Base_Def_History_Items + Base_Def_Altering_Items)
  Def_Course_Items = item_struct "Course", [:id, "", ".id"], [:run_id, "", ".run_id"],  *Def_Course_Items_List
  Course_Items     = [:title, :english_name, :subtitle]
  History_Items   =  [:title] + Base_History_Items
  
  Def_Course_Class_Items_List = [:organizations, "対象クラス単位", :organizations],
                                [:course_group, "科目群", "course_classes.class_Kei"],   # 旧版でのとりちがい補整
                                [:course_series, "科目系", "course_classes.class_Gun"],  # 旧版でのとりちがい補整
                                [:party, "班", "course_classes.party"],
                                [:must_or_choice, "必修，選択", "course_classes.must_or_choice"],
                                [:additional, "他学科履修？", "course_classes.main_or_sub"],
                                [:open, "開講？", "course_classes.open"],
                                [:notices_for_math_teacher_candidates, "教職（数学）", "course_classes.teacher_for_math"],
                                [:notices_for_info_teacher_candidates, "教職（情報）", "course_classes.teacher_for_info" ],
                                [:for_web, "webに表示", "course_classes.for_web"],
                                [:for_print, "パンフレットに表示", "course_classes.for_print"],
                                [:comment,   "備考", "course_classes.comment"],
                                *Base_Def_History_Items
                                
  Def_Course_Class_Items = item_struct "CourseClass", [:id, "", ".id"], [:run_id, "", ".run_id"],  *Def_Course_Class_Items_List
  Course_Class_Items     = Def_Course_Class_Items_List.map(&:first) - [:for_web, :for_print]
                           
  Def_Lecture_Items_List = [:teacher_name, "担当教員", "teachers.real_name"],
                           [:lecture_member__teachers, "担当教員", :lecture_member__teachers, :render_members_detail_links],
                           [:ta_name,      "TA",       "tas.real_name"],
                           [:lecture_member__t_as,     "TA",     :lecture_member__t_as,      :render_members_detail_links],
                           [:syllabus, "シラバス",     :syllabus, "syllabuses/detail"],
                           [:lecture_course_classes,"対象クラス", :lecture_course_classes], 
                           [:student,      "履修者学籍番号", "students.name"],
                           [:lecture_times,  "時間．場所", :lecture_times], 
                           [:lecture_time, "時限", "lecture_times.lecture_time", :render_lecture_time],
                           [:day_of_week,  "曜日", "lecture_times.day_of_week", :render_day_of_week],
                           [:season,       "学期", "lecture_times.season", :render_lecture_season],
                           [:campus,       "学舎", "lecture_times.campus"],
                           [:room,         "教室", "lecture_times.room", :render_lecture_room],
                           *(Base_Def_History_Items + Base_Def_Altering_Items)
                           
  Lecture_Items = Def_Lecture_Items_List.map(&:first)
                           
  Def_Syllabus_Items_List = [:syllabus_title,       "シラバス名",  "syllabuses.name"],
                           [:abstract,              "授業概要", "syllabuses.goal"],
                           [:lecture_goal,          "授業目標", "syllabuses.teaching_goal"],
                           [:lecture_method,        "授業方法", "syllabuses.teaching_style"],
                           [:question_method,       "質問への対応", "syllabuses.question"],
                           [:lecture_plan,          "授業計画", "syllabuses.detail"],
                           [:performance_evalation, "成績評価法", "syllabuses.judgment"],
                           [:pre_requisit,          "前提科目", "syllabuses.base_subject"],
                           [:related_subject,       "関連科目", "syllabuses.relate_subject"],
                           [:notices,               "注意事項", "syllabuses.comment"],
                           [:syllabus_books,        "教科書・参考書", :syllabus_books],
                           [:attached_files,        "添付ファイル", :attached_files ],
                           *(Base_Def_History_Items + Base_Def_Altering_Items)
                           
  Def_Syllabus_Items = item_struct "Syllabus", [:id, "", ".id"], [:run_id, "", ".run_id"],  *Def_Syllabus_Items_List  
  Syllabus_Items = Def_Syllabus_Items_List.map(&:first)
  Syllabus_Render_Items = Syllabus_Items - Base_History_Items
  
  Def_Syllabus_Book_Items_List = [:book_type, "種類",      "syllabus_books.book_type"],
                                 [:title,     "書名・説明", "syllabus_books.title"],
                                 [:isbn,      "ISBN",     "syllabus_books.isbn"],
                                 [:isbn10,    "ISBN10",   "syllabus_books.isbn10"],
                                 [:isbn13,    "ISBN13",   "syllabus_books.isbn13"]
  Def_Syllabus_Book_Items = item_struct "SyllabusBook", [:id, "", ".id"], [:run_id, "", ".run_id"], *Def_Syllabus_Book_Items_List  
  Syllabus_Book_Items     = [:book_type, :title, :isbn, :isbn10, :isbn13]
  
  Def_Items = item_struct "Course", *(Def_Course_Items_List + Def_Course_Class_Items_List + Def_Lecture_Items_List + Def_Syllabus_Items_List )                    
  
  # input items
  
  Def_Course_Form_Items = form_item_struct Def_Items,
                           Def_Since_Form_Item,
                           [:title, :name, nil, [:required => true]],
                           [:subtitle],
                           [:seq],
                           [:english_name],
                           [:season, nil, :select, [LectureTime::Seasons]],
                           [:course_classes, nil, :render_association_to_put, [:required => true]],
                           [:lectures, nil, :render_association_to_put]
  Course_Form_Items = [:since, :title, :subtitle, :english_name, :season, :course_classes, :lectures]
  
  Def_Course_Class_Form_Items = form_item_struct Def_Items,
                            Def_Since_Form_Item,
                            [:organizations, nil, :render_association_to_put, [
                                                                          :required => true,
                                                                          :out_of_selection_for_aff => Out_Of_Selection_For_Aff,
                                                                          :out_of_selection_for_sta => Out_Of_Selection_For_Sta,
                                                                          :show_items => [:affiliation, :status, :seq]]], 
                            [:course_group, :class_Kei, :render_select_by_existing_values],
                            [:course_series, :class_Gun, :render_select_by_existing_values],
                            [:party],
                            [:must_or_choice, :must_or_choice, :select, [Must_Or_Choice]],
                            [:additional,     :main_or_sub,    :select, [Additional_Or_Not]],
                            [:open,           :open,           :select, [Open_Or_Not]],
                            [:notices_for_math_teacher_candidates, :teacher_for_math],
                            [:notices_for_info_teacher_candidates, :teacher_for_info ],
                            [:for_web, nil, :select, [Do_Or_Dont]],
                            [:for_print, nil, :select, [Do_Or_Dont]],
                            [:comment, nil, :text_area]
  Course_Class_Form_Items = [:since, :organizations, :course_group, :course_series, :must_or_choice, :additional, :open, 
                             :notices_for_math_teacher_candidates,:notices_for_info_teacher_candidates,:for_web, 
                             :for_print,:comment]
  
  Def_Lecture_Form_Items = form_item_struct Def_Items,
                           Def_Since_Form_Item,
                           [:lecture_member__teachers, nil, :render_association_to_put, [:collection_name => "members", :show_items => [:since]]],
                           [:lecture_member__t_as,     nil, :render_association_to_put, [:collection_name => "members", :show_items => [:since, :till]]],
                           [:syllabus,      nil,            :render_association_to_put, [:single => true, :show_items => [:since]]],
                           [:lecture_course_classes, nil, :render_association_to_put, [:association_template=> "lecture_course_classes/input/lecture_course_classes", :required => true]],
                           [:lecture_times, nil, :render_association_to_put]
  Lecture_Form_Items     = [:since, :syllabus, :lecture_course_classes, :lecture_member__teachers, :lecture_member__t_as, :lecture_times]
  
  Def_Lecture_Time_Form_Items = form_item_struct Def_Items,
                           Def_Since_Form_Item,
                           [:lecture_time, nil, :select, [LectureTime::Lecture_Times]],
                           [:day_of_week,  nil, :select, [LectureTime::Days_Of_Week]],
                           [:season,       nil, :select, [LectureTime::Seasons]],
                           [:campus,       nil, :select, [LectureTime::Campus]],
                           [:room]
                           
  Lecture_Time_Form_Items = [:since, :lecture_time, :day_of_week, :season, :campus, :room]
  
  Def_Syllabus_Form_Items = form_item_struct Def_Items,
                           Def_Since_Form_Item,
                           [:syllabus_title, :name, nil, [:required => true]],
                           [:abstract,              :goal, :text_area, [:required => true]],
                           [:lecture_goal,          :teaching_goal, :text_area, [:required => true]],
                           [:lecture_method,        :teaching_style, :text_area, [:required => true]],
                           [:question_method,       :question, :text_area, [:required => true]],
                           [:lecture_plan,          :detail, :text_area, [:required => true]],
                           [:performance_evalation, :judgment, :text_area, [:required => true]],
                           [:pre_requisit,          :base_subject, :text_area],
                           [:related_subject,       :relate_subject, :text_area],
                           [:syllabus_books,        nil, :render_association_to_put],
                           [:notices,               :comment, :text_area],
                           [:attached_files, nil, :render_association_to_put, [:legend => "添付ファイル", :entity_template => "attached_files/input/collection"]]
  Syllabus_Form_Items    = [:since, :syllabus_title, :abstract,:lecture_goal, :lecture_method, 
                            :lecture_plan, :performance_evalation, :question_method, 
                            :pre_requisit, :related_subject, :notices, :syllabus_books, :attached_files]
                            
  Def_Syllabus_Book_Form_Items = form_item_struct Def_Syllabus_Book_Items,
                           [:book_type, nil, :select, [SyllabusBook::Book_Types]],
                           [:title],
                           [:isbn],
                           [:isbn10],
                           [:isbn13]
  Syllabus_Book_Form_Items = Syllabus_Book_Items - [:id, :run_id]
  
  def index
    @mobile = params["mobile"] == "true"
    catch :flash_now do 
      find_collection
    end
    if @mobile
      render :partial => "courses_for_mobile", :layout => "mobiles"
      return false
    end   
  end
  
  def set_academic_season
    receive_and_set_background_params
    @background_params.merge! :academic_year   => params[:academic_year],
                              :academic_season => params[:academic_season]
    arrange_environment_from_background
   
    render :update do |page|
      page[:depending_on_academic_season].reload
    end
  end
  
  def allow_to_add_new_entity?(opts = {})
    admin?  
  end

  def search
    @mobile = params[:mobile] == "true"
    catch(:flash_now) do find_collection end
    template = @display_mode == "list" ? "/shared/collection" : "schedules"
    render :update do |page|
      page[:collection].replace  :partial => template
    end
  end
 
  # show detail of a course entity as AJAX
  def show
    @mobile = @background_params[:mobile] == "true"
    catch :flash_now do find_detail end
    div_id = params[:div_id]
    render :update do |page|
      page[div_id].replace_html  :partial => "detail"
    end
  end

  private
  
  def cat
   @degree == "大学院" ?  Root_Of_Status + "院生|"  :  Root_Of_Status + "学部生|"
  end
  
  def find_collection
    arrange_environment_from_background
    
    if @display_mode == "list"
      @header_local_info = Course_Header_Local_Info
      @lec_schedule_local_info = Lec_Schedule_Local_Info
          
      # for displaying list of courses; primary model is :Course with CourseClass.
      @def_items = Def_Items.merge( item_struct("Course", [:id, "", ".id"], [:run_id, "", ".run_id"]) )
      @list_items = @mobile ? [:title] :  Course_Items
      
      list_scope = unless @query_params.detect{|k, v| k != "title" && !v.blank?}
                     ":Course << #{Course_Class_Assocs}"
                   else  # lecture concerned
                     ":Course << :Lecture [#{lecture_member_scope()}]"
                   end
      @collection = Course.find :all,
                           :page       => current_page,
                           :scope      => list_scope,
                           :select     => select_items(@def_items, @list_items + [:id, :run_id]),
                           :group      => "courses.run_id",
                           :conditions => merge_conditions( @season_cond, @affiliation_cond, @status_cond, query_cond() ),                          
                           :order      => "courses.seq, affiliation.fullseq, status.fullseq, course_classes.fullseq"
                                
      admin? and @view_allowed = @view_allowed.to_a << :adding_new_call
      
      flash_now @collection.blank?, "該当する授業はありません．"

      # set entity template as with toggled detail call
      @entity_template = "shared/entity_with_toggled_detail_call"
      
    else
      # for displaying lecture time schedules; primary model is :Lecture.
      @def_items = Def_Items.merge( item_struct("Lecture", [:id, "", ".id"], [:run_id, "", ".run_id"]))

      lectures = Lecture.find :all, 
                              :scope      => ":Lecture [(>> :Course)
                                                        #{lecture_member_scope()}]",
                              :select     => select_items(@def_items, 
                                                          (Lecture_Items + [:id]) + Course_Items - [:student,:ta_name]),
                              :conditions => merge_conditions( @season_cond, @affiliation_cond, @status_cond, query_cond() ),
                              :group      => "lectures.id"
                       
      to_lecture_schedules(lectures)
    end  

  end
     
  def find_history   
    @def_items  = Def_Course_Items
    @list_items = History_Items
    @collection = @entity.history :distinct => select_items
    @entity_template = "shared/entity_with_toggled_detail_call"
  end

  
  def find_detail
    @course = @entity
    arrange_environment_from_background 
    @def_items     = Def_Items
    @detail_items  = Course_Items
    # aff and sta to ignore to express them from fullname
    @aff_and_sta_to_neglect  = Affiliations_To_Neglect + Status_To_Neglect
    @def_course_class_items = Def_Course_Class_Items
    @course_class_items     = Course_Class_Items

    # set course_classes of @course
    @course.course_classes :select => select_items(@def_course_class_items, [:id, :run_id] + @course_class_items),
                            :conditions => merge_conditions(@affiliation_cond, @status_cond),
                            :group => "course_classes.id"

    (q_cond = query_cond()).blank? or q_cond.first.gsub!(/courses/, Run::Self_Entity)
    # set lectures of @course
    @course.lectures :assoc_net  => "[(>> :self)#{lecture_member_scope()}]",
                      :conditions => q_cond,
                      :group => "lectures.id"
  end
  
  def arrange_environment_from_background    
    # if not logged in, regard user as guest temporally.
    if @current_account.blank?
      Run.current_account = Account.guest_account
      @current_user = Run.current_user
    end
                              
    @out_of_selection_for_aff = Out_Of_Selection_For_Aff
    @out_of_selection_for_sta = Out_Of_Selection_For_Sta
    
    @background_params.blank? and return

    # from academic year selection
    @academic_year = get_academic_year(@background_params[:academic_year])
    # from season selection
    @academic_season = get_academic_season(@background_params[:academic_season])
    
    # assert time is given by time span for academic season.
    set_assert_time_as_end_of_academic_season_range
         
    @season_cond = @academic_season.blank? ? nil :  "courses.season LIKE '%#{@academic_season}%'"
    
    # for query_cond() and query bar
    @queries = Queries
    @query_params = @background_params[:query] || {}
    
    # display mode : list or lecture schedule（時間割）
    @display_mode = @background_params[:display_mode] || "list"

    # graduate school(大学院) or undergraduate school(学部)
    @degree = @background_params[:degree] || "学部"
 
    default_affiliation_fullname = 
      if @degree.blank? && @current_user
        # current_user's representative affiliation
        guest?  ? Root_Of_Affiliation + "学部|"  : @current_user.affiliation_name
      else
        Root_Of_Affiliation + @degree + "|"
      end
    default_status_fullname =
      if @current_user
        case @current_user.category
          when "教職員", "公開ユーザ"
            @degree = cat
          when "学部生", "院生"
            @degree.blank? ? @current_user.status_name : cat
        end
      else
        @degree = cat
      end
     
    @aff_root = Affiliation.find :first,
                             :scope => ":self",
                             :conditions => "name = '中京大学'"
    @sta_root = Status.find :first,
                             :scope => ":self",
                             :conditions => "name = 'ステータス'"                         
    # @background_params[:selected_affiliation] is selected  id:Affiliation
    @affiliation = 
      unless (entity_id = @background_params[:affiliation]).blank?
        Run.find_entity(entity_id)
      else
        Affiliation.find :first, 
                         :scope => ":self",
                         :conditions => {:fullname => default_affiliation_fullname}
      end
    @status = 
      unless (entity_id = @background_params[:status]).blank?
         Run.find_entity(entity_id)
      else
        Status.find      :first, 
                         :scope => ":self",
                         :conditions => {:fullname => default_status_fullname}
      end
   
    @affiliation_cond = ["(affiliation.fullname LIKE CONCAT(:affiliation, '%') OR :affiliation LIKE CONCAT(affiliation.fullname, '%'))", 
                         {:affiliation => (@affiliation ? @affiliation.fullname : Root_Of_Affiliation + "学部|")}]
    @status_cond =      ["(status.fullname LIKE CONCAT(:status, '%') OR :status LIKE CONCAT(status.fullname, '%'))", 
                         {:status => (@status ? @status.fullname : default_status_fullname)}]
  end
  
  # scope for attendant members to lecture; depends on params[:query]
  def lecture_member_scope()
    scp = []<< "(<< :LectureCourseClass >> #{Course_Class_Assocs})" 
    scp << Lecture_Time_Assocs unless @display_mode == 'list'
    @query_params ||={}
    scp << Syllabus_Assoc unless @query_params[:abstract].blank? 
    scp << Teacher_Member unless @display_mode == 'list' && @query_params[:teacher_name].blank?
    scp << TA_Member      unless @query_params[:ta_name].blank?
    scp << Student_Member unless @query_params[:student].blank?
    return scp.join('')
  end
  
  # preparation for displaying lecture schedule 
  # output @lecture_schedules, @extra_schedules; the entities are lecture.
  def to_lecture_schedules(lectures)    
    @lecture_schedules = []
    Lecture_Time_Range.each do |lt|
      week_sum = [lt]
      Wday_Range.to_a.each do |wday|
        contents = lectures.select do |c|
          c.lecture_time.to_i == lt && c.day_of_week.to_i == wday
        end
        week_sum << contents
        lectures -= contents
      end
      @lecture_schedules << week_sum
    end
    # courses which are out of specified schedule ranges.
    @extra_schedules = lectures
  end

  
  # --- altering 
   
  # for creating new course
  def prepare_for_new
    arrange_environment_from_background
    default_attrs = environmental_attributes
    @course = @entity = Course.new_run( default_attrs[:course] )
    course_class = @course.course_classes.build default_attrs[:course_class]
    course_class.organizations.build default_attrs[:organization]
    preparation_for_altering
    # exclude creating lecture when creating new course, since no course_classes as lecture_course_classes are determined yet.
    @course_form_items = Course_Form_Items - [:lectures]
  end
  
  # attributes reduced from @background_params
  def environmental_attributes
    default_since = beginning_of_academic_season(@academic_year, @academic_season)
    {:lecture_time         => {:since => default_since, 
                               :season => @academic_season},
     :organization         => {:since => default_since, 
                               :affiliation_run_id => @affiliation.run_id,
                               :status_run_id      => @status.run_id},
     :course               => {:since => default_since, :season => @academic_season},
     :course_class         => {:since => default_since, 
                               :for_web => 1, :for_print => 1}}
  end
  
  # for updating course
  def prepare_for_updating
    arrange_environment_from_background
    set_assert_time_as_end_of_academic_season_range
    # default since through whole composite entity
    @default_since = beginning_of_academic_season(@academic_year, @academic_season)
    @course = @entity = find_by_entity_ref(@default_since)
    preparation_for_altering
    @course_form_items = Course_Form_Items
    @course_classes = @course.course_classes
    flash_now @course_classes.blank?, "注意：科目の対象クラスを作成，登録したのちに行ってください．"
  end
  
  def preparation_for_altering   
    @def_course_form_items  = Def_Course_Form_Items
    @def_course_class_form_items = Def_Course_Class_Form_Items
    @course_class_form_items     = Course_Class_Form_Items - [:since]
    @def_lecture_form_items = Def_Lecture_Form_Items
    @lecture_form_items     = Lecture_Form_Items - [:since]
    @def_lecture_time_form_items = Def_Lecture_Time_Form_Items
    @lecture_time_form_items     = Lecture_Time_Form_Items - [:since]

    # view items for organization
    @view_allowed = [:member_new_call, :org_affiliation, :org_status]
  end
    
  def prepare_for_destroying
    @def_form_items = Def_Course_Form_Items
    @form_items     = Form_Deleting_Items    
  end

  def after_put
     attached_files_connection(@entity)
  end

end