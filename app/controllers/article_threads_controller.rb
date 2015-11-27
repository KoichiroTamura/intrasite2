=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# bases for handling articles ("メッセージ"　in old intrasite)

class ArticleThreadsController < RunsController
  
  before_filter :registered_only, :except => [:index, :show, :search]
  
  # :receive_mode parameters
  STANDARD  = "標準受信"
  EXTENDED  = "拡大受信"  
  ALL       = "すべて"
  SENT      = "送信済み"
  
  Header_Local_Info = ["メッセージ交換の場です．",
                       "登録ユーザならばだれでも発信できます．", 
                       "受信（閲覧）は，メッセージの宛先によって指定されます．",
                       "宛先として，個人，グループ，組織単位を指定できます．いずれも複数可です．このいずれかに入るユーザが受信（閲覧）出来ることになります．",
                       "予定日時を指定すると，（受信者の）スケジュールコーナーにも載ります．さらに場所を指定すると，その場所の使用予定を示すことになります．",
                       "これらの詳細は，各欄の<button>i</button>で．"]
  
  Career_Header_Local_Info = ["就活情報の交換の場です．",
                              "就活担当の先生からのメッセージや学生からの就活にまつわる情報を自由に発信してください．"]
  Form_Header_Local_Info   = ["提出書類の書式を扱います．",
                              "事務手続きその他，書類の書式を添付ファイルで与えてください．それを表示，プリントするなどして利用してください．"]
  Link_Header_Local_Info   = ["興味深いリンク情報を交換する場です．どなたでも興味を持ったページのリンクを自由に載せてください．",
                              "リンクは，URLの欄に記載します．"]
  Questionnaire_Header_Local_Info = ["アンケートを作り，利用するためのコーナーです．",
                                     "アンケートの設問作成，回答処理，回答の統計処理が行えます．",
                                     "一般メッセージの作成においてもアンケートを付加することが出来ます．"]
  
  Receive_Mode_Names = [STANDARD, EXTENDED, ALL, SENT]
  
  # article class name for lecture forum
  Lecture_Message = "授業メッセージ"
  Link_Info_Class = "関連リンク"
  
  # destination of articles at standard mode of receiving
  To_Individual   = "( ~<<  to_individual:ArticlePerson >>~)"    
  To_Group        = "( ~<<  to_group:ArticleGroup >> groups:Group  *memberable <<  group_members:GroupMember >>~)"  # CAUTION: variabl(alias) nameとしてgroupを使用すると，MySQLではキーワードと見なされ，構文エラーになるので注意．

  To_Affiliation  = "(.affiliation_run_id >> aff:Affiliation  contains user_aff:Affiliation << .affiliation_run_id)" 
  To_Status       = "(.status_run_id      >> sta:Status       contains user_sta:Status << .status_run_id)" 
  Organizational_Containment = To_Affiliation + To_Status
  To_Organization   = "(*organized_entity ~<< to_org:Organization [" + Organizational_Containment + "] user_org:Organization >>~ *organized_entity)"
  
  Basic_Destination =  To_Individual + To_Group + To_Organization
  Destination_Condition = "to_individual.id OR to_group.id OR to_org.id "
  
  Basic_A_Net = "threads:ArticleThread << articles:Article [#{Basic_Destination}] receiver:UserInfo"
  Basic_A_Net_Only = "threads:ArticleThread << articles:Article"
  
  # for marks "star" and "read" attached to each article
  Mark_Star        = ":articles:Article ~<- star_label_set:Star ->~ receiver:UserInfo"
  
  # for questionnaires（アンケート） to add a_net
  Questionnaire_Net      = ":Article *questionnairable << :Questionnaire"
  Week_Questionnaire_Net = ":Article *questionnairable ~<< :Questionnaire"

  # base of thread_items
  # grouping by "threads.run_id" is supposed.
  Def_Thread_Items = item_struct "ArticleThread", [:id, "",    ".id"], [:run_id, "", ".run_id"],
                      [:sender_name, "発信者",  latest_value_in_sql_group("articles", "sender_name")],
                      [:sender_name_to_query, "発信者", "articles.sender_name"],
                      [:send_time,    "発信時間", latest_value_in_sql_group("articles", "created_at")], 
                      [:title,        "タイトル", ".title", :render_h3],
                      [:content,      "本文",    latest_value_in_sql_group("articles","body")],
                      [:content_to_query, "本文", "articles.body"],
                      [:no_of_articles,"記事数",  "COUNT(DISTINCT articles.id)", :sandwich_by_parentheses],
                      [:latest_article_id, "",   "MAX(articles.id)"],
                      [:label_set, "",      "labels.name"],
                      [:star_label_set, "", latest_value_in_sql_group("star_label_set","name")],
                      [:cumulative_star_label, "", "GROUP_CONCAT(star_label_set.name SEPARATOR ',')"],
                      [:articles, "記事", :articles]
                      
  Query_Items = [:sender_name_to_query, :title, :content_to_query]
                      
  Thread_List_Items = Def_Thread_Items.keys - [:articles]
  
  Thread_Detail_Items = [:title, :no_of_articles, :label_set]
                      
  # base of article_items
  Def_Article_Items = item_struct( "Article", [:id, "", ".id"],  [:run_id, "", ".run_id"],
                      [:title,        "タイトル", ".title"],
                      [:forum_run_id, "", ".forum_run_id"],
                      [:forum_type, "", ".forum_type"],
                      [:destinations,  "宛先", :self, :render_destinations],
                      [:to_individuals, "個人", :to_individuals, "/members/entity"],   # to_individual
                      [:to_groups, "グループ", :to_groups, "/groups/to_group"],         # to_group
                      [:organizations,"組織", :to_orgs, "/organizations/entity"],      # to_org
                      [:star_label_set,    "☆", "star_label_set.name"],
                      [:sender,        "発信者", :sender, :user_info_detail_link],
                      [:answerer,      "回答者", :answerer, :user_info_detail_link],   # creater of answer_response article for questionnaire
                      [:send_time,     "発信時間", ".created_at", :time_in_japanese_style],
                      [:created_by,    "", ".created_by"],
                      [:content,       "内容", ".body"],
                      [:head_line,     "見出し", ".body",  [:shorten, 20]],
                      [:categories,      "拡張カテゴリ", ".user_category", [:render_select_set_elements, UserInfo::User_Categories]],
                      [:time_place_settings, "予定日時と場所", :self, :render_time_place_settings],
                      [:start_date,     "開始日",   ".start_date"],
                      [:end_date,       "終了日",   ".end_date"],
                      [:start_datetime, "開始日時", ".start_datetime", :time_in_japanese_style], 
                      [:end_datetime,   "終了日時", ".end_datetime",   :time_in_japanese_style],
                      [:shared_place,  "共用場所", :shared_place,      :render_shared_place],
                      [:place_run_id,  "", ".place_run_id"],
                      [:non_shared_place, "非共用場所", ".non_shared_place"],
                      [:contact_to,    "連絡先", ".contact_to"],
                      [:article_class, "記事種別", ".article_class"],
                      [:url, "関連リンク", ".url"],
                      [:attached_files, "添付ファイル", :attached_files ], 
                      [:questionnaires, "アンケート設問",  :questionnaires],
                      [:is_news, "", ".is_news"],                          # for messages
                      [:is_news_for_schedules, "メッセージ？", ".is_news"],  # for schedules
                      [:is_general, "一般メッセージ？", ".is_general"],   # for messages
                      [:is_general_hidden, "", ".is_general"],  # for general messages and schedules
                       *(Base_Def_History_Items + Base_Def_Altering_Items) )
                     
  Article_List_Items   = [:sender, :send_time, :title]
  Answer_Response_List_Items = [:answerer, :article_class, :send_time]
  
  Article_Detail_Items = [:destinations, :categories, :time_place_settings,
                          :contact_to, :url, :article_class, :attached_files] 
                          
  Answer_Response_Detail_Items = [:destinations, :send_time]                   
                           
  Article_History_Items = [:title] + Base_History_Items 
              
  Def_Thread_Form_Items = form_item_struct Def_Thread_Items,
                      [:articles, nil, :render_association_to_put, [:required => true, :single => true]]
                      
  Def_Article_Form_Items = form_item_struct Def_Article_Items,
                      [:title, nil, nil, [:required => true]],
                      [:destinations, nil,   :render_input_destinations, 
                         [:required => true, 
                          :local_info => ["個人およびグループ，組織に所属するユーザが[標準受信]時に受信者となります．いずれも複数指定できます．",
                                          "メッセージでは，記事の発信時点における所属，スケジュールでは，予定日時における所属です．"]]],
                      [:to_individuals, nil, :render_association_to_put, [:legend => "個人宛先",    :entity_template => "members/input/member"]],
                      [:to_groups, nil,      :render_association_to_put, [:legend => "グループ宛先", :entity_template => "groups/input/group_connection"]],
                      [:organizations, nil,  :render_association_to_put, 
                        [:local_info => ["所属とステータス（状態）で指定します．"]]],                     
                      [:content,:body, :text_area, [:html_options=>"rows=30"]],
                      [:categories, :user_category, :render_input_select_set_elements, 
                         [UserInfo::User_Categories, 
                         {:local_info => ["宛先の受信者に加えて，チェックされたカテゴリのユーザが[拡大受信]時に受信できるようになります．",
                                          "宛先の指定と異なり，時間に関係せず，受信者のカテゴリで受信（閲覧）が決まります．"]}]],
                      [:time_place_settings, nil,   :render_input_time_place_settings,
                         [:local_info => ["予定日時を設定すると，この記事は予定記事として｢スケジュール｣に載ります．", "場所を指定すると，共用場所の場合はその場所の使用予定となります．"]]],
                      [:start_date, nil, :date_select_jp],
                      [:end_date,   nil, :date_select_jp],
                      [:start_datetime, nil, :datetime_select_jp], 
                      [:end_datetime,   nil, :datetime_select_jp],
                      [:shared_place,   nil, :render_select_shared_place,
                       [:local_info => "会議室，教室等，共用の場所を指定します．共用差所でない場合は，自由記入で，非共用場所を指定してください．"]],
                      [:place_run_id],
                      [:non_shared_place],
                      [:contact_to],
                      [:url],
                      [:article_class, nil, nil],
                      [:attached_files, nil, :render_association_to_put, [{:legend => "添付ファイル", :entity_template => "attached_files/input/collection"}]],                    
                      [:forum_type, nil, :hidden_field],                    
                      [:forum_run_id, nil, :hidden_field],   
                      [:is_news, :is_news, :hidden_field],  # for messages
                      [:is_news_for_schedules, :is_news, :radio_button_selection, [[true, "メッセージコーナーにも載せる．"], [false, "スケジュールのみ"]]], # for schedules
                      [:is_general, nil, :radio_button_selection, [[true, "一般メッセージコーナーにも載せる"], [false, "このコーナーのみ"]]], 
                      [:is_general_hidden, :is_general, :hidden_field],
                      [:questionnaires, nil, :render_association_to_put,
                       [:local_info => ["アンケートの設問を作成します．回答方式は，単一選択，複数選択，自由記入のいずれかを選べます.", 
                                        "アンケート回答の統計処理も用意されています．"]]],
                      Def_Since_Form_Item
                      
  Article_Form_Items = [:title,
                        :destinations,
                        :categories,
                        :content, 
                        :time_place_settings,
                        :contact_to, 
                        :url,
                        :article_class, 
                        :is_general,
                        :attached_files,
                        :questionnaires,
                        :forum_run_id, :forum_type,
                        :is_news]
                        
  Def_Answering_Form_Items = form_item_struct Def_Article_Items,
                      [:title, nil, :hidden_field],
                      [:forum_type, nil, :hidden_field],                    
                      [:forum_run_id, nil, :hidden_field],  
                      [:article_class, nil, :hidden_field],
                      [:is_news, nil, :hidden_field],
                      [:is_general, nil, :hidden_field]
                      
  Answering_Form_Items = [:title,
                          :forum_run_id, :forum_type,
                          :article_class,
                          :is_news, :is_general]

  Destination_Items = [:to_individuals, :to_groups, :organizations]
  
  Time_Place_Items  = [ :start_datetime, :end_datetime, 
                        :shared_place, :non_shared_place]                      
                        

  # ........... Label Handling ........................#

  # click on star mark
  def check_star
    entity = find_entity
    latest_article = Article.find params[:latest_article]
    div_id         = params[:div_id]
    latest_article.toggle_star
    render :update do |page|
      page.replace_html div_id,
        :partial => "article_threads/star",
        :locals =>  {:has_star => latest_article.star?}
    end
  end
  
  def get_check_box_flag
    receive_and_set_background_params
    label_name = params[:label_name]
    check_box_flag_list = params[:article_thread]
    
    if check_box_flag_list.blank?
      flash.now[:error] = "スレッドが選択されていません．"
    else
      check_box_flag_list.each do |th, value|
        value.to_i == 1  and  find_entity(th).add_label(label_name)
      end
    end
    list_again
  end
 
  
  # ........... end of Label_Handling ...............#

  def allow_to_add_new_entity?(opts ={})
    registered?
  end
  
  # special version for article_thread
  # confirmation is list_again (not standard confirmation method)
  def universal_put
    catch :flash_now do 
      @entity = put
    end
    list_again
  rescue ActiveRecord::RecordInvalid => e
    render_error_messages(e)
  end
  
  # special updating for article_thread
  # adding new article to a_thread as responder
  # params[:id] is supposed to be id of article to be responded
  def adding_responder
    article = find_entity
    @thread = article.a_thread
    receive_and_set_background_params
    @display_mode = @background_params[:display_mode]
    @responder = article.responder(@thread, params[:responding_to])
    
    base_div_id = params[:base_div_id]    # id of div to add
    uuid = random_id  # generate random id
    preparation_for_altering
    render :update do |page|  
       page.replace_html base_div_id, 
            :partial => "article_threads/responder", 
            :locals  => {:uuid => uuid},
            :object  => @responder
      end
  end 
  
  # questionnaire's answer version of adding_responder
  def adding_answer_responder
    article = find_entity # article with questionnaire
    @thread = article.a_thread
    @question_entities = article.questionnaires
    base_div_id = params[:base_div_id]    # id of div to add
    @answer_responder = article.answer_responder(@thread)
    @def_answer_responder_form_items = Def_Answering_Form_Items
    @answer_responder_form_items     = Answering_Form_Items
    render :update do |page|  
       page.replace_html base_div_id, 
            :partial => "article_threads/answer_responder", 
            :object  => @answer_responder
      end
  end
  
  # questionnaire's answer version of adding_responder
  def render_question_entities
    article = find_entity # article with questionnaire
    @question_entities = article.questionnaires
    base_div_id = params[:base_div_id]    # id of div to add    
    render :update do |page|  
       page.replace_html base_div_id, 
            :partial => "article_threads/question_entities"
      end
  end
  
  # get answer_response articles to a questionnaire article
  #   for author of questionnaire to evaluate answers with point.
  def list_answer_responses
    article = find_entity        # questionnaire article
    receive_and_set_background_params
    @display_mode       = params[:display_mode]
    @is_answer_response = true # choose only answer response article to questionnaire article
    @question_entities  = article.questionnaires
    find_detail_of_thread(article.a_thread)
    render :partial => "detail_with_answer_responses", :layout => "base_layout"
  end

 protected
  
  def find_collection(input_params = params)
    # time span of periodical change (ms)
    @periodical_change_span = -1
  
    @display_mode  = input_params[:display_mode] || "messages"
    @background_params = input_params.symbolize_keys
    @background_params.merge! :display_mode => @display_mode
    @article_class = @background_params[:article_class]
    
    @with_questionnaires = @background_params[:only_with_questionnaires]

    @menu_name = menu_name
    @header_local_info = header_local_info

    @receive_mode  = @background_params[:receive_mode] || STANDARD
    @label_name    = @background_params[:label_name]
    
    # for the case of being called as forum such as lecture forum
    @forum         = @background_params[:forum] 
    @academic_year = @background_params[:academic_year]
    @academic_season = @background_params[:academic_season]

    # set listing period as @background_params[:date] to @background_params[:display_month] ago.      
    last_datetime = @academic_year.blank? ? 
                      @show_time : 
                      [@show_time, end_of_academic_season(@academic_year, @academic_season)].min
                     
    # @background_params[:display_months] is number of months to display.
    @display_months = @academic_year.blank? ? (@background_params[:display_months].blank? ? 3 : @background_params[:display_months].to_i ) :
                                              12
    
    first_datetime = last_datetime - @display_months.months + 1.day
    send_time_cond = "(articles.created_at BETWEEN '#{first_datetime.beginning_of_day.to_s(:db)}' AND '#{last_datetime.end_of_day.to_s(:db)}')" + 
                     " AND ('#{@show_time.to_s(:db)}' BETWEEN threads.since and threads.till)"
    
    @time_now = last_datetime
    
    # item structs of whole items
    @def_items  = Def_Thread_Items
    @list_items = Thread_List_Items + [:id, :run_id]
    
    # items for attribute of article_thread entity
    @attr_items = [:id, :run_id] + Thread_List_Items
                   
    # items for query bar
    @queries =  Query_Items
    
    @collection = ArticleThread.find :all,
            :page       => current_page,
            :scope      => a_net(),
            :assert_time => :show_time,
            :local_assert_time => local_assert_time_for_destination("articles.created_at"),  
            :select     => select_items(@def_items, @list_items),
            :group      => "threads.id",
            :conditions => merge_conditions(send_time_cond, *basic_cond()),    
            :order      => "send_time DESC"
   
    @view_allowed = [:adding_new_call]
    @response_template = "article_threads/collection"

    flash_now @collection.blank?, "該当する記事はありません．"
  end 
  
  def a_net()
    result_setting = [Basic_A_Net, Mark_Star, personal_setting]
    # depending on whether called from "アンケート" menu or not
    result_setting << (@with_questionnaires ? Questionnaire_Net : Week_Questionnaire_Net)
    return [result_setting]
  end

  
  # in order to determine if receiver belongs to group or organization at "time",
  #   set local assert time to "time" for group_members and user_org in destination.
  def local_assert_time_for_destination(time)
    result = {}
    [:group_members, :user_org].each do |key|
      result.merge! key => time
    end
    result
 end

  # for labels attached by receiver to thread including "archive" and various labels.
  # those labels are packed into a cell
  def personal_setting
    "threads:ArticleThread ~<- labels:PersonalSetting .user_info_run_id = #{@current_user.run_id}"
  end
  
  def find_detail
    @display_mode  = "messages"
    find_detail_of_thread(find_entity)
  end
  
  # for share use in SchedulesController
  # list up article details of a_thread
  def find_detail_of_thread(a_thread) 
    @receive_mode = @background_params[:receive_mode]
    @display_mode = @background_params[:display_mode] || params[:display_mode]
    @background_params.merge! :display_mode => @display_mode
    @def_items = Def_Thread_Items
    @thread_detail_items = Thread_Detail_Items 

    # re-assure access conditions
    @thread =  ArticleThread.find :first,
                           :assert_time => :show_time,
                           :local_assert_time => local_assert_time_for_destination("articles.created_at"),
                           :scope      => a_net(),
                           :select     => select_items(@def_items, [:id, :run_id] + @thread_detail_items),
                           :conditions => merge_conditions(thread_restriction(a_thread), news_cond())

    flash_now @thread.no_of_articles <= 0, "このスレッドには現在受信する記事はありません．"
   
    # define article items   
    @def_article_items        = Def_Article_Items
    # items appeared in listing view of articles
    @article_list_items       = @is_answer_response ? Answer_Response_List_Items : Article_List_Items
    # items appeared in detail view of an article
    @article_detail_items     = @is_answer_response ? Answer_Response_Detail_Items : Article_Detail_Items
    @destination_items        = Destination_Items
    @time_place_setting_items = Time_Place_Items
 
    @def_questionnaire_items  = QuestionnairesController::Def_Items
    @questionnaire_list_items = (q_article = a_thread.questionnaire_article) && q_article.sender? ?
                                    QuestionnairesController::Sender_List_Items : QuestionnairesController::List_Items
                                    
    @articles         = article_assocs()
    flash_now @articles.blank?, "現在，このスレッドには記事がありません．"
    @article_template = @is_answer_response ? "articles/answer_response" : "articles/entity"                               
  end
  
  def find_history
    @entity     = find_entity(params[:id])  # redo find_entity since this is an Article not ArticleThread
    @def_items  = Def_Article_Items
    @list_items = Article_History_Items
    @collection = @entity.history :distinct => select_items(@def_items, @list_items)
  end
  
  # articles associated with a_thread for displaying its detail.
  def article_assocs(user = @current_user)
    @thread.associated_with  "Article","[( >> :self) ([#{Basic_Destination}(~<- star_label_set:Star ->~)] receiver:UserInfo)]",
            :assert_time => :show_time,
            :local_assert_time => local_assert_time_for_destination("articles.created_at"),
            :distinct     => select_items(Def_Article_Items, Def_Article_Items.keys),
            :conditions   => merge_conditions(receive_restriction_cond(user), news_cond, answer_response_cond(@is_answer_response)),
            :group        => "articles.id"
  end
  
  # extended destination conditions including the case of EXTENDED and ALL receive mode
  def destination_cond(user = @current_user)
    result  = Destination_Condition
    @self_receive_allowed and 
      result += " OR (articles.created_by = #{@current_user.run_id})"  #including sender as a receiver
    (@receive_mode == EXTENDED || @receive_mode == ALL) and 
      result += " OR articles.user_category LIKE CONCAT('%','#{@current_user.category}','%')"
    result
  end
  
  # conditions to identify destinated receiver
  # in Schedule, it might be different from @current_user when finding other user's schedules.
  def receiver_cond(user = @current_user)
    "receiver.run_id = #{user.run_id}"
  end
  
  # for receiving articles by user with various modes
  def basic_cond(user = @current_user)
    @receive_mode == SENT and return class_cond, news_cond, query_cond,  forum_cond, "articles.created_by='#{@current_user.run_id}' and receiver.run_id='#{@current_user.run_id}'"
    return receiver_cond(user), destination_cond(user), normal_cond, class_cond, news_cond, query_cond,  forum_cond
  end
  
  def normal_cond
     @receive_mode == ALL ? nil : "labels.id IS NULL OR labels.name NOT LIKE '%archive%'" 
  end
  
  def class_cond
     @article_class.blank? ?   "articles.is_general = TRUE" : "articles.article_class = '#{@article_class}'" 
  end

  def forum_cond
    @forum.blank? and return
    forum_id, forum_type = @forum.to_id_and_model_name
    "articles.forum_type = '#{forum_type}' AND articles.forum_run_id=#{forum_id}"
  end
  
  def news_cond
    @display_mode == "messages" ? "articles.is_news" :  nil 
  end
  
  def answer_response_cond(limit)
    limit ? "articles.article_class = '#{Article::Questionnaire_Answer_Class}'" :
            "articles.article_class <> '#{Article::Questionnaire_Answer_Class}'"
  end
  
  # restriction condition to receive a thread by current user
  def receive_restriction_cond(user = @current_user)
    merge_conditions receiver_cond(user), destination_cond(user)
  end
 
  
  def thread_restriction(a_thread) 
    thread_id_cond    = "threads.run_id = #{a_thread.run_id} AND articles.thread_run_id = #{a_thread.run_id}"
    merge_conditions thread_id_cond, receive_restriction_cond
  end

  
  # --- altering

  # for creating new article and its article_thread
  def prepare_for_new
    @display_mode = @background_params[:display_mode]
    @forum        = @background_params[:forum] || []
    preparation_for_altering
    
    sender_name   = @current_user.real_name
    @thread = @entity = ArticleThread.new_run(:no_of_articles => 0)
    article_class = (prm = @background_params[:article_class]).blank? ? Article::General_Class : prm
    if article_class == Article::General_Class
      @article_form_items = @article_form_items - [:is_general] + [:is_general_hidden]  # make this field hidden
    end
    init_article_attrs = { :article_class => article_class,
                           :is_general    => true,
                           :is_news       => true,
                           :sender_name   => sender_name}
                         
    unless @forum.blank?
      forum_id, forum_type = @forum.to_id_and_model_name
      init_article_attrs.merge! :forum_run_id => forum_id,
                                :forum_type   => forum_type,
                                :is_general   => false
    end
    
    if ["schedules" ,"space_schedules"].include? @display_mode
      @article_form_items = @article_form_items - [:is_news, :is_general] + [:is_news_for_schedules, :is_general_hidden]
      date = params[:start_date].to_datetime(:local).to_date
      init_article_attrs.merge! :start_date => date,
                                :end_date   => date,
                                :start_datetime => date,
                                :end_datetime   => date,
                                :is_news => false,
                                :is_general => true,
                                :time_place_settings => 1    
    end
    
    if @display_mode == "space_schedules"
      # set pre_selection of shared_place
      space_span = @background_params[:space_span]
      init_article_attrs.merge! :place_run_id => Space.entity_by_name(space_span).run_id
    end

    @article = @thread.articles.build(init_article_attrs)
    @article.to_individuals.build :user_info_run_id => @current_user.run_id
    # as default organization destination.
    @article.organizations.build :affiliation_run_id => Affiliation.tree_root.run_id,
                                 :status_run_id      => Status.tree_root.run_id 
    if @background_params[:only_with_questionnaires]
      @article.questionnaires.build :question_no => 1
    end
    
  end
  
  # for updating article_thread
  # but, this is for responding article since responder article is added to article_thread; this is a kind of updating article_thread.
  # @entity is an article
  def prepare_for_updating
    @thread = @entity.a_thread
    @thread.articles.build @entity.responder.attributes
    preparation_for_altering
  end
  
  def preparation_for_altering
    @def_thread_form_items  = Def_Thread_Form_Items
    @thread_form_items  = []
    @def_article_form_items = Def_Article_Form_Items
    @article_form_items     = Article_Form_Items
    @destination_form_items = Destination_Items
    @time_place_setting_form_items  = Time_Place_Items
  end
  
  def prepare_for_correcting
    @def_form_items = Def_Article_Form_Items
    @form_items     = Correcting_Items
  end
  
  def after_put() 
    @entity or return # do nothing
    
    @thread = @entity
    if @put_method == :create
      add_extra_schedule_articles
      attached_files_connection(@thread.articles(:order => "articles.id DESC").first)
    end
    if @put_method == :update
      attached_files_connection(@thread.articles(:order => "articles.id DESC").first)
    end
    if @put_method == :delete
      @entity.destroy_banner_schedules
    end
  end
  
  # add artilces to make banner shcedule when schedule time is over multiple days.
  def add_extra_schedule_articles
    latest_article = @thread.articles(:order => "articles.id DESC").first
    s_time, e_time = latest_article.start_datetime, latest_article.end_datetime
    s_time or return # do nothing
 
    # over a day ?
    unless [s_time.year, s_time.yday] == [e_time.year, e_time.yday]
      # force to set banner.
      Article.update latest_article.id, :banner_run_id => latest_article.run_id
    end
    article_attrs = latest_article.attributes
    s_time = (s_time + 1.day).beginning_of_day
    while s_time < e_time do 
      additional_article = @thread.articles.build article_attrs.merge(:start_datetime => s_time,
                                                                      :end_datetime   => e_time,
                                                                      :is_news        => false,
                                                                      :banner_run_id  => latest_article.run_id) 
      additional_article.set_schedule_time_attrs
      additional_article.create_run!
      s_time += 1.day
    end     
  end
  
  def menu_name()
    result = "コミュニケーション：："
    @with_questionnaires and return result + "アンケート"
    result + 
      case @article_class
        when "就職サポート" then "就職サポート"
        when "提出書類"    then "提出書類"
        when "関連リンク"   then "関連リンク"
      else
        "一般メッセージ"
      end    
  end
  
  def header_local_info()
    @with_questionnaires and return Questionnaire_Header_Local_Info
    case @article_class
      when "就職サポート" then Career_Header_Local_Info
      when "提出書類"    then Form_Header_Local_Info
      when "関連リンク"   then Link_Header_Local_Info
    else
      Header_Local_Info
    end       
  end
    
end