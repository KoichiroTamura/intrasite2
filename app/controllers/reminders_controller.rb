=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class RemindersController < RunsController

  skip_before_filter :find_entity
  skip_before_filter :login_required
  skip_before_filter :owner_only
  skip_before_filter :registered_only
  before_filter :not_login
  
  # 標識数の有効期間 (秒) 2011.07.29
  Valid_of_change_password = 3600

  def not_login
    render_flash_now_if((@current_account!=nil), "ログイン出来ないユーザのみが利用できます．")    
  end

  def show
    flash.delete(:notice)
  end

  def create
  ActiveRecord::Base.transaction do
      if params[:name].blank?
        render :update do |t|
          flash[:notice]="該当するアカウントはないか、有効ではありません"
          t.replace_html :flash_notice, {:partial => "shared/flash_notice"}
          t.replace_html :form_processing, :text=>"<script>$('process_form').style.display='block';step=0</script>"
        end
        return false
      end

      if params[:name] == "guest"
        render :update do |t|
          flash[:notice]="ゲストユーザのパスワードは変更できません。"
          t.replace_html :flash_notice, {:partial => "shared/flash_notice"}
          t.replace_html :form_processing, :text=>"<script>$('process_form').style.display='block';step=0</script>"
        end
        return false
      end

      account = Account.find(:first,:scope=>":self",:conditions=>["name=?",params[:name]])
      unless account
        render :update do |t|
          flash[:notice]="該当するアカウントはないか、有効ではありません"
          t.replace_html :flash_notice, {:partial => "shared/flash_notice"}
          t.replace_html :form_processing, :text=>"<script>$('process_form').style.display='block';step=0</script>"
        end
        return false
      end
  
      if params[:password].blank?
        render :update do |t|
          flash[:notice]="パスワードが不適切です"
          t.replace_html :flash_notice, {:partial => "shared/flash_notice"}
          t.replace_html :form_processing, :text=>"<script>$('process_form').style.display='block';step=0</script>"
        end
        return false
      end
  
      pr = PasswordRegist.find(:all,:scope=>":self",:conditions=>["account_run_id=?",account.run_id])
      if pr 
        pr.each do |old_pr|
          old_pr.delete
        end
      end
      
      names = "new" + random_id + "#{Run::ID_Model_Separator}PasswordRegist"
      code_on_mail = "#{rand*10000000}".to_s
      
      pr = Hash.new
      pr[names] = Hash.new
      pr[names][:account_run_id] = account.run_id.to_s
      pr[names][:code_on_mail] = code_on_mail
      pr[names][:password] = params[:password]
      pr[names][:till] = @action_time.since(Valid_of_change_password).to_s
      pr[names][:since] = @action_time.to_s
      pr[names][:created_at] = @action_time.to_s
      pr[names][:session_key] = params[:authenticity_token]

      begin
        mail_set = YAML.load_file("#{RAILS_ROOT}/config/mail.yml")
   
        m = Mailer::Send.new
        m.to=account.user_info.email
        m.subject="IntraSite パスワード設定の確認"
        m.body_with_template_file("template_password_missing",{:user_name=>account.user_info.real_name,:auth_code=>code_on_mail})
        mail_set[ENV["RAILS_ENV"]].each do |k,v|
          eval "m.#{k}='#{v}'"
        end
        
        check_pr = PasswordRegist.find(:first,:scope=>":self",:conditions=>["account_run_id=? and session_key=?",account.run_id,params[:authenticity_token]])
        unless check_pr 
          m.send
        end
      rescue Exception=>err then
        fail "Mail Server Error"
      end
      
      prs = pr.to_entity_ref

      Run.set_current_account(account.run_id.to_s) 
      Run.set_current_user
      prs.put
      
      render :update do |t|
        flash.delete(:notice)
        t.replace_html :information, {:partial=>"check"}
      end

  end
  end

  def update
    Account.transaction do
      account = Account.find(:first,:scope=>":self",:conditions=>["name=?",params[:name]])
      unless account
        render :update do |t|
          flash[:notice] = "該当するアカウントはないか、有効ではありません"
          t.replace_html :flash_notice, {:partial => "shared/flash_notice"}
          t.replace_html :form_processing, :text=>"<script>$('process_form').style.display='block';step2=0</script>"
        end
        return false
      end
  
      pr = PasswordRegist.find(:first,:scope=>":self",:conditions=>["account_run_id=?",account.run_id])
      unless check_input(pr,params)
        render :update do |t|
          flash[:notice] = "標識数またはパスワードが一致しません"
          t.replace_html :flash_notice, {:partial => "shared/flash_notice"}
          t.replace_html :form_processing, :text=>"<script>$('process_form').style.display='block';step2=0</script>"
        end
        return false
      end
  
      # 標識数を知って、新パスワードも知っているのであれば、おそらく本人だろう。
      Run.set_current_account(account.run_id)
      Run.set_current_user
     
      account.update_run! @action_time,:passwd=>account.hash_password(params[:password])
      

      pr.destroy
#      pr.delete
#      2011.07.29削除

      render :update do |t|
          flash[:notice]="パスワードが変更されました"
          t.replace_html :flash_notice, {:partial => "shared/flash_notice"}
          t.replace_html :form_processing, :text=>'更新完了...<script>window.open("/session/new","_top");</script>'
      end
    end
  end

private
  def check_input(pr,params)
    case false
    when pr.code_on_mail.to_s == params[:code_on_email].to_s
      return false
    when pr.verify_password(params[:password].to_s)  
      return false
    else
      return true
    end
  end
end