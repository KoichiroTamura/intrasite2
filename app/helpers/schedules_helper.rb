=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

#  r1684 | 並松  | 2010-01-15  コードの整理
# 
module SchedulesHelper
  # schedules rendering helper
  
  # parameters of popup window to show schedule
  Schedule_Popup_Params = "schedule_detail_page", "width=400, height=500, scrollbars= yes"

  def schedule_span_name(i)
    [SchedulesController::MONTH, SchedulesController::MONTH2, SchedulesController::WEEK, SchedulesController::DAY][i]
  end
  
  def convert_to_calendar_type(schedule_span = @schedule_span)
    case schedule_span
      when SchedulesController::MONTH, SchedulesController::MONTH2
        "month"
      when SchedulesController::WEEK
        "week"
      when SchedulesController::DAY
         "day"
    end
  end
  
  Short_Name_Of_Day_Of_Week = %w{日 月 火 水 木 金 土}
  Long_Name_Of_Day_Of_Week  = Short_Name_Of_Day_Of_Week.map{|w| w + "曜日"}
  
  def day_of_week_name(wday, short_or_long = :short)
    case short_or_long
      when :long
        Long_Name_Of_Day_Of_Week[wday]
      when :short
        Short_Name_Of_Day_Of_Week[wday]
    end
  end
    
  
  # remote call for detail of schedule
  def remote_call_for_schedule_detail(schedule, options = {}, html_options = {})
    options[:params ] = {:display_mode => @display_mode}
    options[:controller] = "schedules"
    if schedule.respond_to?(:lecture_id)    # schdeule article for lecture
      options[:controller] = "lectures"
      options[:action]     = "show_lecture_schedule"
      options[:id]         = "#{schedule.lecture_id}:Lecture"
    end
    remote_call_for_detail  schedule, options
  end
  
  # call for adding new schedule article on date
  def remote_link_for_new_schedule_article(text, date, options = {}, html_options = {})
    options[:controller] = "schedules"
    options[:params]     = {:start_date => date, 
                            :display_mode => "schedules"}    
    remote_link_to_new(text,  options )
  end
  
  def remote_call_for_new_schedule(date, options = {}, html_options = {})
    options[:controller] = "schedules"
    options[:params]     = {:start_date => date, 
                            :display_mode => "schedules"}    
    remote_call_to_new(:ondblclick, options, html_options)
  end
  
  def remote_call_to_set_schedule_span(schedule_span, options = {})
    options[:url] ||= {:controller => "schedules", :action => "set_schedule_span",
                       :params => {:schedule_span => schedule_span, :background_params => @background_params}}
    remote_call_on_event(:onclick, options)
  end
  
  # move schedule span to move_direction; "+" (next) or "-" (previous) or "0" (today)
  def remote_call_to_move_schedule_span(move_direction, options={})
    options[:url] ||= {:controller => "schedules", :action => "move_schedule_span",
                       :params => {:move_direction => move_direction, :background_params => @background_params}}
    remote_call_on_event(:onclick, options)
  end
  
  def remote_call_to_prev_schedule(options = {})
    remote_call_to_move_schedule_span("-", options)
  end
  
  def remote_call_to_next_schedule(options = {})
    remote_call_to_move_schedule_span("+", options)
  end
  
  def remote_call_to_today_schedule(options = {})
     remote_call_to_move_schedule_span("0", options)
  end
  
  # move simple month calendar to move_direction; "+" (next) or "-" (previous) or "0" (today)
  def remote_call_to_move_simple_calendar(move_direction, display_time, options={})
    options[:url] ||= {:controller => "/schedules", :action => "move_simple_calendar",
                       :params => {:move_direction => move_direction, :div_id => @div_id, :display_time => display_time}}
    remote_call_on_event(:onclick, options)
  end
  
  def remote_call_to_prev_month(display_time, options = {})
    remote_call_to_move_simple_calendar("-", display_time, options)
  end
  
  def remote_call_to_next_month(display_time, options = {})
    remote_call_to_move_simple_calendar("+", display_time, options)
  end
  
    
  def remote_call_to_today_month(display_time, options = {})
     remote_call_to_move_simple_calendar("0", display_time, options)
  end


  
  # schedules with over days in date_schedules_pairs
  def banner_schedules(date_schedules_pairs)
    date_schedules_pairs.inject([]) do |result, date_schedules_pair|
      date, schedules = *date_schedules_pair
      schedules.each do |schedule|
        if schedule.attribute_present?(:banner_run_id) && !result.map(&:banner_run_id).include?(schedule.banner_run_id)
          result << schedule
        end
      end
      result
    end
  end
  
  # for weeek and day calendar
  def all_day_long_schedules(date_schedules_pairs, week_or_day = :week)
    date_schedules_pairs.map do |date, schedules|
      result_schedules = schedules.select do |schedule|
        all_day_long?(schedule) && ( week_or_day == :week ? !schedule.attribute_present?(:banner_run_id) : true)
      end
      [date, result_schedules]
    end
  end
  
  def content_element_sizes(date_schedules_pairs)
    date_schedules_pairs.map do |date, schedules|
      schedules.inject(0) do |size, schedule|
        unless schedule.attribute_present?(:banner_run_id)      
          if all_day_long?(schedule) 
            size += 1
          else
            size += 2
          end
        end
        size
      end
    end
  end
    
  
  # color for all_day_long_schedule
  def color_for_article_type(schedule)
    schedule.attribute_present?(:article_class) && schedule.article_class == SchedulesController::Holiday ? "red" : "orange"
  end
  
  def current_day_color(date)
    current_date?(date)  ? "oldlace" : "white"
  end
  
  def current_date?(date)
    [date.year, date.month, date.day] == [@show_time.year, @show_time.month, @show_time.day]
  end
  
  def other_month_date?(display_time, date)
    display_time.month != date.month
  end
  
  def height_of_grid_background(week_schedules)
    number_of_banners = week_schedules.map do |p| banner_schedules(p).size end.max
  end
  
  # end_of_week beginning with Sunday not Monday as Rails version
  def j_end_of_week(datetime)
    time = datetime
    datetime.wday == 0 and time = datetime + 1.day
    time.end_of_week - 1.day
  end
  
  # beginning of_week;  Sunday not Monday as Rails version
  def j_beginning_of_week(datetime)
    time = datetime
    datetime.wday == 0 and time = datetime + 1.day
    time.beginning_of_week - 1.day
  end
  
  # making month calendar html around display_time with @schedules
  # tags are html content_tags like <table   > ...</table>
  # tags
  #   month_tag
  #   week_tag
  #   day_tag
  #   day_cell_tags          # for details in day cell
  #     day_name_tag         # for name of each day
  #     day_wrapping_tag     # for description content of each day
  #     day_item_tag         # for each item of the description
  #   display_time is time(datetime) for displaying schedules
  # @schedules is an array of array of items for each day.can be handled in the attached block.
  def month_calendar_html(display_time, tags = {}, &block)
    # in Rails, the beginning of a week is monday!!
    day_time = j_beginning_of_week(display_time.beginning_of_month)
    last_day_time = j_end_of_week(display_time.end_of_month)
    index = 0
    month_html = ""
    while day_time <= last_day_time do 
     html, day_time, index = week_html(display_time, day_time, index, tags, &block)
     month_html += html
    end
    i_content_tag(tags[:month_tag], month_html)
  end
  
  def week_calendar_html(display_time, tags = {}, &block)
    week_html(display_time, j_beginning_of_week(display_time), 0, tags, &block)
  end
  
  def day_calendar_html(day_desription, day_cell_tags)
    day_html(day_descrition, day_cell_tags)
  end
  
  def week_html(display_time, day_time, index, tags = {}, &block)
    html = ""
    7.times do
      day_schedule = @schedules && @schedules[index] || ""
      day_html     = yield(day_time, day_schedule, tags[:day_cell_tags])
      day_class    = current_date?(day_time) ? tags[:current_date_class] : 
                       other_month_date?(display_time, day_time) ? tags[:other_month_date_class] : "cal-day-default"
      day_tag      = tags[:day_tag] + ' ' + "class = #{day_class}"
      html        += i_content_tag(day_tag, day_html)
      day_time     = day_time.next
      index       += 1
    end
    return i_content_tag( tags[:week_tag], html), day_time, index
  end
  
  # simple calendar
  def simple_month_calendar(display_time, tags = nil)
    tags ||= {:month_tag  => "ul", 
              :week_tag     => "li"}
    month_calendar_html(display_time, tags) do |day_time, day_schedule, day_cell_tags|   
      simple_day_view_for_calendar(display_time, day_time, day_schedule, day_cell_tags)
    end
  end
  
  # day display for calendar
  def simple_day_view_for_calendar(display_time, day_time, day_schedule, day_cell_tags)
    day_html = (day_time.day < 10 ? "&nbsp;&nbsp;" : "") + day_time.day.to_s
    day_html = "&nbsp;&nbsp;" if day_time.month != display_time.month
    day_name = "&nbsp;" + day_html + "&nbsp;"  
    day_link = link_to day_name, schedules_path(:menu_name1=>"コミュニケーション : スケジュール",
                                                :schedule_span => SchedulesController::DAY,
                                                :date => day_time.to_s(:db))
    day_cell_tags ? i_content_tag(day_cell_tags[:day_name_tag], day_link) : day_link
  end
  
  def all_day_long?(schedule)
    schedule or return
    all_day_span?(schedule.start_datetime, schedule.end_datetime)
  end
  
  def all_day_span?(start_datetime, end_datetime)
    (start_datetime.to_s(:db) == start_datetime.beginning_of_day.to_s(:db)) && (end_datetime.to_s(:db) == end_datetime.end_of_day.to_s(:db))
  end
  
  def render_time_of_schedule(schedule)
    start_time, end_time = schedule.start_datetime, schedule.end_datetime
    all_day_long?(schedule)? "" :
         "#{render_time_without_date(start_time)} ~ #{render_time_without_date(end_time)} <br />"    
  end

  def input_today_special_helper(obj_name,param=nil)
    unless param
      return "schd.input_spec_today('#{@show_time.year}/#{@show_time.month}/#{@show_time.day} 00:00:00 UTC+0900');"
    else
      return "schd.input_spec_today('#{params[:date][:year]}/#{params[:date][:month]}/#{params[:date][:day]} 00:00:00 UTC+0900');";
    end
  end

end