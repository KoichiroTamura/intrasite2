=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# system maintenance information controller

class MaintenanceInfosController < RunsController

  skip_before_filter :login_required, :only => [:index, :show, :search]
  
  before_filter      :admin_only, :except => [:index, :show, :search]
  
  Def_Items = item_struct "MaintenanceInfo",  [:id, "",     ".id"],
              [:run_id,     "", ".run_id"],
              [:created_at, "追加日", ".created_at", :date_format],
              [:content,    "記事",    ".content", nil, {:class => "box"}],
              *Base_Def_Altering_Items
  List_Items = [:created_at, :content] + Base_Altering_Items - [:updating]
  
  Def_Form_Items = form_item_struct Def_Items,
                   [:content, nil,  :text_area ]
              
  Form_Items = [:content]
              
  Correcting_Items = [:content]

  def allow_to_add_new_entity?(options ={})
    admin? 
  end

 protected
  
  def find_collection
    @def_items  = Def_Items
    @list_items = List_Items
    @collection =  MaintenanceInfo.find :all, 
                               :page => current_page, 
                               :scope => ":self",
                               :order => "created_at DESC"
  end
  
  def prepare_for_new
    @maintenance_info = @entity = MaintenanceInfo.new_run
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
  end
  
  def prepare_for_updating
    @maintenance_info = @entity
    @def_form_items   = Def_Form_Items
    @form_items       = Form_Items
  end

  def after_put
    @confirmation_method = "find_collection"
    # for history's entity page(this has not
    @entity_template  = "entity"
  end

end