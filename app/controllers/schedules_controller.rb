=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


require 'set'

# for schedule tables ("スケジュール" in old intrasite)
class SchedulesController < ArticlesController
  
  skip_before_filter :login_required, :only => [:index, :set_schedule_span, :move_schedule_span, :move_simple_calendar]
  
  Schedule_Header_Local_Info = ["スケジュール情報の交換の場です．",
                                "一般メッセージと同様，記事の宛先（すなわち閲覧者）を個人，グループ，組織で指定できますから，
                                　一般のカレンダと異なり，利用範囲は広大です．",
                                "他人の予定も（許可される範囲で）知ることが出来ます．",
                                "メッセージコーナーで作成した記事に日時を指定すると，このスケジュールコーナーにも載ります．"]
  Space_Schedule_Header_Local_Info = ["会議室やミーティングルームなど，場所使用予定の情報を交換します．",
                                      "場所は，「スペース」の木構造で指定します．"]
  
  # :schedule_span parameters
  MONTH = "月（通常形式）"
  WEEK  = "週"
  DAY   = "日"
  MONTH2=  "月（今週から）"
  Default_Span = MONTH
  
  Holiday = "祝日"
  
  # for schedules
  Article_Schedule_Item = 
    {:id             => "articles.id",
     :run_id         => "articles.run_id",
     :banner_run_id  => "articles.banner_run_id",
     :start_datetime =>  "articles.start_datetime",
     :end_datetime   =>  "articles.end_datetime",
     :title          =>  "articles.title",
     :thread_id      =>  "thread.id",
     :created_by     =>  "articles.created_by",
     :article_class  =>  "article_class",
     :schedule_class => "articles.schedule_class"}
                          

  # for finding lectures current_user attends.
  Articles_AS_Lecture_Schedule = 
     ":Article     [(.schedule_class = '授業日' ) 
                    (.schedule_day_of_week = .day_of_week)
                    (.season in .season) ]
      :LectureTime  >> 
      :Lecture     [( >> :Course)
                    (*memberable << :Member)]"

  Lecture_Schedule_Item = 
    {:id           => "articles.id",
     :date         => "articles.start_date",
     :lecture_time => "lecture_times.lecture_time",
     :campus       => "lecture_times.campus",
     :lecture_id   => "lectures.id",
     :title        => "courses.name"}
  
  def index
    @mobile = params[:mobile] == "true"
    catch :flash_now do 
      find_collection 
    end
    if @mobile
      render :partial => "day_calendar_for_mobile", :layout => "mobiles"
      return false
    end   
  end
  
  def show
    # call ArticlesControler#find_detail
    # this will get its thread detail.
    catch :flash_now do find_detail end
    # render thread detail which includes the schedule article.
    render :update do |page|
      page.replace_html "working_div", :partial => "article_threads/detail"
      page.insert_html :top, "working_div" , :partial => "shared/flash_notice"
      page.insert_html :bottom, "working_div" , :partial => "back_to_calendar"
    end      
  end

  # new is for schedule not article.
  #  the controller should be different through the sequence of this action.
  def new
    catch :flash_now do prepare_for_new end
    render :update do |page|
      page.replace_html "working_div", :partial => "shared/committing_template", :locals => {:content_template => "article_threads/new"}
      page.insert_html :bottom, "working_div" , :partial => "back_to_calendar", :locals => {:text => "キャンセル"}
    end
  end

  
  # move to previous or next schedule_span(MONH, WEEK or DAY)
  # move_direction param is either "+" (next) or "-" (previous) or "0" (today)
  def move_schedule_span
    move_direction = params[:move_direction]
    receive_and_set_background_params

    if move_direction == "0"
      target_date = @show_time
    else     
      original_display_time = @background_params[:date].to_datetime(:local)
      move_span = 
        case @background_params[:schedule_span]
          when MONTH, MONTH2
            1.month
          when WEEK
            1.week
          when DAY
            1.day
      end
      target_date = original_display_time.send(move_direction, move_span)
    end
    
    @background_params.merge! :date => target_date.to_s(:db) 

    list_again
  end
  
  # move to previous or next simple calendar
  def move_simple_calendar
    template       = "schedules/simple_calendar"
    div_id         = "simple_calendar"
    move_direction = params[:move_direction]
    
    if move_direction == "0"
      display_time = @show_time
    else     
      original_display_time = params[:display_time].to_datetime(:local)
      display_time = original_display_time.send(move_direction, 1.month)    
    end
    render :update do |page|
      page.replace div_id , :partial => template, :locals => {:display_time => display_time}
    end   
  end
  
  def set_schedule_span
    @schedule_span = params[:schedule_span]
    receive_and_set_background_params
    @background_params.merge! :schedule_span => @schedule_span
    list_again
  end

  protected
  
  # display schdules for month, week, or day of given show_time
  # "dispaly_mode" is "schedules" or "space schedules".
  # MONTH, WEEK, or DAY for input_params[:schedule_span]
  # @schedules is an array of each day with articles including lectures attended by receiver.
  def find_collection(input_params = params)
    @background_params = input_params.symbolize_keys
    
    @display_mode = input_params[:display_mode] || "schedules"
    @background_params.merge! :display_mode => @display_mode
    
    if @display_mode == "space_schedules"
      @background_params.merge! :space_span => input_params[:space_span] || Space::Default
    end
  
    @mobile = input_params[:mobile] == "true"
    @background_params.merge! :mobile => @mobile

    @header_local_info = case @display_mode
      when "schedules"       then Schedule_Header_Local_Info
      when "space_schedules" then Space_Schedule_Header_Local_Info
    end
    
    # if not logged in, regard user as guest temporally.
    if @current_account.blank?
      Run.current_account = Account.guest_account
      @current_user = Run.current_user
    end

    
    @academic_year   = input_params[:academic_year]
    @academic_season = input_params[:academic_season]
    date             = input_params[:date]
    @display_time    = date.nil? ? nil : date.to_datetime(:local)

    # when called by "move_calendar", @display_time is given
    # when called as lecture schedule, @academic_year && @academic_season are given.
    @display_time ||= (@academic_year && @academic_season ? 
                        [@show_time, end_of_academic_season(@academic_year, @academic_season)].min :
                         @show_time)
    @background_params.merge! :date => @display_time.to_s(:db)

    @forum = input_params[:forum] 
    
    @schedule_span   = input_params[:schedule_span].blank? ? Default_Span  : input_params[:schedule_span]
    @background_params.merge! :schedule_span => @schedule_span
    
    @article_class   = input_params[:article_class] 
    @receive_mode    = input_params[:receive_mode]  
    @other_user_name = input_params[:other_user_name]

    # item structs of whole items
    @def_items = Def_Thread_Items 

    # items for query bar
    @queries = [:sender_name_to_query, :title, :content_to_query]
    
    # time range(in :db format) to display
    @dates = date_span(@display_time, @schedule_span)
    
    # query for other user's schedule
    if @other_user_name.blank?
      @other_user = nil
    else
      @other_user = UserInfo.find :first, :assert_time => (@dates.begin.to_datetime..@dates.end.to_datetime),
                                  :select => "id, run_id",
                                  :scope => ":self",
                                  :conditions => {:name => @other_user_name}
      # forcing receive_mode as EXTENDED
      @receive_mode = EXTENDED
    end
    
    # SQL conditions for articles whose schedule dates are overlapped with display span(db format)
    date_cond = Run.intersect_in_db_ranges?( "articles.start_date".."articles.end_date",  "'#{@dates.begin}'".."'#{@dates.end}'")
    
    # array of arrays each of which has one day schedules(article objects) through the @schedule_span.
    datetime_span = [@dates.first.to_datetime, @dates.last.to_datetime]
    total_schedules = article_schedule(date_cond) + lecture_schedule(date_cond, datetime_span)
    schedules = partition_schedules_per_day(total_schedules.sort_by(&:start_datetime), datetime_span)
    @schedules =    
      case @schedule_span
        when MONTH
         month_arrange(schedules)
        when WEEK
         schedules
        when DAY
         schedules
        when MONTH2
         month_arrange(schedules)
       end
    @calendar_template = 
      case @schedule_span
        when MONTH, MONTH2
          "month_calendar"
        when WEEK
          "week_calendar"
        when DAY
          "day_calendar"
      end
    # set special template for collection with @calendar_template or template for mobile
    @response_template = @mobile ? "/schedules/day_calendar_for_mobile" : "/schedules/collection"
  end
  
  # special version for schedules to display new calender.
  def list_again(options = {})
    catch :flash_now do find_collection(@background_params) end
    div_id       = options[:div_id]     || "collection"
    template     = options.delete(:collection_template) || @response_template || "shared/collection"
    render :update do |page|
      page.replace div_id , :partial => template, :locals => options
    end 
  end
  
  def find_detail
    a_thread = find_entity.a_thread
    find_detail_of_thread(a_thread)
  end
  
  # time range given in :db format
  def date_span(now, span = MONTH)
    date_pair = 
      case span
        when MONTH
          [now.beginning_of_month.since(-86400*now.beginning_of_month.wday).beginning_of_day, now.end_of_month.since(86400*(6-now.end_of_month.wday)).end_of_day]
        when WEEK
          [now.since(-86400*now.wday).beginning_of_day, now.since(86400*(6 - now.wday)).end_of_day]
        when DAY
          [now.beginning_of_day, now.end_of_day]
        when MONTH2
          [now.since(-86400*now.wday).beginning_of_day, now.since(86400*4*7).since(86400*(6-now.since(86400*4*7).wday)).end_of_day]
      end 
    result = date_pair.map do |d| d.to_date.to_s(:db) end
    result.first..result.last
  end
  
  # find article schedule during dates(range, db_format)
  def article_schedule(date_cond)
    # current_user's schedules
    schedule_ids = schedule_ids_during(date_cond, @current_user)
    
    unless @other_user.blank?
      other_schedule_ids = schedule_ids_during(date_cond, @other_user)
      schedule_ids = (schedule_ids.to_set & other_schedule_ids.to_set).to_a
    end
