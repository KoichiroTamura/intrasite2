=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# 並松追加 2009.07.22 メニュー時変動対応 新規作成
# 
# 2009.07.28 intrasie-tからintrasite2-nbへ移動
# 
# メニューを画面に出すためのパーツを表示するところと、管理者用の機能
# 
#　[依存関係]
#*RunController : before_filler :set_current_account_and_userを想定 
#*Corners: Run
# 
# [修正遍歴]
# 2009.07.22 t.namimatsu 初版
# 2009.07.27 t.namimatsu 日付を考慮に入れるための細工
# 2009/08/17　田村　全面的改訂
# 2010/10/05　田村　Menu（同じテーブルを使用し，親子でつながる）を作り，それへのassocとしてmenusを指定．

class CornersController < RunsController

  skip_before_filter :login_required, :only => [:search,:back_to_current,:timer]

  before_filter      :admin_only, :except => [:search, :set_show_time_setting, :back_to_current,:timer]
  
  Def_Items = item_struct "Corner",  [:id, "",     ".id"],
              [:run_id,     "", ".run_id"],
              [:name,       "名称",    ".name"],
              [:url,        "URL",    ".url"],
              [:target_new, "新ウィンドウ？", ".target_new"],
              [:logined,    "要ログイン？",   ".logined"],
              [:role,       "account role", ".role"],
              [:parameters, "パラメータ",    ".parameters"],
              [:menus,      "メニュー",      :menus],
              *(Base_Def_History_Items+ Base_Def_Altering_Items)

  List_Items = [:since, :name, :role]
  
  Menu_Items = List_Items + [:url, :logined, :target_new, :parameters]
  
  Def_Form_Items   = form_item_struct Def_Items,
                   [:name, nil, nil, [:required => true]],
                   [:url],
                   [:target_new, nil, nil, 
                      [:size => 3, :local_info => "新ウィンドウ表示ならば, １"]],
                   [:logined, nil, nil, 
                      [:size => 3, :local_info => "ログインを必要とするならば, １"]],
                   [:role, nil, nil,
                      [:required => true, 
                       :local_info => "使用可とするアカウントのroleをカンマでつなぎます．"]],
                   [:parameters, nil, :text_area,
                       [:local_info => "メニューに伴うパラメータをハッシュで表します．"]],
                   [:menus, nil,:render_association_to_put, 
                       [:required => true,
                        :local_info => "メニューを作ります．"]],
                   Def_Since_Form_Item
              
  Form_Items      = List_Items + [:menus]
  
  Menu_Form_Items = Menu_Items
 
  def allow_to_add_new_entity?(options ={})
    admin? 
  end
  
  # show menus associated to corner
  # necessary to respond to remote call for toggled detail
  def show  
    catch :flash_now do find_detail end
    div_id = params[:div_id]
    render :update do |page|
      page[div_id].replace_html  :partial => "detail"
    end
  end
  
  # called when show_time_setting of layout is changed
  def set_show_time_setting
    change_show_time
    home_change_template = @simulation_mode ? "home/change_simulation_mode" : "home/change_show_time"
    render :update do |page|
      page[:show_time_setting].replace_html :partial => "layouts/show_time_setting"
      page[:page_jp_title].replace_html "ホーム"
#      page[:layout_calendar].replace_html :partial => "layouts/calendar_menu"
      page[:menu_clusters].replace_html :partial => "menu_clusters"
      page[:contents_i].replace_html :partial => home_change_template
    end
  end
  
  # called when "back_to_current" button of show_time_setting clicked
  def back_to_current
    change_show_time_to_current
    render :update do |page|
      page[:show_time_setting].replace_html :partial => "layouts/show_time_setting"
      page[:page_jp_title].replace_html "ホーム"
#      page[:layout_calendar].replace_html :partial => "layouts/calendar_menu"
      page[:menu_clusters].replace_html :partial => "menu_clusters"
      page[:contents_i].replace_html :partial => "home/back_to_current"  
    end
  end

  def universal_put
    catch :flash_now do 
      @entity = put
    end
    list_again
  rescue ActiveRecord::RecordInvalid => e
    render_error_messages(e)
  end
  
  protected
  
  # for index to respond to menu management action
  def find_collection
    @def_items  = Def_Items
    @list_items = List_Items + Base_Altering_Items
    @menu_items = Menu_Items

    @collection =  Corner.find :all, 
                         :page => current_page, 
                         :scope => ":self",
                         :conditions => "parent_run_id IS NULL OR parent_run_id = 0",
                         :order => "fullseq"
  end
  
  def find_detail
    @corner = @entity
    @menus  = @corner.menus
    @def_items    = Def_Items
    @menu_items   = Menu_Items
  end
  
  def prepare_for_new
    @menu = @entity = Corner.new_run
    preparation_for_altering
  end
  
  def prepare_for_updating
    @menu = @entity
    preparation_for_altering
  end
  
  def preparation_for_altering
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
    @def_menu_form_items = Def_Form_Items
    @menu_form_items     = Menu_Form_Items
  end


end
