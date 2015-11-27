=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# 卒論・修論要旨提出の説明資料の表示

class ThesisIntroductionsController < RunsController
  before_filter :admin_only, :only => [:new, :create, :updating, :update, :destroy]

  Def_Items = item_struct( "ThesisIntroduction", [:id, "", ".id"], [:run_id, "", ".run_id"],
                  [:academic_year, "年度", ".name"],
                  [:content, "説明", ".content"],
                  *(Base_Def_History_Items + Base_Def_Altering_Items)
                  )
                  
  List_Items   =  [:academic_year, :content]                  

  History_Items = [:academic_year] + Base_History_Items + Base_Altering_Items
              
  Def_Form_Items = form_item_struct Def_Items,
              [:academic_year, :name,  :text_field ],
              [:content, :content, :text_area],
              Def_Since_Form_Item
  
  def allow_to_add_new_entity?(options = {})
    admin?
  end
  
 protected

  def find_collection
    @def_items    = Def_Items
    @detail_items = List_Items
    @thesis_status = params[:thesis_status] || "卒業論文"
    @academic_year = get_academic_year
    @collection = ThesisIntroduction.find :all, 
                      :scope => :self,
                      :assert_time => :anytime,
                      :conditions => ["name = :academic_year", {:academic_year => @academic_year}, ],
                      :group => "thesis_introductions.run_id"
    @menu_name = "#{@academic_year}年度　卒論・修論要旨の作成要領"                  
    flash_now @collection.blank?, "今年度作成要領はまだ作成されていません．"
  end
      
  def find_detail
    @def_items    = Def_Items
    @detail_items = List_Items
    admin? and @detail_items += Base_Altering_Items
  end
  
  def find_history
    @def_items  = Def_Items
    @list_items = History_Items
    @collection = @entity.history :distinct => select_items
    @view_allowed = [:no_detail_call]
  end
  
  def prepare_for_new(init = {})
    @entity = ThesisIntroduction.new_run
    @def_form_items = Def_Form_Items
  end
  
  def prepare_for_updating
    @thesis_introduction = @entity
    @def_form_items = Def_Form_Items
  end

end