#    return [] if schedule_ids.blank?
    schedule_ids.blank? and return [] 
    
    Article.find schedule_ids,
                        :select => Article_Schedule_Item,
                        :scope  => ":self >> thread:ArticleThread",
                        :conditions=> forum_cond,
                        :group => "articles.id"
  end
  
  # find schedule_ids during the dates(range, db format) for user
  def schedule_ids_during(date_cond, user = @current_user)
    # regarding space schedule condition
    a_net = [] << Basic_A_Net
    
    if @display_mode == "space_schedules"
      @space_span = @background_params[:space_span] || Space::Default
      a_net << ":Article .place_run_id >> space:Space .fullname contained_by '#{@space_span}'"
      space_cond = nil
      # when space schedule required,  receive_mode is forced to be extended
      @receive_mode = EXTENDED
      @background_params.merge! :space_span => @space_span, :receive_mode => @receive_mode
    end
   
    ArticleThread.find :all, 
                 :scope      => a_net << personal_setting,  
                 :local_assert_time => local_assert_time_for_destination("articles.start_date"),
                 :select     => "articles.id",
                 :conditions => merge_conditions(date_cond, space_cond, forum_cond, *basic_cond(user)),
                 :group      => "articles.id"
  end

  def lecture_schedule(date_cond, datetime_span)
    
    # for the moment
