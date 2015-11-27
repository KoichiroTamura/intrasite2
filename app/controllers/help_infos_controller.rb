=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class HelpInfosController < RunsController
    
  skip_before_filter :login_required, :only => [:index, :search, :show]
  
  before_filter      :admin_only,     :except => [:index, :show]
    
  Def_Items = item_struct "HelpInfo",  [:id, "",     ".id"],
              [:run_id,       "", ".run_id"],
              [:name, "名称", ".name", nil, [:required => true]],
              [:content, "内容", ".content", nil, [:required => true]],            
              [:button_to_history, nil, :self, :button_to_history],
              *(Base_Def_History_Items + Base_Def_Altering_Items)
              
  List_Items    = [:name, :button_to_history]
  
  Detail_Items  = [ :name, :content]

  History_Items = [:name] + Base_History_Items + Base_Altering_Items
              
  Def_Form_Items = form_item_struct Def_Items,
              [:name, :name,  :text_field ],
              [:content, :content, :text_area],
              Def_Since_Form_Item
  
 protected
 
  def find_collection
    @menu_name = params[:menu_name]
    help_name = params[:help_name]
    if help_name.blank?  # called for help_info management
      flash_now !admin?, "システム管理者のみこの形式で呼ぶことが出来ます．"
      @collection = HelpInfo.find :all, 
                                  :scope      => ":HelpInfo .name ~= .name :Corner",
                                  :conditions => "corners.fullname LIKE 'ヘルプ|%'",
                                  :order      => "corners.fullseq"
      @def_items  = Def_Items
      @list_items = List_Items
      @view_allowed = [ :adding_new_call]
    else                  # called by help_info menus for usual users
      @entity = HelpInfo.find :first,
                              :scope => ":self",
                              :conditions => {:name => help_name}
      find_detail
      render :partial => "detail", :layout => "application"
    end
  end
  
  def find_detail
      @help_info = @entity
      @def_items    = Def_Items
      @detail_items = Detail_Items
      @menu_name = params[:menu_name]
  end
  
  def find_history
    @def_items  = Def_Items
    @list_items = History_Items
    @collection = @entity.history :distinct => select_items
    @view_allowed = [:no_detail_call]
  end
  
  def prepare_for_new
    @help_info = @entity = HelpInfo.new_run
    @def_form_items = Def_Form_Items
  end
  
  def prepare_for_updating
    @help_info = @entity
    @def_form_items = Def_Form_Items
  end

   
end