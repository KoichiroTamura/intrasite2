=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class UnionsController < RunsController


  def index
    real_name = @current_user.real_name.tr("　","").tr(" ","").split(//).join('%')
    @account=UserInfo.find(:all,:select=>"distinct name",:scope=>":self",:conditions=>"real_name like '#{real_name}' and name<>'#{@current_user.name}' and (category='院生' or category='学部生') ")

    render :text=>"<script>alert('対象のアカウントはありません。');location.href='/';</script>" unless @account
    render :text=>"<script>alert('対象のアカウントはありません。');location.href='/';</script>" unless @account.size>0
  end
  
  def action
    flash_back !auth_check?,"パスワードが間違っています"
#    return false if !auth_check?
    !auth_check? and return false

    Account.transaction do 
      @old_account = Account.find(:first,:scope=>":self",:conditions=>["name=?",params[:account_name]])
      @old_user = UserInfo.find(:first,:scope=>":self",:conditions=>["run_id=?",@old_account.user_info_run_id])
      @old_orgs = Organization.find(:all,:scope=>":self",:conditions=>["organized_entity_type='UserInfo' and organized_entity_run_id=?",@old_account.user_info_run_id])
      @current_account = Account.find(:first,:scope=>":self",:conditions=>["name=?",@current_account.name])
      @current_user = UserInfo.find(:first,:scope=>":self",:conditions=>["run_id=?",@current_account.user_info_run_id])
      @current_orgs = Organization.find(:all,:scope=>":self",:conditions=>["organized_entity_type='UserInfo' and organized_entity_run_id=?",@current_account.user_info_run_id])

      @old_account.till = @current_account.since.ago(-1)
      @old_account.save
      @old_user.till = @current_user.since.ago(-1)
      @old_user.save
      @old_orgs.each do |org|
        org.till = @current_user.since.ago(-1)
        org.save
      end
  
      @current_user.run_id = @old_user.run_id
      @current_user.save
      @current_account.run_id = @old_account.run_id
      @current_account.user_info_run_id = @current_user.run_id
      @current_account.save
  
      @current_orgs.each do |org|
        org.organized_entity_run_id = @old_user.run_id
        org.save
      end
      
      ActiveRecord::Migration.execute("update articles set created_by=#{@old_user.run_id} where created_by=#{@current_user.run_id}")
      ActiveRecord::Migration.execute("update members set user_info_run_id=#{@old_user.run_id} where user_info_run_id=#{@current_user.run_id}")
      ActiveRecord::Migration.execute("update article_people set user_info_run_id=#{@old_user.run_id} where user_info_run_id=#{@current_user.run_id}")
      ActiveRecord::Migration.execute("update destinations set designated_run_id=#{@old_user.run_id} where designated_run_id=#{@current_user.run_id} and designated_type='UserInfo'")
    end
    render :text=>"<script>alert('成功しました。以後、旧アカウントの使用はできません');location.href='/';</script>"
  end
  
private
  # まずは、過去のIDが通らないと、こちらも対処できない。
  def auth_check?
     @old_account = Account.new(:name=>params[:account_name],:password=>params[:password])
     begin
       @old_account.authenticate
       return true
     rescue
       return false
     end
  end

end