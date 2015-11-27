=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# 参考資料

class DocumentsController < RunsController
  skip_before_filter :login_required, :only   => [:index, :show, :search]
  
  before_filter      :admin_only,     :except => [:index, :show, :search]
  
  Def_Items = item_struct "Document",  [:id, "",     ".id"],  [:run_id, "", ".run_id"],
              [:run_id,       "run_id", ".run_id"],
              [:title,        "題名",    ".title"],
              [:english_title, "英文題名", ".english_title"],
              [:authors,      "著者",    ".authors"],
              [:url,          "URL",    ".url",  :render_link_to_url], 
              [:description,  "説明",    ".description"],
              *Base_Def_Altering_Items
  List_Items = [:title, :english_title, :authors, :description, :url] + Base_Altering_Items
  
  Def_Form_Items = form_item_struct Def_Items,
                   [:title],
                   [:english_title],
                   [:authors],
                   [:url],
                   [:description, nil, :text_area]
  Form_Items     = [:url, :title, :english_title, :authors, :description]
              
  Correcting_Items = [:title, :english_title, :authors, :description, :url]

  def allow_to_add_new_entity?(options ={})
    admin? 
  end

 protected
  
  def find_collection
    @header_local_info = ["参考資料を管理します．", "参考資料は /public/doc/の下にpdfとして入れておくこと．urlの欄には /doc/file_nameの形で記入する."]
    @def_items  = Def_Items
    @list_items = List_Items
    @collection =  Document.find :all, 
                               :page => current_page, 
                               :scope => ":self",
                               :order => "created_at DESC"
  end
  
  def prepare_for_new
    @document = @entity = Document.new_run
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
  end
  
  def prepare_for_updating
    @document = @entity
    @def_form_items   = Def_Form_Items
    @form_items       = Form_Items
  end

  def after_put
    @confirmation_method = "find_collection"
    # for history's entity page(this has not
    @entity_template  = "entity"
  end
end
