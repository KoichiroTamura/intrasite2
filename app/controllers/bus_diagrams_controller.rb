=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# show school bus diagram(スクールバス時刻表)

class BusDiagramsController < RunsController

  skip_before_filter :login_required, :only   => [:index, :search]
  before_filter      :admin_only,     :except => [:index, :search]

  # interprete wday of Ruby to name in Model
  Day_Type_Db = BusDiagram::Day_Type_Db
  
  Departure_Options = BusDiagram::Departure_Options
  
  Def_Items = item_struct "BusDiagram", [:id,        "",       ".id"], [:run_id, "", ".run_id"],
                           [:diagram_type, "ダイヤタイプ", ".diagram_type"],
                           [:day_type, "日タイプ", ".holiday"],
                           [:station, "出発地", ".station"],
                           [:hour, "時", ".hour"],
                           [:min, "分", ".min"],
                           *(Base_Def_History_Items + Base_Def_Altering_Items)
                           
  List_Items = [:diagram_type, :day_type, :station, :hour, :min, :since, :till] + Base_Altering_Items

  History_Items = List_Items + Base_History_Items
              
  Def_Form_Items = form_item_struct Def_Items,
              [:diagram_type, nil, nil, [:required => true]],
              [:day_type, :holiday, nil, [:required => true]],
              [:station, nil, :select, [Departure_Options]],
              [:hour, nil, nil, [:required => true,:size => 3]],
              [:min, nil, nil, [:required => true,:size => 50]],
              Def_Since_Form_Item
  
  def index
    catch :flash_now do 
      find_collection 
    end
    if @mobile
      render :partial => "bus_diagrams_for_mobile", :layout => "mobiles"
      return false
    end   
  end              
  
  def allow_to_add_new_entity?(opts = {})
    admin? && @display_mode
  end
  
 protected
 
  def find_collection(input_params = params)
    @background_params = input_params.symbolize_keys
    
    @display_mode  = @background_params[:display_mode]

    @mobile = @background_params[:mobile] == "true"
    # set special template for mobile
    @response_template = @mobile ? "bus_diagrams_for_mobile" : nil
  
    if @display_mode.blank?
      applied_time = time_from_date_params(@background_params[:date])
      @bus_departure_time = applied_time
      @background_params[:bus_departure_time] = @bus_departure_time 
      @station  = @background_params[:station]   
      @departure_options = Departure_Options
      @collection_options = {:preamble => "preamble"}  
      
      day_type = Day_Type_Db[applied_time.wday] 
      flash_now day_type == "日曜日", "日曜日のため運休です．"
      
      bus_schedule = BusSchedule.find(:first,
                         :assert_time => applied_time,
                         :scope => ":self", 
                         :select => "diagram")
      flash_now !bus_schedule, "ダイヤは未定です．"
      
      diagram_type = bus_schedule.diagram
      flash_now diagram_type == "別途", "ダイヤは別途掲示します．"
      flash_now diagram_type == "運休", "祝日等のため，運休です．"
    
      @collection  = BusDiagram.find :all, 
        :assert_time => applied_time,
        :page        => current_page,
        :scope       => ":self",
        :select      => "hour, min",
        :order       => "hour",
        :conditions  => {:station => @station, :holiday => day_type, :diagram_type => diagram_type}
      unless @collection.blank?
        message =  "「#{day_type}　#{diagram_type}」 ダイヤです．"
        diagram_type == "講義" and message += "（登下校時には利用者が集中するため、ダイヤ通り運行できない場合があります）"
        flash_now true, message
      else
        flash_now true, "データがありません．"
      end
    elsif @display_mode == "for_admin"
      @bus_departure_time = params[:bus_departure_time]
      @background_params[:bus_departure_time] = @bus_departure_time 
      list
    end  
  end
  
  # render list for data maintenance by admin
  def list
    @def_items = Def_Items
    @list_items = List_Items
    @menu_name = "スクールバス：ダイヤグラム表"
    @collection_options = {:collection_template => "list", :entity_template => "list_entity"}
    @collection = BusDiagram.find :all, 
                                  :page  => current_page,
                                  :scope => :self, 
                                  :assert_time => @bus_departure_time,
                                  :select => select_items(@def_items, @list_items + [:id, :run_id]),
                                  :order  => "diagram_type, holiday, station, hour"
  end
  
  def find_history
    @def_items  = Def_Items
    @list_items = History_Items
    @collection = @entity.history :distinct => select_items
    @view_allowed = [:no_detail_call]
  end
  
  def prepare_for_new
    @entity = BusDiagram.new_run
    @def_form_items = Def_Form_Items
  end
  
  def prepare_for_updating
    @def_form_items = Def_Form_Items
  end
  
end
