=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# 旧版の「ゼミ紹介」に対応
# 
# 旧版のゼミ紹介は静的なもので、毎年ファイルをさしかえた。
# 新版のゼミ紹介は時変動の概念を取り込む。
#
# ゲスト権限者は閲覧不可
# 
# ただし、既存データが複数のファイルで構成されるので、
# 既存データの表示を阻害しないようにURLを一通りに固定した。
# それにしても、2005年以降、PDFやらSWFやらで、統一性がない
# 
# もう少しスマートな方法があれば、それを希望する by ナミマツ
#
# 2009.10.24
# 
class SeminarIntroductionsController < RunsController
  before_filter :admin_only, :except => [:show]
  
  skip_before_filter :find_entity, :only=>[:show]


  Def_Items = item_struct "SeminarIntroduction",  [:id, "",     ".id"],
              [:run_id,       "", ".run_id"],
              [:name, "ファイル名", ".name"],
              [:button_to_history, nil, :self, :button_to_history],
              *(Base_Def_History_Items + Base_Def_Altering_Items)
              
  List_Items = [:name] + Base_Altering_Items - [:deleting] + [:button_to_history]
  
  Detail_Items  = [ :name , :since ]

  History_Items = [:name] + Base_History_Items + Base_Altering_Items
              
  Def_Form_Items = form_item_struct Def_Items,
              [:name, :name,  :text_field ],
              Def_Since_Form_Item
  
  Correcting_Items = [:name]
 
# ADMIN KEY
 def allow_to_add_new_entity?(options ={})
    return false 
end

# パス情報
  Path = "#{RAILS_ROOT}/seminar_introductions/"
    
  # 表示日（年）を変更することで，その年のゼミ紹介が見られるようにすること．
  def show
    # 最後に/がないと曽我部さんの汗と涙の結晶が崩壊するからURLの確認
    unless request.url.include?("seminar_introduction/")
      redirect_to "/seminar_introduction/"
      return false
    end
    
    catch :flash_now do
      @year = get_academic_year
      state = SeminarIntroduction.find :first, :scope=>":self"
      state or (render :text=>"<img src='/images/under/under.png'><h1>工事中</h1>"; return false;)
      if state.name.include?("htm")
        render :file => Path + state.name
      else
        begin
          send_file Path + state.name,:type => 'application/pdf',:disposition => "inline"
        rescue
          (render :text=>"<img src='/images/under/under.png'><h1>工事中</h1>"; return false;)
        end
      end
    end
  end

  # ファイルが複数から構成されている場合があるので、その対応
  # できればこんなことは今後やめてほしい
  def swf_download
    params[:id].tr('..','')
    send_file Path+params[:id]+'.swf', :disposition => "inline", :type => 'application/x-shockwave-flash'
  end

  def html_download
    params[:id].tr('..','')
    send_file Path+"seminar2004/"+params[:id]+'.html', :disposition => "inline", :type => 'text/html'
  end

  def pdf_download
    params[:id].tr('..','')
    send_file Path+"seminar2004/pdf/"+params[:id]+'.pdf', :disposition => "inline", :type => 'application/pdf'
  end

  def pics_download
    params[:id].tr('..','')
    send_file Path+"seminar2004/pics/"+params[:id]+'.jpg', :disposition => "inline", :type => 'image/jpeg'
  end

  def header_download
    params[:id].tr('..','')
    send_file Path+"seminar2004/header/"+params[:id]+'.jpg', :disposition => "inline", :type => 'image/jpeg'
  end

  # 2004/imageはどうやら、レイアウトのようなので、publicにおくことにする。

 
 protected

  def find_collection
      flash_now !admin?, "システム管理者のみこの形式で呼ぶことが出来ます．"
      @collection = SeminarIntroduction.find :all, 
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
    @entity = SeminarIntroduction.new_run
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