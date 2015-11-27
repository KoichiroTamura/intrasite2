=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class MailsController < RunsController
  require "jcode"

  Def_Items = item_struct( "Mail", [:id, "", ".id"],  [:run_id, "", ".run_id"],
                      [:title,  "タイトル", ".title"],
                      [:mail_account_run_id,   "From",  ".mail_account_run_id"],
                      [:mail_to,   "宛先",  :mail_to],
                      [:priority,   "重要度", ".priority"],
                      [:disposition_notification,   "開封確認", ".disposition_notification"],
                      [:body,   "本文", ".body"],
                      *Base_Def_History_Items )
                        
  Def_Form_Items = form_item_struct Def_Items,
                   [:title],
                   [:mail_account_run_id, nil, :render_mail_account],
                   [:mail_to, nil, :render_association_to_put, [:legend => "宛先"]],
                   [:priority, nil,  :radio_button_selection, [["Very High", "非常な高い"], 
                                                              ["High", "高い"],
                                                              ["Normal", "標準"],
                                                              ["Low", "低い"],
                                                              ["Very Low", "非常に低い"]
                                                              ]],
                   [:disposition_notification, nil,  :radio_button_selection, [["1", "求める"], 
                                                              ["0", "求めない"]
                                                              ]],
                   [:body, nil, :text_area]
              
  List_Items = [:run_id,:title,:priority]
                
  Form_Items = [:title,:mail_account_run_id,:mail_to,:priority,:disposition_notification,:body]

  def prepare_for_new
    @mails = @entity = Mail.new_run
    @def_form_items = Def_Form_Items
    @form_items     = Form_Items
  end

  def find_collection
    @def_items  = Def_Items
    @list_items = List_Items
    @collection =  Mail.find :all, 
                               :page => current_page, 
                               :scope => ":self",
                               :conditions=>"created_by=#{@current_user.run_id}",
                               :order => "created_at DESC"
  end

  def after_put
      begin
        mail_set = YAML.load_file("#{RAILS_ROOT}/config/mail.yml")
   
        m = Mailer::Send.new
        m.subject=@entity.title
        m.body=@entity.body
        m.from=@current_user.email.to_s
        
  # 連打の危険があるので、現在封鎖中
  #      if @entity.mail_account_run_id != 0
  #         ma = MailAccount.find(:first, :scope=>":self", :conditions=>["user_info_run_id=? and run_id=?",@current_user.run_id,@entity.mail_account_run_id.to_i])
  #         m.smtp_server = m.smtp_server
  #         logger.debug "Server Set: #{m.smtp_server}"
  #      end

        if (@entity.disposition_notification==1)
              m.disposition_notification=m.from.to_s
        end

        tos_b = Array.new();
  
        @entity.mail_to.each do |t|
    	 		  tos_b.push(t.mailaddress)
    		end
    		
    		m.to=tos_b.join(",")
    		
        mail_set[ENV["RAILS_ENV"]].each do |k,v|
          eval "m.#{k}='#{v}'"
        end

        m.content_type="text/html; charset=utf-8"
        
        m.send
        
      rescue Exception=>err then
        flash[:notice]="サーバ接続エラー"
        logger.debug "Server Error"
        logger.debug err
      end
  end

  def find_history
    
  end

end
