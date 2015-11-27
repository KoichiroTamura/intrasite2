=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# in old intrasite, 「論文発表会」
class ThesisPresentationSchedulesController < RunsController
  
  before_filter :admin_only, :except => [:index, :search]
  
  skip_before_filter :login_required, :only => [:index, :search]
  
  Header_Local_Info = ["発表会で発表される論文要旨一覧に飛ぶことが出来ます．"]

  Def_Items = item_struct( "ThesisPresentationSchedule", [:id, "", ".id"], [:run_id, "", ".run_id"],
                  [:thesis_degree, "学位種別", ".thesis_degree"],
                  [:presentation, "発表種別", ".presentation"],                 
                  [:presentation_code, "発表コード", ".presentation_code"],
                  [:date, "発表年月日", ".date"],
                  [:start_time, "開始時間", ".start_time", :render_time_without_date],
                  [:place, "場所", ".place"],
                  [:academic_year, "年度", ".academic_year"],
                  [:link_to_theses, "", :self, :link_to_thesis_presentation],
                  *(Base_Def_History_Items + Base_Def_Altering_Items)
                  )
                  
  List_Items   =  [:presentation, :presentation_code, :date, :start_time, :place, :link_to_theses]            

  History_Items = [:academic_year] + Base_History_Items + Base_Altering_Items
              
  Def_Form_Items = form_item_struct Def_Items,
              [:thesis_degree],
              [:presentation],
              [:date, nil, :date_select_jp, [:include_blank => true]],
              [:start_time, nil, nil, [:size => 6]],
              [:place],
              [:presentation_code],
              [:academic_year, nil, nil, [:size => 5] ],
              Def_Since_Form_Item
              
  Form_Items = [:since, :thesis_degree, :academic_year, :presentation, :presentation_code, :date, :start_time, :place]
              
  def allow_to_add_new_entity?(options = {})
    admin?
  end
  
 protected
  
  def find_collection   
    @academic_year = get_academic_year
    @background_params[:academic_year] = @academic_year
    @thesis_status = params[:thesis_status] || "卒業論文"
    @background_params [:thesis_status] = @thesis_status
    model_name = model_name_from_thesis_status(@thesis_status)
    @background_params[:model_name] = model_name
    
    @header_local_info = [@thesis_status + "発表会のスケジュールを表示します．"] 
    admin? and @header_local_info << "管理者はここでスケジュールの新規，更新，削除が出来ます．"
    @header_local_info += Header_Local_Info
      
    @def_items = Def_Items
    @list_items = List_Items
    admin? and @list_items += Base_Altering_Items
    
    @collection = model_name.to_model.find :all,
       :scope => ":self",
       :assert_time => end_of_academic_year,
       :conditions => {:academic_year => @academic_year},
       :order => "thesis_presentation_schedules.presentation, thesis_presentation_schedules.date"
       
    flash_now @collection.blank?, "該当する発表スケジュールはありません．"
  end
  
  
  def find_history
    @def_items = Def_Items
    @list_items = History_Items
    @collection = @entity.history :scope => :self, :distinct => select_items
  end
  
  # --- altering ---
    
  def prepare_for_new
    prepare_for_altering
    @academic_year = @background_params[:academic_year]
    model = model_name_from_thesis_status(@thesis_status).to_model
    @entity = model.new_run(:thesis_degree => @thesis_status, :academic_year => @academic_year, :start_time => "10:00")
  end
  
  def prepare_for_updating
    prepare_for_altering
  end
  
  def prepare_for_altering
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
    @thesis_status = @background_params[:thesis_status] || "卒業論文"
  end

  def model_name_from_thesis_status(thesis_status)
    case thesis_status
      when "卒業論文"
        "BachelorThesisSchedule"
      when "修士論文"
        "MasterThesisSchedule"
      when "博士論文"
        "DoctorThesisSchedule"
    end   
  end
end