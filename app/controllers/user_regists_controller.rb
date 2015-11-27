=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class UserRegistsController < RunsController
  before_filter :set_guest
  skip_before_filter :login_required
  skip_before_filter :owner_only
  skip_before_filter :find_entity
  skip_before_filter :registered_only
  
  Def_Items = item_struct  "UserInfo",  [:id, "", ".id"], [:run_id, "", ".run_id"], 
                           [:real_name,        "実名",       ".real_name"],
                           [:name,        "ユーザ名",       ".name"],
                           [:phone,         "電話番号",     ".phone"],
                           [:address,     "住所",         ".address"],
                           [:description,          "自己紹介",     ".pr"]
                           
  Def_Form_Items = form_item_struct Def_Items,
                           [:real_name,nil,nil,nil,1],
                           [:name,nil,nil,nil,1],
                           [:phone],
                           [:address],
                           [:description,nil,:text_area]
                           
  Form_Items = [:real_name,:name,:phone,:address,:description]

  def set_guest
    unless @current_account
      account = Account.find(:first,:conditions=>"name='guest'",:scope=>":self")
      Run.set_current_account(account.run_id.to_i)
      Run.set_current_user
      
      @current_account=account
      @current_user=account.user_info      
    end
    
    if @current_account && @current_account.name!="guest"
      render :text=>"<script>alert('システムエラーです。管理者にお問い合わせください');</script>"
    end

  end
  def find_history
  end

  def prepare_for_new(param = {})
    @user_info = @entity = UserInfo.new_run
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
  end
  
  def index
    redirect_to :action=>"new"
  end

  def scan_name
    render :text=>Account.find(:all,:scope=>":self",:conditions=>["name=?",params[:name]]).size
  end

  def show
  end

  def before_put
    p = params["_universal_attribute_"]
    p = p[p.keys[0]]

    !p[:name] and fail "入力エラー"
    p[:name].blank? and fail "入力エラー" 
    !p[:real_name] and fail "入力エラー"
    p[:real_name].blank? and fail "入力エラー"

    ac = Account.find(:first,:conditions=>["name=?",p[:name]])
    ac and fail "このユーザ名（Eメールアドレス）はすでに登録されております"
    
    p[:category] = "公開ユーザ"
    p[:email] = p[:name]

    p[:accounts] = Hash.new
    c = random_id
    account_id = "new"+c+ Run::ID_Model_Separator + "Account"
    p[:accounts][account_id] = Hash.new
    p[:accounts][account_id][:name] = p[:name]
  end

 def after_put
  ActiveRecord::Base.transaction do
    p = params["_universal_attribute_"]
    p = p[p.keys[0]]
    new_no = Hash.new
    new_account_org = "new_account" + Run::ID_Model_Separator + "Organization"
    new_no[new_account_org] = Hash.new
    new_no[new_account_org][:organized_entity_type]="UserInfo"
    new_no[new_account_org][:organized_entity_run_id]=@entity.run_id.to_s
    new_no[new_account_org][:status_run_id]=Status.find(:first,:scope=>":self",:conditions=>"fullname like '%|登録ユーザ|'").run_id.to_s
    new_no[new_account_org][:affiliation_run_id]=Affiliation.find(:first,:scope=>":self",:conditions=>"fullname like '%|学外|'").run_id.to_s
    
   flash[:notice]="#{p[:real_name]}様、ご登録をありがとうございます．"

      begin
        mail_set = YAML.load_file("#{RAILS_ROOT}/config/mail.yml")
   
        m = Mailer::Send.new
        m.to=p[:name]
        m.subject="IntraSite 登録完了のおしらせ"
        m.body="Intrasite2へようこそ。\r\n\r\nこのメールは記入されたアドレスの確認のためのメールです。\r\n\返信する必要はありません。\r\n\r\nどうぞ、Intrasite2を大いにご利用ください。\r\nWeb委員会"
        mail_set[ENV["RAILS_ENV"]].each do |k,v|
          eval "m.#{k}='#{v}'"
      end
      oc = Organization.find(:first,:conditions=>["organized_entity_type=? and organized_entity_run_id=?","UserInfo",@entity.run_id.to_s])
      unless oc 
        m.send
      end
      rescue Exception=>err then
        logger.info "Mail Server Error"
        flash[:notice]=err
        ENV["RAILS_ENV"] == "production" and fail "メールが配送できないため、登録を取り消しました"
      end

    (new_no.to_entity_ref).put
  end
 end
end