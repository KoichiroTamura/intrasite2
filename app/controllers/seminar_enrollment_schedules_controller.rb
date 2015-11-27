=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# 希望ゼミ登録のスケジュール作成

class SeminarEnrollmentSchedulesController < RunsController
  
  before_filter :admin_only
       
  Def_Items = item_struct "SeminarEnrollmentSchedule",  [:id, "",     ".id"],
              [:run_id,         "",  ".run_id"],
              [:name, "年度", ".name"],
              [:stage, "ステージ", ".stage"],
              [:start_time, "開始日時", ".start_time", :time_in_japanese_style],
              [:end_time,   "終了日時", ".end_time",   :time_in_japanese_style],
              [:description,    "共通記述",     ".description"],
              [:description_for_teachers, "教員向け記述",  ".description_for_teachers"],
              [:description_for_students, "学生向け記述",  ".description_for_students"],
              *(Base_Def_History_Items + Base_Def_Altering_Items)
  List_Items = [:name, :stage, :start_time, :end_time, :description, :description_for_teachers, :description_for_students] + Base_Altering_Items
  
  Def_Form_Items = form_item_struct Def_Items,
                   [:name],
                   [:stage],
                   [:start_time, nil, :datetime_select_jp],
                   [:end_time,   nil, :datetime_select_jp],
                   [:description,              nil, :text_area],
                   [:description_for_teachers, nil, :text_area],
                   [:description_for_students, nil, :text_area],
                   Def_Since_Form_Item
              
  Form_Items = [:since, :name, :stage, :start_time, :end_time, :description, :description_for_teachers, :description_for_students]
  
  
  def allow_to_add_new_entity?(options ={})
    admin? 
  end

 protected
 
  def find_collection
    @year = get_academic_year
    @collection = SeminarEnrollmentSchedule.find_schedules(@year)
    @entity_template = "entity_for_admin"
    @def_items  = Def_Items
    @list_items = List_Items
  end

  def prepare_for_new
    receive_and_set_background_params
    @seminar_enrollment_schedule = @entity = SeminarEnrollmentSchedule.new_run
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
  end
  
  def prepare_for_updating
    @seminar_enrollment_schedule = @entity
    @seminar_enrollment_schedule.name = @entity.name.to_i + 1
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
  end

  def after_put
    @confirmation_method = "find_collection"
  end
  
end