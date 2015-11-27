=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# ゼミ登録配属の手引きの表示とデータ管理

class SeminarRegistIntroductionsController < RunsController
  before_filter :admin_only, :only => [:new, :create, :updating, :update, :destroy]

  skip_before_filter :find_entity, :only => :show

  Path = "#{RAILS_ROOT}/seminar_regist_introduction/"
  
  Menu_Name = "ゼミ登録：ゼミ配属の手引きファイル管理"
  Header_Local_Info = ["ゼミ登録のコーナーで，配属方法について説明するファイルの管理をします．",
                       "教職員向けと，学部生向けのファイルが担当の先生によって作成されますから，それを用意してください．"]
  
  Def_Items = item_struct "SeminarRegistIntroduction",  [:id, "",     ".id"],
              [:run_id,       "", ".run_id"],
              [:name, "ファイル名", ".name"],
              [:category, "ユーザカテゴリ", ".category"],
              [:button_to_history, nil, :self, :button_to_history],
              *(Base_Def_History_Items + Base_Def_Altering_Items)
              
  List_Items = [:name, :category] + Base_Altering_Items - [:deleting] + [:button_to_history]
  
  Detail_Items  = [ :name , :category, :since ]

  History_Items = [:name, :category] + Base_History_Items + Base_Altering_Items
              
  Def_Form_Items = form_item_struct Def_Items,
              [:name, :name,  :text_field ],
              [:category, :category, :select, [UserInfo::User_Categories]],
              Def_Since_Form_Item
  
  
  def show
      @year = get_academic_year
      category = params[:user_category] || @current_user.category
      span = Run.get_academic_year_range_for_time

      state = SeminarRegistIntroduction.find :first, :conditions => "(since BETWEEN '#{span.begin}' AND '#{span.end}') AND category='#{category}'"
      state or (render :text=>"<h3>今年度の｢配属の手引き｣はまだ準備されていません．</h3>"; return false)

      send_file Path + state.name, :type => 'application/pdf',:disposition => "inline" 
  end
  
  protected
  

  def find_collection
    @menu_name = Menu_Name
    @header_local_info = Header_Local_Info
    flash_now !admin?, "システム管理者のみこの形式で呼ぶことが出来ます．"
    @collection = SeminarRegistIntroduction.find :all, 
                                :scope => ":self",
                                :order => "fullseq"
    @def_items  = Def_Items
    @list_items = List_Items
  end
  
  def find_detail
    @help_info = @entity
    @def_items    = Def_Items
    @detail_items = Detail_Items
  end
  
  def prepare_for_new
    @entity = SeminarRegistIntroduction.new_run
    @def_form_items = Def_Form_Items
  end
  
  def find_history
    @def_items  = Def_Items
    @list_items = History_Items
    @collection = @entity.history :distinct => select_items
  end
  
  def prepare_for_updating
    @def_form_items = Def_Form_Items
  end

  

end
