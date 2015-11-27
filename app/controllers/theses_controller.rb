=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# in old intrasite, 「卒論・修論要旨」
class ThesesController < RunsController
  
  skip_before_filter :login_required, :only => [:index, :search, :show, :set_academic_year, :update_tree_select]
  skip_before_filter :owner_only
#  before_filter :owners_and_teachers_only, :only => [:updating, :destroying]
  
  Header_Local_Info = ["論文作成の学生はここにその要旨を入力します．"]
  
  Bachelor_Degree_Aff    = "全員|中京大学|学部|"
  Master_Degree_Aff      = "全員|中京大学|大学院|"
  Doctor_Degree_Aff      = "全員|中京大学|大学院|"
  
  Bachelor_Degree_Status = "ステータス|学部生|"
  Master_Degree_Status   = "ステータス|院生|修士課程|"
  Doctor_Degree_Status   = "ステータス|院生|博士課程|"
    
  # exclude from list of selection for affiliations which have no lecture courses
  Out_Of_Selection = %w{学外 事務局本部 人工知能高等研究所 事務室 スタッフ}
  
  Def_Items = item_struct( "Thesis", [:id, "", ".id"], [:run_id, "", ".run_id"],
                  [:seminar_name, "指導教員名（ゼミ名）", ".teacher"],
                  [:title, "題目", ".title"],
                  [:authors, "著者", :authors, [:render_entities, :name_and_code]],
                  [:author_members, "著者", :author_members],   # for input only
                  [:academic_year, "年度", ".academic_year"],
                  [:presentation_code, "発表グループID",  ".presentation_code"], 
                  [:presentation_number, "通し番号", ".presentation_number"],
                  [:abstract, "要旨", ".abstract"],
                  [:start_time, "開始時刻", ".start_time", :render_time_without_date],
                  [:end_time,   "終了時刻", ".end_time",   :render_time_without_date],
                  [:presentation_run_id, "", "presentation.run_id"],
                  [:presentation_date,"発表日", "presentation.date"],
                  [:presentation_time, "開始時刻", "presentation.start_time"],
                  [:presentation_place, "場所", "presentation.place"],
                  [:author_real_name, "著者名", "author.real_name"],
                  [:author_student_code, "著者学籍番号", "author.name"],
                  [:attached_files, "添付ファイル", :attached_files],
                  [:created_by, "記入者", ".created_by", :user_info_detail_by_run_id],
                  *(Base_Def_History_Items + Base_Def_Altering_Items)
                  )
                  
  List_Items1  =  [:authors, :seminar_name, :title, :academic_year]
  List_Items2  =  [:presentation_code, :presentation_number, :start_time, :end_time]
  
  Detail_Items =  [:abstract]

  Queries      =  [:seminar_name, :author_real_name, :author_student_code, :title, :abstract]
  
  Reference_To_Guide = ["参照：", [:render, {:partial => "/theses/link_to_thesis_introduction"}]]
  
  Def_Form_Items = form_item_struct Def_Items,  
                  [:seminar_name, :teacher, nil, [:required => true, :local_info => Reference_To_Guide]],
                  [:title, nil, nil, [:required => true]],
                  [:presentation_code, nil, nil, [:required => true, :local_info => Reference_To_Guide]], 
                  [:presentation_number, nil, nil, [:local_info => Reference_To_Guide]],
                  [:abstract, nil, :text_area, [:required => true]],
                  [:start_time, nil, :time_select, [:include_blank => true, :local_info => "ゼミ担当教員が記入します．"]],
                  [:end_time,   nil, :time_select, [:include_blank => true, :local_info => "ゼミ担当教員が記入します．"]],
                  [:author_members, :author_members, :render_association_to_put, [:legend => "論文著者", :collection_name => "members"]],
                  [:attached_files, nil, :render_association_to_put, [:legend => "添付ファイル", :entity_template => "attached_files/input/collection"]],
                  Def_Since_Form_Item
                  
  Form_Items    = [:author_members, :seminar_name, :title, :presentation_code, :presentation_number, :abstract, :start_time, :end_time, :attached_files]
  
    
  def allow_to_add_new_entity?(options = {})
    student?
  end
  
  # override
  def commit_allowed?(thesis, user = @current_user)
    admin_or_owner_of? || teacher? || thesis.author_member?(user)
  end
  
  def allow_to_update?(thesis, user = @current_user)
    admin_or_owner_of? || teacher? || thesis.author_member?(user)
  end
  
  def allow_to_delete?(thesis, user = @current_user)
    admin_or_owner_of? || thesis.author_member?(user)
  end
  
  def search
    catch(:flash_now) do find_collection end
    render :update do |page|
      page[:link_to_thesis_introduction].reload
      page.replace "collection", :partial => "shared/collection",
                                 :locals => {:table_header => "shared/head_item"}
    end
  end
  
  def set_academic_year
    receive_and_set_background_params
    @background_params.merge! :academic_year => params[:academic_year]
    arrange_environment_from_background
    render :update do |page|
      page[:tree_selection].reload
    end
  end
  
    
  # show detail below entity row.
  def show   
    catch :flash_now do find_detail end
    div_id = params[:div_id]
    render :update do |page|
      page[div_id].replace_html  :partial => "detail"
    end
  end
  
  def before_put
    content = @entity_ref.content
    if @put_method == :create
      content.merge!(:till => Run.get_academic_year_range_for_time.end)  # limit valid span of thesis
    end
  end

  def after_put
     attached_files_connection(@entity)
  end

  private
  
  def find_collection 
    arrange_environment_from_background
    
    @header_local_info = [@thesis_status + "要旨の一覧を表示します．"] + Header_Local_Info
    
    @collection = @degree_status.to_model .find :all, 
       :local_assert_time => {:theses => :show_time},
       :page => current_page,
       :scope => thesis_a_net(),
       :distinct => select_items(),
       :order => "theses.presentation_code, theses.presentation_number",
       :conditions => @cond,
       :group      => "theses.id"
       
    flash_now @collection.blank?, "該当する論文はありません．"

    @entity_template = "shared/entity_with_toggled_detail_call"
  end
  
  def arrange_environment_from_background 
    @def_items  = Def_Items
    @list_items = List_Items1
    registered? and @list_items += List_Items2
    
    # refine params value
    [:presentation_code, :presentation_number].each do |p|
      @background_params[p] and @background_params[p].gsub!(/\s/, "")
    end

    # if not logged in, regard user as guest temporally.
    @current_account or Run.current_account = Account.guest_account

    
    @thesis_status = @background_params[:thesis_status] || "卒業論文"
    @degree_status, default_affiliation_fullname = thesis_status_to_degree_status(@thesis_status)

    @academic_year = get_academic_year(@background_params[:academic_year])
    set_assert_time_as_end_of_academic_season_range
    
    # run_id of thesis_presentation_schedule entity
    presentation_run_id = @background_params[:presentation_entity]
    unless presentation_run_id.blank?
       @presentation_entity = ThesisPresentationSchedule.find( :first, :scope => :self, 
                                                           :conditions => "thesis_presentation_schedules.run_id = #{presentation_run_id}")
       @presentation_code = @presentation_entity.presentation_code
    end
    
    @out_of_selection = Out_Of_Selection
    @aff_root = Affiliation.find :first,
                             :scope => ":self",
                             :conditions => "fullname = '#{default_affiliation_fullname}'"
                             
        
    # for query_cond() and query bar
    @queries = Queries
    @query_params = @background_params[:query] || {}
    
    # selected node id for author's affiliation
    affiliation_id = @background_params[:affiliation]
    @affiliation = affiliation_id.blank? ? Affiliation.tree_root : Run.find_entity(affiliation_id) 
      
    affiliation_cond = ["author_aff.fullname LIKE :affiliation", {:affiliation => "#{@affiliation.fullname}%"}]

    admin? || student? and @view_allowed = [:adding_new_call]  
    @cond = merge_conditions(query_cond(), academic_year_cond(),  presentation_code_cond(), affiliation_cond)
  end
  
  def find_detail
    @def_items    = Def_Items
    @detail_items = Detail_Items
    admin? and @detail_items += [:created_by]
    registered?         and @detail_items += [:attached_files]
    allow_to_update?(@entity)  and @detail_items += [:updating]
    allow_to_delete?(@entity)  and @detail_items += [:deleting]
  end
  
  def thesis_a_net()
    ":self [(*memberable << :ThesisMember::Author >> author:UserInfo  #{organization_net('author_org', 'author_aff', 'author_sta')})
            ( .presentation_run_id ~>> presentation:ThesisPresentationSchedule) ]"
  end
  
  def academic_year_cond()
    ["theses.academic_year = :academic_year", {:academic_year => @academic_year}]
  end
  
  # when called from thesis_presentation_schedules
  def presentation_code_cond()
    @presentation_code.blank? and return nil # true as condition for SQL
    ["theses.presentation_code = :code", {:code => @presentation_code}]
  end
  
  # altering 
      
  # creating                   
  def prepare_for_new()
    @academic_year = @background_params[:academic_year]
    default_time = @show_time.beginning_of_day
    thesis_status = @background_params[:thesis_status] || "卒業論文"
    @degree_status, default_affiliation_fullname = thesis_status_to_degree_status(thesis_status)
    @thesis = @entity = @degree_status.to_model.new_run(:start_time => default_time, :end_time => default_time)
    # one of authors is the creater(current_user) of this thesis if he/she is a student.
    @thesis.author_members.build  current_user_member_attributes("ThesisMember::Author")
    preparation_for_altering
  end
  
  def prepare_for_updating
    @thesis = @entity = find_by_entity_ref
    preparation_for_altering
  end
  
  def preparation_for_altering
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
  end
  
  def prepare_for_destroying
    @def_form_items = Def_Form_Items
    @form_items     = Form_Deleting_Items    
  end
    
  def find_history
    @def_items = Def_Items
    @list_items = List_Items1
    registered? and @list_items += List_Items2
    @collection = @entity.history :scope => thesis_a_net, :distinct => select_items
    @entity_template = "shared/entity_with_toggled_detail_call"
  end
 
  def thesis_status_to_degree_status(thesis_status)
     case thesis_status
        when "卒業論文"
          ["BachelorThesis", Bachelor_Degree_Aff]
        when "修士論文"
          ["MasterThesis", Master_Degree_Aff]
        when "博士論文"
          ["DoctorThesis", Doctor_Degree_Aff]
     end  
  end

end