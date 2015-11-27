=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# 時限lecture timeに対し，その開始時間と終了時間を与える．

class LectureTimeToRealTimesController < RunsController

  before_filter :admin_only
      
  Def_Items = item_struct "LectureTimeToRealTime",  [:id, "",     ".id"],
              [:run_id,          "",  ".run_id"],
              [:lecture_time,    "時限",     ".lecture_time"],
              [:real_start_time, "開始時間",  ".real_start_time", :render_real_time_part],
              [:real_end_time,   "終了時間",  ".real_end_time",   :render_real_time_part],
              *(Base_Def_History_Items + Base_Def_Altering_Items)
  List_Items = [:lecture_time, :real_start_time, :real_end_time] + Base_Altering_Items
  
  Def_Form_Items = form_item_struct Def_Items,
                   [:lecture_time],
                   [:real_start_time],
                   [:real_end_time],
                   Def_Since_Form_Item
              
  Form_Items = [:lecture_time, :real_start_time, :real_end_time, :since]

 protected
  
  def find_collection
    @def_items  = Def_Items
    @list_items = List_Items
    @collection =  LectureTimeToRealTime.find :all, 
                               :page => current_page, 
                               :scope => ":self",
                               :order => "lecture_time"
  end

  def prepare_for_new
    @lecture_time_to_real_time = @entity = LectureTimeToRealTime.new_run
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
  end
  
  def prepare_for_updating
    @lecture_time_to_real_time = @entity
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
  end
  
  def prepare_for_correcting
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
  end


  def after_put
    @confirmation_method = "find_collection"
    # for history's entity page(this has not
    @entity_template  = "entity"
  end

end