#    return [] if @display_mode == "space_schedules"
    @display_mode == "space_schedules" and return []
    
    user = @other_user ||  @current_user    
    
    # lecture schedules for teacher, student, or ta
    schedules = Article.find :all,
                  :scope       => Articles_AS_Lecture_Schedule,
                  :local_assert_time => local_assert_time_for_lecture(Run.get_academic_season_range_for_time(@display_time)),
                  :select      => Lecture_Schedule_Item,
                  :conditions  => merge_conditions(date_cond, member_user_cond(user), forum_schedule_cond),
                  :group       => "articles.start_date, lecture_times.lecture_time"
    
    schedules.each do |a|
      campus = a.campus.blank? ? nil : a.campus
      real_time = LectureTimeToRealTime.real_time(a.lecture_time.to_i, campus)
      a.start_datetime = a.date + " " + real_time.first
      a.end_datetime   = a.date + " " + real_time.last 
      a.title          = "［#{a.lecture_time}限］#{a.title}"  # title with lecture time
    end   
  end
  
  def local_assert_time_for_lecture(time)
    {:lecture_times => time, 
     :lectures => time, 
     :courses => time, 
     :members => time}
  end
  
  def member_user_cond(user = @current_user)
    "members.user_info_run_id = #{user.run_id}"
  end
    
  def forum_schedule_cond
    @forum.blank? and return "TRUE"
    forum_id, forum_model = @forum.to_id_and_model
    "#{forum_model.table_name}.run_id=#{forum_id}"
  end

  def space_tree(parent)
    Space.find_descendants(parent)
  end
  
  # partition schdules to each day schedules by its datetime(datetime format)
  # schedules are supposed to be already sorted by start_datetime.
  # result is array of arrays each of which is [date, [schedules of the date]]
  def partition_schedules_per_day(schedules, datetime_span)
    date = datetime_span.first.to_date
    end_date = datetime_span.last.to_date
    result = []
    while date <= end_date do 
      day_sch = schedules.select do |sch| sch.start_datetime.to_date == date end
#      day_sch = [] if day_sch.nil?
      day_sch.nil? and day_sch = []
      result << [date, day_sch]
      schedules = schedules[day_sch.length..-1]
      date += 1.day
    end
    result
  end
  
  def month_arrange(schedules, result = [])
    schedules.blank?  and  return result
    top_week = schedules[0,7]
    month_arrange(schedules[7..-1], result << top_week)
  end
  
  # -- Altering --
  
end