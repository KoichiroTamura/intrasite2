=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# show schedules of school bus diagram
# for admin only
class BusSchedulesController < RunsController
  before_filter      :admin_only,     :only => [:list, :create_lecture_day]

  Is_Holiday = BusSchedule::Is_Holiday
  
  Def_Items = item_struct "BusSchedule", [:id,        "",       ".id"], [:run_id, "", ".run_id"],
                           [:schedule_name, "スケジュール名", ".schedule"],
                           [:diagram_type, "ダイヤタイプ", ".diagram"],
                           [:is_holiday, "休日？", ".holiday"],
                           [:year, "年度", ".year"],
                           *(Base_Def_History_Items + Base_Def_Altering_Items)
                           
  List_Items = [:since,:till, :schedule_name,:diagram_type, :is_holiday] + Base_Altering_Items

  History_Items = List_Items
              
  Def_Form_Items = form_item_struct Def_Items,             
              Def_Since_Form_Item,
              Def_Till_Form_Item,
              [:schedule_name, :schedule, nil, [:required => true]],
              [:diagram_type, :diagram, nil , [:required => true]],
              [:is_holiday, :holiday, :select, [BusSchedule::Is_Holiday]]
              
  Form_Items = [:since, :till, :schedule_name, :diagram_type, :is_holiday]
  
  Def_Lecture_Days_Form_Items = form_item_struct Def_Items,
              Def_Since_Form_Item,
              Def_Till_Form_Item
              
  def allow_to_add_new_entity?(opts = {})
    admin? 
  end

  # create dummy schedule articles that show lecture days
  # params are base_since and base_till for virtual bus_schedule
  def create_lecture_days
    receiver = BusSchedule.new(params["bus_schedule"]) 
    list_of_lecture_day_schedules = BusSchedule.find :all,
                                            :scope => :self, 
                                            :assert_time => (receiver.since..receiver.till),
                                            :select => "since, till",
                                            :conditions => "holiday = 'on'"
    n_of_dates = 0                                         
    list_of_lecture_day_schedules.each do |sch|
      start_date, end_date = sch.since, sch.till
      while start_date < end_date do 
        Article.create_lecture_day_article(start_date)
        n_of_dates += 1
        start_date += 1.day
      end
    end
    
    render :update do |page|
      page.replace_html "set_lecture_days", (n_of_dates > 0 ? "#{n_of_dates}日分の授業日を設定しました．" : "授業日はありませんでした．")
    end
  end
   
 protected
 
  def find_collection
    @bus_departure_time = params[:bus_departure_time]
    academic_year = Run.get_academic_year(@bus_departure_time.to_datetime)
    @def_items = Def_Items
    @list_items = List_Items
    @menu_name  = "スクールバス：運行スケジュール表"
    
    @collection = BusSchedule.find :all, 
                                   :page  => current_page,
                                   :scope => :self, 
                                   :assert_time => academic_season_time_range(academic_year), 
                                   :select => select_items(@def_items, @list_items + [:id, :run_id]),
                                   :order => "since"
                                   
    # for setting lecture days format
    @lecture_day_entity = BusSchedule.new_run(:since => @show_time.beginning_of_day, :till => @show_time.end_of_day)
    @def_lecture_day_form_items = Def_Lecture_Days_Form_Items
    @lecture_day_form_items     = [:since, :till]
    @default_since = @show_time.beginning_of_day
    @default_till = @show_time.end_of_day
  end
  
  def find_history
    @def_items  = Def_Items
    @list_items = History_Items
    @collection = @entity.history :distinct => select_items
    @view_allowed = [:no_detail_call]
  end
  
  def prepare_for_new
    @entity = BusSchedule.new_run(:since => @show_time.beginning_of_day, :till => @show_time.end_of_day)
    prepare_for_updating
  end
  
  def prepare_for_updating
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
    @default_since = @entity.since.beginning_of_day
    @default_till  = @entity.till.end_of_day
  end 
  
  def prepare_for_destroying
    @time_to_delete = @entity.since.beginning_of_day    
  end
end
