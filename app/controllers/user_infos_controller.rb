=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class UserInfosController < RunsController
  
  before_filter :local_registered_only
  before_filter :admin_only, :only   => [:new, :create, :correcting, :correct, :destroying, :destroy]
  skip_before_filter :find_entity, :only => [:update_portrait]
  skip_before_filter :owner_only,  :only => :edit # for the case of editing self portrait.
  
  Def_Items = item_struct  "UserInfo",  [:id,        "",       ".id"], [:run_id, "", ".run_id"],
                             [:real_name, "実名",    ".real_name", :h],
                             [:name_ruby, "よみ",    ".name_ruby", :h],
                             [:name,      "ユーザ名", ".name"]
                             
  List_Items = [:name, :real_name, :name_ruby]

  Def_Detail_Items = Def_Items.merge( item_struct( "UserInfo",
                             [:email,    "Eメール", ".email"],
                             [:url,      "ウェブURL", ".url"],
                             [:group_members, "所属グループ", :group_members, "groups/to_group"],
                             [:room_no, "研究室", ".room_no"],
                             [:room_phone, "研究室TEL", ".room_phone"],
                             [:lab_no, "実験室", ".lab_no"],
                             [:lab_phone, "実験室TEL", ".lab_phone"],
                             [:cellular_phone, "携帯TEL", ".cellular_phone"],
                             [:phone, "自宅TEL", ".phone"],
                             [:address, "自宅住所１", ".address"],
                             [:address2, "自宅住所２", ".address2"],
                             [:description, "自己紹介", ".description"],
                             [:zipcode, "郵便番号", ".zipcode"],
                             [:accounts, "アカウント", :accounts, "accounts/attached_account"],
                             [:organizations, "所属とステータス", :organizations],
                             [:attached_files, "添付ファイル", :attached_files],
                             *(Base_Def_History_Items + Base_Def_Altering_Items)
                             ))
                             
  Detail_Items =     [:accounts, :real_name, :name_ruby, :name,
                      :email, :url, :organizations, :group_members,:room_no,
                      :room_phone, :lab_no, :lab_phone, :cellular_phone, :phone,
                      :zipcode, :address, :address2, :description, :attached_files]                      
                               
  History_Items = [:real_name] + Base_History_Items
 
  Def_Form_Items = form_item_struct Def_Detail_Items, 
                             [:real_name, nil, nil, [{:required => true}]],
                             [:name_ruby],
                             [:name, nil, nil, [:required => true]],
                             [:accounts, nil, :render_association_to_put,[:local_info => "初期設定としてアカウント名はユーザ名と同じにしてください．"]],
                             [:email,nil, nil, [:required => true]],
                             [:url],
                             [:room_no],
                             [:room_phone],
                             [:lab_no],
                             [:lab_phone],
                             [:cellular_phone],
                             [:phone],
                             [:zipcode],
                             [:address],
                             [:address2],
                             [:description, nil, :text_area],
                             [:attached_files, nil, :render_association_to_put, [:legend => "添付ファイル", :entity_template => "attached_files/input/collection"]],
                             [:group_members,  nil, :render_association_to_put, [:entity_template => "groups/input/group_connection"]],
                             [:organizations,  nil, :render_association_to_put, [:required => true,
                                                                                  :show_items => [:seq, :title, :post]]],
                             Def_Since_Form_Item
                           
  Form_Items_For_Admin = [:since, :name, :real_name, :name_ruby, :accounts, :email, :organizations, :group_members]
  
  Form_Items_For_User  = [:since, :real_name,:name_ruby, :email,:url,:room_no,:room_phone,:lab_no,
                          :lab_phone,:cellular_phone,:phone,:zipcode,:address,:address2, :description, :attached_files]
                          
  Def_Account_Form_Items = AccountsController::Def_Account_Form_Items
  Account_Form_Items     = AccountsController::Account_Form_Items


  def allow_to_add_new_entity?(opts ={})
    admin?    
  end
  
  # update user's own info.
  def update_portrait
    update
  end
                                
  protected

  def a_net
    ":self [#{test_user_cond()}
            (" + organization_net("", "aff", "sta") + ")]"
  end
  
  def test_user_cond
    admin? || test_user? ? "" : "(<< account:Account .role <> 'test')"
  end
  
  def query_cond
    merge_conditions(query_conditions(params[:query], *query_from_items),
                     tree_condition(@affiliation, "aff"), 
                     tree_condition(@status, "sta"))
  end  
  
  def find_collection
    @header_local_info = ["登録されているすべてのユーザについての情報です．",
                          "左の木構造で，所属組織，ステータス（ユーザの状態）を指定することが出来ます．",
                          "登録ユーザのみ見ることが出来ます．ゲストユーザは見ることが出来ません．",
                          "登録ユーザは自分の情報の更新が出来ます．ただし，所属など，公的なものは変更できません．もしこれらについて変更があれば，イントラweb委員会にご連絡ください．"]
    @def_items  = Def_Items
    @list_items = List_Items
    
    @queries    = List_Items
    
    # affiliation fullname (+ Position::With_Singular_Leaf)
    @affiliation = params[:affiliation] || @current_user.affiliation_name
    # status fullname (+ Position::With_Singular_Leaf)
    @status      = params[:status]      || @current_user.status_name
    # modify 
    @background_params ||= {}
    @background_params.merge! :affiliation => @affiliation, :status => @status
    
    @entity_template = "shared/entity_with_remote_detail_call"
    @view_allowed = [:detail_call]

    admin? and @view_allowed += [:adding_new_call] 
   
    @collection = UserInfo.find :all, 
       :page       => current_page,
       :scope      => a_net,
       :distinct   => select_items,
       :conditions => merge_conditions(query_cond)
    flash_now @collection.blank?, "該当ユーザはありません．"
  end
  
  def find_detail
    @def_items =  Def_Detail_Items
    @detail_items =  Detail_Items  
    admin? ? @detail_items += Base_Altering_Items : @detail_items -= [:accounts]
  end
  
  def find_history
    @def_items = Def_Detail_Items
    @list_items = History_Items
    @collection = @entity.history :distinct => select_items
  end
  
    
  # creating user_info                  
  def prepare_for_new
    @user_info = @entity = UserInfo.new_run
    @background_params = params[:background_params] || {}
    default_attrs = environmental_attributes    
    @user_info.organizations.build default_attrs[:organization]
    @user_info.group_members.build
    @user_info.accounts.build(:role => "user")
    preparation_for_altering
  end

  
  def prepare_for_updating
    @user_info = @entity
    preparation_for_altering
  end

  def preparation_for_altering
    @def_form_items = Def_Form_Items
    @form_items = 
      if params[:id] == "0"   # special case for self portrait update
        @response_template = "edit_portrait"
        Form_Items_For_User
      else                  # editing by admin
        admin_only
        Form_Items_For_Admin
    end
    @def_account_form_items = Def_Account_Form_Items
    @account_form_items     = Account_Form_Items - [:since, :user_info]
  end
  
  def environmental_attributes
    affiliation = @background_params[:affiliation] || Affiliation::ROOT
    status      = @background_params[:status]      || Status::ROOT
    selected_affiliation_run_id = find_run_id_from_fullname("Affiliation", affiliation)
    selected_status_run_id      = find_run_id_from_fullname("Status",      status)

    {:organization => {:affiliation_run_id => selected_affiliation_run_id,
                       :status_run_id      => selected_status_run_id}}
  end
  
  def find_run_id_from_fullname(model, fullname)
    leaf_mark = Position::With_Singular_Leaf
    name = fullname.end_with?(leaf_mark) ? fullname.mb_chars[0..-2] : fullname
    model.to_model.find( :first, :scope => ":self", 
                         :select => {:run_id => "run_id"}, 
                         :conditions => {:fullname => fullname}).run_id
  end

  def after_put  
    attached_files_connection(@entity,"self")
  end

end