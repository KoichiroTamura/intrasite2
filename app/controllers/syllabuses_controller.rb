=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class SyllabusesController < RunsController
  
  Def_Syllabus_Items      = CoursesController::Def_Syllabus_Items
  Syllabus_Items          = CoursesController::Syllabus_Items
  Syllabus_Render_Items   = CoursesController::Syllabus_Render_Items
  Def_Syllabus_Form_Items = CoursesController::Def_Syllabus_Form_Items
  Syllabus_Form_Items     = CoursesController::Syllabus_Form_Items
  Def_Syllabus_Book_Items = CoursesController::Def_Syllabus_Book_Items
  Syllabus_Book_Items     = CoursesController::Syllabus_Book_Items
  Def_Syllabus_Book_Form_Items = CoursesController::Def_Syllabus_Book_Form_Items
  Syllabus_Book_Form_Items     = CoursesController::Syllabus_Book_Form_Items
  
  skip_before_filter :owner_only, :only => [:updating, :update]
  
  def select_options_from_name_and_author
    receive_and_set_background_params
    @academic_year = @background_params.to_h[:academic_year]
    @academic_season = @background_params.to_h[:academic_season]
    self.assert_time = beginning_of_academic_season
    super    
  end

  
  protected
  
  def find_detail
    @def_syllabus_items    = Def_Syllabus_Items
    @syllabus_render_items = Syllabus_Render_Items
    @syllabus   = find_entity :select => select_items(@def_syllabus_items, [:id, :run_id] + Syllabus_Items ) 
    @def_syllabus_book_items = Def_Syllabus_Book_Items
    @syllabus_book_items     = Syllabus_Book_Items
    @academic_year = @background_params.to_h[:academic_year]
    @academic_season = @background_params.to_h[:academic_season]
    @default_since = beginning_of_academic_season
    self.assert_time = @default_since
  end
  
  def find_history
    @def_items  = Def_Syllabus_Items
    @list_items = [:syllabus_title] + Base_History_Items
    @collection = @entity.history :distinct => select_items
  end
  
    
  # --- altering 
   
  # for creating new syllabus
  def prepare_for_new
    # params(=@background_params) gives the current environment of the corner 
    @syllabus = @entity = Syllabus.new_run
    preparation_for_altering
  end
  
  # for updating syllabus
  def prepare_for_updating
    @syllabus = @entity
    preparation_for_altering
  end
  
  def preparation_for_altering
    @def_syllabus_form_items = Def_Syllabus_Form_Items
    @syllabus_form_items     = Syllabus_Form_Items
    @def_syllabus_book_form_items = Def_Syllabus_Book_Form_Items
    @syllabus_book_form_items     = Syllabus_Book_Form_Items
    @academic_year = @background_params.to_h[:academic_year]
    @academic_season = @background_params.to_h[:academic_season]
    @default_since = beginning_of_academic_season
    self.assert_time = @default_since
  end
  
  def prepare_for_destroying
    @def_form_items = Def_Syllabus_Form_Items
    @form_items     = Form_Deleting_Items    
  end
                     
  def prepare_for_adding_assoc_target(syllabus, pre_assoc_items)
    @course = find_entity(pre_assoc_items[-4])
    @academic_year = @background_params.to_h[:academic_year]
    @academic_season = @background_params.to_h[:academic_season]
    @default_since = beginning_of_academic_season
  end
end