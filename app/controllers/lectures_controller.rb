=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# lecture controller
# lecture corrensponds to "syllabuso02" in old version.

class LecturesController < CoursesController
  
  skip_before_filter :login_required, :only => [:index, :search, :show]
  
  Def_Items = Def_Items.merge( item_struct("Lecture", [:id, "", ".id"], [:run_id, "", ".run_id"] ) )
  
  Lecture_Items = [:lecture_member__teachers, :lecture_member__t_as, :lecture_times, :syllabus]
  
  Lecture_Times_Items = [:season, :day_of_week, :lecture_time, :campus, :room]
  
  # to avoid to call show of CourseController
  def show
    render_response("detail") do find_detail end
  end

  # show detail of lecture as an article in scchedule
  def show_lecture_schedule
    receive_and_set_background_params
    datetime = @background_params[:date].to_datetime(:local)
    academic_year, academic_season = Run.get_academic_year(datetime), Run.get_academic_season(datetime)
    @background_params.merge! :academic_year  => academic_year,
                              :academic_seaon => academic_season
    catch :flash_now do find_detail end
    # render lecture detail on calendar table.
    render :update do |page|
      page.replace_html "working_div", :partial => "lectures/detail"
      page.insert_html :top, "working_div" , :partial => "shared/flash_notice"
      page.insert_html :bottom, "working_div" , :partial => "schedules/back_to_calendar"
    end    
  end
  
  # override
  def owner_of?(entity = @lecture)
    super(entity) || entity.teacher_of?   
  end
  
  protected
  
  def find_detail
    @academic_year   = @background_params[:academic_year]
    @academic_season = @background_params[:academic_season]
    set_assert_time_as_end_of_academic_season_range(@academic_year, @academic_season)

    @lecture                 = find_entity 
    @def_items               = Def_Items
    @lecture_items           = Lecture_Items
    # aff and sta to ignore to express them from fullname
    @aff_and_sta_to_neglect  = Affiliations_To_Neglect + Status_To_Neglect
    @lecture_times_items     = Lecture_Times_Items

    @course                  = @lecture.course
    
    @def_course_class_items  = Def_Course_Class_Items
    @course_class_items      = Course_Class_Items - [:course_group, :course_series]
    @course_classes          = @lecture.course_classes :select => select_items(@def_course_class_items,[:id, :run_id] + @course_class_items),
                                                       :conditions => "courses.run_id = #{@course.run_id}",
                                                       :group  => "course_classes.id"
                                                       
    @students = @lecture.students
    
    @def_syllabus_items      = Def_Syllabus_Items
    @syllabus_render_items   = Syllabus_Render_Items
    @syllabus                = @lecture.syllabus :select => select_items(@def_syllabus_items, [:id, :run_id] + Syllabus_Items )

    @def_syllabus_book_items = Def_Syllabus_Book_Items
    @syllabus_book_items     = Syllabus_Book_Items
    @syllabus_books          = @syllabus.blank? ? nil : 
                                 @syllabus.syllabus_books( :select => select_items(@def_syllabus_book_items, [:id, :run_id] + Syllabus_Book_Items) )
                                 
    @menu_name = "授業詳細"
  end
  
  # creating new lecture as assoc_target of a course
  def prepare_for_adding_assoc_target(lecture, pre_assoc_items)
    @def_lecture_form_items = Def_Lecture_Form_Items
    @lecture_form_items     = Lecture_Form_Items
    @def_lecture_time_form_items = Def_Lecture_Time_Form_Items
    @lecture_time_form_items     = Lecture_Time_Form_Items
    @course = find_entity(pre_assoc_items[-2])
    flash_now @course.blank?, "連結する科目がまだ作られていません．それを作成後，あらためて授業の作成を行ってください．"
    arrange_environment_from_background
    set_assert_time_as_end_of_academic_season_range
    # default since through whole composite entity
    @default_since = beginning_of_academic_season(@academic_year, @academic_season)
    unless @course.blank?
      lecture.build_course(@course)
      @course.since = @root_entity_since
      @course.course_classes.reject(&:new_record?).map do |cc| 
        lecture.lecture_course_classes.build(:course_class_run_id => cc.run_id)
      end
      @course_classes = @course.course_classes
    end
    @default_since = beginning_of_academic_season
    lecture.since = @root_entity_since
    lecture.lecture_member__teachers.build
    lecture.lecture_times.build
  end

end