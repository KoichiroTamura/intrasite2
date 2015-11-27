=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# for course_classes

class CourseClassesController < CoursesController
  
  # to avoid to call show of CourseController
  def show
    render_response("detail") do find_detail end
  end
  
 private
 
 def find_detail
   @academic_year   = @background_params[:academic_year]
   @academic_season = @background_params[:academic_season]
   set_assert_time_as_end_of_academic_season_range(@academic_year, @academic_season)
    
   @def_course_class_items = Def_Course_Class_Items
   @course_class_items     = Course_Class_Items
   @course_class_render_items = Course_Class_Items - Base_History_Items
   @course_class = find_entity :select => select_items(@def_course_class_items, [:id, :run_id] + @course_class_items)
   @menu_name = "対象クラス詳細"
 end
 
 def prepare_for_adding_assoc_target(course_class, pre_assoc_items)
   course_class.organizations.build 
   @def_course_class_form_items = Def_Course_Class_Form_Items
   @course_class_form_items     = Course_Class_Form_Items
   @aff_root = Affiliation.tree_root
   @sta_root = Status.tree_root
 end
end