=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class ReportsController < RunsController
  
  Commented = ReportComment::Commented
  Uncommented = ReportComment::Uncommented
  
  Assoc_Net_To_Exercise = "[(>> :self)
                            ([(.created_by >> author:UserInfo)(~<- :ReportComment)])]"   
                            
  Def_Items = item_struct "Report", [:id, "", ".id"], [:run_id, "", ".run_id"],
                      [:author, "作成者；学籍番号",  "CONCAT_WS(':', author.real_name, author.name)"],
                      [:author_student, "作成者", :author_student, :user_info_detail_link],
                      [:student_code, "学籍番号", "author.name"],
                      [:student_name, "作成者名", "author.real_name"],
                      [:title, "題目", ".title", :h],
                      [:content, "本文",  ".body"],
                      [:exercise, "", :exercise],
                      [:report_comments, "", :report_comments], # input only
                      [:judgement, "採点チェック",  "report_comments.judgement"],
                      [:has_judged?, "採点済み？", :has_judged?],
                      [:attached_files, "添付ファイル", :attached_files],
                      *(Base_Def_History_Items + Base_Def_Altering_Items)
  List_Items = [:author, :title, :created_at, :has_judged?]
  Detail_Items = [:author_student, :title, :content, :attached_files]
  
  Def_Report_Comment_Items = item_struct "ReportComment", [:id, "", ".id"], [:run_id, "", ".run_id"],
                      [:correction, "添削", ".report_tennsaku"],
                      [:comment, "コメント", ".comment"],
                      [:point, "採点", ".point"],
                      [:commentator, "コメンテータ", :commentator, :user_info_detail_link],                     
                      [:judgement, "採点チェック",  "report_comments.judgement"],
                      [:report, "", :report],
                      *(Base_Def_History_Items + Base_Def_Altering_Items)
  Report_Comment_Items = [:since, :judgement, :correction, :comment, :point, :commentator]
  
  Query_Items = [:student_code, :student_name, :content, :judgement]
  History_Items = [:title] + Base_History_Items 
  Def_Form_Items = form_item_struct Def_Items,
                    Def_Since_Form_Item,
                    [:title, nil, nil, [:required => true]],
                    [:content, :body, :text_area, [:required => true, :html_options=>"rows=30"]],
                    [:exercise, :exercise_run_id, :hidden_field],
                    Def_Attached_File_Form_Item
                    
  Form_Items    = [:exercise, :title, :content, :attached_files]
  
  Def_Report_Comment_Form_Items = form_item_struct Def_Report_Comment_Items,
                   [:correction, :report_tennsaku, :text_area],
                   [:comment, nil, :text_area],
                   [:point],
                   [:judgement, nil, :select, [[Commented, Uncommented]]],
                   [:report, :report_run_id, :hidden_field]
                   
  Report_Comment_Form_Items = [:report, :correction, :comment, :point, :judgement]
  
  protected
  
  def find_collection
    @def_items = Def_Items
    @list_items = List_Items
    @queries    = Query_Items
    
    @exercise = Run.find_entity(params[:exercise_id])  # CAUTION: Do not call RunController "find_entity"
    teachers  = @exercise.teachers
    tas       = @exercise.tas
                               
    teachers_and_tas = (teachers + tas).map(&:run_id)
                                  
    open_cond       = @exercise.is_open
    member_cond     = teachers_and_tas.include?(@current_user.run_id)
    creater_cond    = @current_user.run_id == @exercise.created_by
    basic_show_cond = open_cond || member_cond  || creater_cond
    show_cond = basic_show_cond ? nil : "reports.created_by = #{@current_user.run_id}"
    @collection = @exercise.associated_with "Report", Assoc_Net_To_Exercise,
           :assert_time => :anytime,
           :group => "reports.run_id",
           :order => "reports.since DESC, report_comments.since DESC",
           :select      => select_items(@def_items, @list_items + [:id, :run_id]),
           :conditions  => merge_conditions(show_cond, query_cond),
           :order       => "reports.created_at" 
    flash_now @collection.blank?, "該当するレポートはありません．"
  end
  
  def find_detail
    @def_items = Def_Items
    @detail_items = Detail_Items
    
    @def_report_comment_items = Def_Report_Comment_Items
    @report_comment_items = Report_Comment_Items
    
    unchecked = params[:to_unchecked]  # true when getting next unchecked report detail
    cond = unchecked ? "report_comments.judgement <> '#{Commented}'"  : "reports.run_id = #{@entity.run_id}"
    @entity = Report.find  :first,
                           :scope => ":self [(.created_by >> author:UserInfo)(~<- :ReportComment)]",
                           :distinct    => select_items(@def_items, @detail_items + [:id, :run_id]),
                           :assert_time => :anytime,
                           :order => "reports.created_at DESC",
                           :conditions  => cond
    flash_now @entity.blank?, "該当するレポートはありません．"
                           
    @report_comment = @entity.report_comment :select => select_items(@def_report_comment_items, @report_comment_items + [:id, :run_id])
    @has_judged = @entity.has_judged? == Commented
    # restrict to updating
    !@has_judged && (admin_or_owner_of?(@entity)) and @detail_items << :updating

    lecture_teacher_ids = (@entity.exercise.teachers + @entity.exercise.tas).map(&:run_id)
    @one_of_lecture_teachers = lecture_teacher_ids.include?(@current_user.run_id)
  end
  
  def find_history
    @def_items  = Def_Items
    @list_items = History_Items
    @collection = @entity.history  
  end
  
  def prepare_for_new
    preparation_for_altering
    @exercise = find_entity(@background_params[:exercise_id])
    @report = @entity = Report.new_run
    @report.build_exercise(@exercise)
    @report.title = @exercise.title
  end
  
  def prepare_for_updating
    preparation_for_altering
    @report = @entity = find_by_entity_ref
  end
  
  def preparation_for_altering
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items    
  end
	
end
