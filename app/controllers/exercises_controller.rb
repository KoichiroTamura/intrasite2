=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# 旧版の「レポート課題」に対応
class ExercisesController < RunsController
  
  before_filter :local_registered_only # necessary because RunsController declares registered_only filter.
  
  Header_Local_Info = ["レポート課題を表示し，レポートを受け付けます．",
                       "教職員のみ，出題できます（レポート提出は自由ですが，出題された授業の受講者を想定します）．",
                       "授業の担当教員は，その授業からの出題へのレポートの添削，コメント付け，そして，採点を行えます．",
                       "さらに，授業ごとに，担当教員は当該学期における学生別成績一覧を見ることが出来ます．"]
  Related_Lec_Local_Info = ["教員ならば担当授業，学生ならば受講している授業からの出題のみ表示します．"]
  
  A_Net = ":self [( >> :Lecture [ (>> :Course) 
                                  ( *memberable << :Member >> user:UserInfo )])
                  (.created_by >> teacher:UserInfo)]"
                    
  Def_Items = item_struct "Exercise", [:id, "", ".id"], [:run_id, "", ".run_id"],
                      [:title, "タイトル",  ".title"],
                      [:course_name, "科目名", "courses.name"],
                      [:lecture_run_id, "科目"],  # for input only
                      [:teacher, "出題者",  "teacher.real_name"],
                      [:content, "課題内容",  ".body"],
                      [:is_open, "提出レポート：",  ".is_open", :publicity_level] ,
                      [:created_by, "",  ".created_by"] ,
                      [:limit_date, "締め切り", ".limit",      :time_in_japanese_style],
                      [:attached_files, "添付ファイル", :attached_files],
                      *(Base_Def_History_Items + Base_Def_Altering_Items)
                      
  List_Items = [:id, :run_id, :title, :course_name, :teacher, :since]
  
  History_Items = [:title] + Base_History_Items
  
  Detail_Items = [:title, :course_name, :teacher, :created_at, :limit_date, :is_open, :content, :attached_files]
  
  Def_Stochastics_Items = item_struct "UserInfo", [:id, "", ".id"], [:run_id, "", ".run_id"],
                     [:name, "ユーザ名", ".name"],
                     [:real_name, "実名", ".real_name"],
                     [:count, "レポート数", "COUNT(reports.run_id)"],
                     [:sum, "総計点", "SUM(report_comments.point)"],
                     [:average, "平均", "AVG(report_comments.point)"]
                     
  Def_Form_Items = form_item_struct Def_Items,
                    Def_Since_Form_Item,
                    [:title, nil, nil, [:required => true]],
                    [:lecture_run_id, nil, :select_with_default, [:course_choices]],
                    [:content, :body, :text_area, [:required => true, :html_options=>"rows=30"]],
                    [:is_open, nil, :radio_button_selection, [[true, "公開する"], [false, "出題者と作成者のみ閲覧可とする"]]],
                    [:limit_date, :limit, :datetime_select_jp],
                    Def_Attached_File_Form_Item
                    
  Form_Items    = [:title, :is_open, :limit_date, :lecture_run_id, :content, :attached_files]
  
    
  def allow_to_add_new_entity?(opts = {})
    !Exercise.new.related_courses.blank?
  end

  # stochastics of student performance through lecture of the exercise
  def stochastics_of_students
    catch :flash_now do
      receive_and_set_background_params
      setting_global_assert_time_with_academic_season
      academic_season_cond = set_academic_season_cond("reports", :created_at)
     
      @exercise = find_entity      
      @def_items = Def_Stochastics_Items     
      @lecture  = @exercise.assoc_dependee "Lecture", "[(<< :self)
                                                        (>> :Course)]", 
                       :assert_time => :anytime,
                       :select      => {:id => "lectures.id", :run_id => "lectures.run_id", :course_name => "courses.name"}
      flash_now @lecture.blank?, "該当する授業がありません．"
      
      @collection = @lecture.associated_with "UserInfo", "<- .created_by :Report[( >> :Exercise >> :self)
                                                                                 ( <- :ReportComment )]",
                       :select => select_items,
                       :conditions  => academic_season_cond,
                       :group  => "user_infos.name"
      @view_allowed = [:no_detail_call]
      @menu_name = "#{@lecture.course_name} 学生別成績一覧"
    end
    render :partial => "stochastics_of_students", :layout => "base_layout", :target => "_new"
  end
  
 protected
  
  def find_collection
    @header_local_info = Header_Local_Info
    @related_lec_local_info = Related_Lec_Local_Info
    
    setting_global_assert_time_with_academic_season()
    academic_season_cond = set_academic_season_cond("exercises")
  
    # designated in course corner as a lecture exercise（シラバスコーナーで，授業のレポート課題として呼ばれる場合）
    @lecture = @background_params[:lecture]
                              
    lecture_cond = @lecture.blank? ? "TRUE" : "(exercises.lecture_run_id=#{@lecture.to_id})" 
    # all or only related to display exercises
    @all_or_related = @background_params[:all_or_related] || "related"                     
    
    @def_items = Def_Items
    @list_items = List_Items - [:id, :run_id]
    @collection = Exercise.find :all, 
                                :scope      => A_Net,
                                :distinct   => select_items,
                                :page       => current_page,
                                :conditions => merge_conditions(academic_season_cond, related_cond, lecture_cond),
                                :order      => "exercises.since DESC"
                                
    flash_now @collection.blank?, "該当する課題はありません．"

  end
         
  def find_history   
    @def_items  = Def_Items
    @list_items = History_Items
    @collection = @entity.history
  end
  
  def find_detail
    setting_global_assert_time_with_academic_season
    
    @def_items = Def_Items
    @exercise_items = Detail_Items
    owner_of? and @exercise_items += [:updating, :deleting]
    
    @entity =  find_entity :scope       => A_Net,
                           :select      => select_items
                         
    flash_now @entity.blank?, "該当する課題はありません．"   
            
    # number of reports submitted to the exercise
    @n_of_reports = @entity.reports.size
    
    # get number of reports, average and standard deviation of points of reports submitted to the exercise
    @judgement_statistics = @entity.report_comment_statistics

    # no assocs for altering
    @entity_ref = @entity.to_entity_ref(:no_assocs)
  end
  
  def setting_global_assert_time_with_academic_season
    @academic_year   = get_academic_year   @background_params[:academic_year]
    @academic_season = get_academic_season @background_params[:academic_season]
    @background_params.merge! :academic_year => @academic_year, :academic_season => @academic_season
    set_assert_time_as_end_of_academic_season_range(@academic_year, @academic_season)
  end
  
  def set_academic_season_cond(table_name, attr_name = :since)
    @academic_year   = get_academic_year   @background_params[:academic_year]
    @academic_season = get_academic_season @background_params[:academic_season]
    academic_season_time_range = Run.academic_season_time_range(@academic_year, @academic_season)
    return "#{table_name}.#{attr_name} BETWEEN '#{academic_season_time_range.begin}' AND '#{academic_season_time_range.end}'"
  end
  
  # conditions for displaying only related lecture exercises
  def related_cond
    @all_or_related == "all" ? nil : "user.run_id = #{@current_user.run_id}"
  end
    
  def prepare_for_new
    @exercise = @entity = Exercise.new_run(:lecture_run_id => @background_params[:lecture].to_i,
                                 :is_open => false,
                                 :limit   => @show_time + 14.days)
    preparation_for_altering
  end
  
  def prepare_for_updating
    @exercise = @entity = find_by_entity_ref
    preparation_for_altering
  end
  
  def preparation_for_altering
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items    
  end

end