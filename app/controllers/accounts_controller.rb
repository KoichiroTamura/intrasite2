=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


class AccountsController < RunsController
  
  before_filter :admin_only, :except => [:changing_password,:change_password, :allow_to_add_new_entity?]
  skip_before_filter :owner_only
  
  A_Net = ":self ~>> user:UserInfo"  # allow to display accounts without its user_info

  Def_Items = item_struct "Account",  [:id, "",     ".id"],
              [:run_id,       "", ".run_id"],
              [:account_name, "アカウント名", ".name"],
              [:account_role, "role",   ".role"],
              [:passwd,       "passwd", ".passwd",      :shorten],
              [:user_info,    "ユーザ",   :user_info,    :user_info_detail_link],
              [:user_name,    "ユーザ名", "user.name"],
              [:real_name,    "実名",    "user.real_name"],
              [:name_ruby,    "よみ",    "user.name_ruby"],
              [:button_to_history, nil, :self, :button_to_history],
              *(Base_Def_History_Items + Base_Def_Altering_Items)
              
  List_Items       = [:account_name, :account_role, :user_info, :button_to_history]

  History_Items    = [:account_name, :account_role, :user_name] + Base_History_Items + Base_Altering_Items
  
  Correcting_Items = [:account_name, :account_role]
             
  Def_Account_Form_Items = form_item_struct Def_Items,
              [:account_name, :name,  :text_field, [:required => true] ],
              [:account_role, :role,  :select,  [Account::Roles]],
              [:user_info, nil, :render_association_to_put, [:required => true, :single => true]],
              Def_Since_Form_Item
              
  Account_Form_Items = [:since, :account_name, :account_role, :user_info]
  
  # prepare for changing own password
  def changing_password
    @account = current_account
  rescue => e
    flash[:error] = "アカウント名／パスワードの変更準備に失敗しました．理由：" + e
    redirect_to :controller => "/home"
  end
  
  def change_password
    flash.discard
    @account = current_account.dup  # CAUTION: DO NOT apply "clone", that makes id nil !
    @account.name     = params[:name]
    @account.password = params[:password]
    @account.change_name_and_password
    flash.now[:notice] = "アカウント／パスワードを下記のように変更しました.<br />" +
                         "一旦ログアウトし，新アカウント名／パスワードでログインしてください．"
  rescue => e
    flash.now[:error] = "アカウント名／パスワードの変更に失敗しました．<br />理由：" + e
  end

  def allow_to_add_new_entity?(opts ={})
    admin?    
  end
  
  protected
  
  def find_collection
    @def_items = Def_Items
    @list_items = List_Items
    @queries = [:account_name, :user_name, :real_name, :name_ruby, :account_role]
    
    @view_allowed = [ :adding_new_call, :no_detail_call]
    
    @collection = Account.find :all,
        :page  => current_page,
        :scope  => A_Net,
        :select   => select_items,
        :conditions => query_cond,
        :order      => "accounts.created_at DESC, accounts.name"
    flash_now @collection.blank?, "該当するアカウントはありません．"
  end

  def find_history
    @def_items = Def_Items
    @list_items = History_Items
    @collection = @entity.history :scope => A_Net, :distinct => select_items
    @view_allowed = [:no_detail_call]
  end
  
  def prepare_for_new(init = {})
    @account = @entity = Account.new_run()
    @user_info = @account.build_user_info()
    @def_account_form_items   = Def_Account_Form_Items
    @account_form_items = Account_Form_Items
  end
  
  def prepare_for_updating
    @account = @entity
    @user_info = @account.user_info
    @def_account_form_items = Def_Account_Form_Items
    @account_form_items = Account_Form_Items
  end
  
  def prepare_for_adding_assoc_target(assoc_target, pre_assoc_items)
    @def_account_form_items = Def_Account_Form_Items
    @account_form_items     = Account_Form_Items - [:since, :user_info]
  end
  
  # check if user_info is given when create or update.
  def before_put
    @put_method == :delete and return # do nothing
    receiver = @entity_ref.to_entity
    receiver.entity_id = @entity_ref.entity_id
    user = receiver.user_info
    if user.blank? || user.new_record?
      receiver.errors.add :user_info, "既存のユーザを指定してください．"
      fail ActiveRecord::RecordInvalid.new(receiver)
    end
  end
  
end