=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# Do not use "Thread" as class name, which causes crashing against the ruby original one.

# threads of articles
 class ArticleThread < Run
  
  set_table_name "threads"
  
  # check_box parameter receiver
  attr_accessor :check_box_flag
  
  validates_presence_of :title, :message => "必ず記入してください．"
  
  define_association :articles, :dependant, "Article" , ">> :self", 
                     :assert_time =>  :show_time,
                     :order => "articles.id"
  
  define_association :personal_settings, :dependant,
                     "PersonalSetting", "[(-> :self)(-> :UserInfo)", 
                     :assert_time =>  :show_time
                     
  def latest_article
    Article.find latest_article_id, 
        :scope  => ":Article ~<- star_label_set:Star >>~ :UserInfo .run_id = {#{@@current_user.run_id}",
        :select => {:id => "articles.id", :run_id => "articles.run_id",
                    :sender_name => "articles.sender_name", 
                    :title => "articles.title",
                    :body => "articles.body",
                    :star_label_set => "star_label_set.name",
                    :created_at => "articles.created_at"}
  end
  
  def star?
    cumulative_star_label && cumulative_star_label.name_include?("star")
  end
  
  def add_label(label)
    original = personal_settings(:conditions => "user_info_run_id = #{@@current_user.run_id}").first
    original.blank? and return PersonalSetting.create_run!(:name => label, :thread_run_id => self.run_id, :user_info_run_id => @@current_user.run_id)
    original.add_name(@@show_time, label)
  end
  
  def remove_label(label)
    original = personal_settings(:conditions => "user_info_run_id = #{@@current_user.run_id}").first
    original.blank? and return
    original.remove_name(@@show_time, label)
  end
  
  def questionnaire_article
    articles(:conditions => "articles.article_class = '#{Article::Questionnaire_Class}'").first
  end
  
  def questionnaires
    questionnaire_article.questionnaires
  end
  
  
  # modify param_receiver in put.
  # self is supposed to be param_receiver
  def modifier!
    article_assoc = self._assoc_dependant.detect do |assoc| assoc.target_model.name == "Article" end
    new_article_ref = article_assoc.last.to_entity_ref
    new_title   = (new_article_ref.content["title"] || "")
    self.title = new_title
    self
  end  
  
  private
    
    
 end