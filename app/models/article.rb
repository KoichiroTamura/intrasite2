=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


class Article < Run
  set_table_name "articles"
  
  # article classes
  General_Class = "一般"
  Questionnaire_Class        = "アンケート設問"
  Questionnaire_Answer_Class = "アンケート回答"
  
  define_association :a_thread, :dependee, "ArticleThread", "<< :self",
                     :assert_time => :show_time
  
  define_association :to_individuals, :dependant, "ArticlePerson", ">> :self",
                     :assert_time => :show_time
  
  define_association :to_groups, :dependant, "ArticleGroup", ">> :self",
                     :assert_time => :show_time
                     
  define_association :to_orgs, :dependant, "Organization", ">> *organized_entity :self",
                     :assert_time => :show_time
  
  define_association :sender, :dependee, "UserInfo", "<- .created_by :self",
                     :assert_time => "#{Self_Entity}.created_at"
                     
  define_association :shared_place, :dependee, "Space", "<< .place_run_id :self",
                     :assert_time => "#{Self_Entity}.created_at"
  
  # for making response
  Destination_Assocs = [:to_individuals, :to_groups, :organizations]
  
  # answers for each answer response
  # CAUTION: foreign_key "parent_run_id" is temporal; should be right name as "answer_run_id"
  define_association :answers, :dependant, "Answer", ".parent_run_id >> :self",
                     :assert_time => "#{Self_Entity}.created_at",
                     :group => "answers.id"
  
  def sender?
    created_by == @@current_user.run_id
  end
  
  def responder(original_a_thread, responding_to)
    # set result to be an assoc'ed article of original a_thread.
    result = original_a_thread.articles.build self
    result.run_id = nil
    if responding_to == "ALL"
      # destinations of responder are the same as original article
      Destination_Assocs.each do |assoc_name|
        move_assocs assoc_name, result 
      end
    end
    # add sender to receivers if result.members do not include it.
    sender_included = result.to_individuals.detect do |mem| mem.user_info_run_id == sender.run_id end
    unless sender_included
      result.to_individuals.build(:user_info_run_id => sender.run_id)
    end
    # initial new content
    result.body = response_body()
    result
  end
  
  # destroy all schedule articles in banner
  def destroy_banner_schedules
    banner_run_id = self.banner_run_id.blank? and return # do nothing

    b_articles = self.class.find :all, :scope => :self,
                    :conditions => "banner_run_id = #{banner_run_id} AND id <> #{self.id}"
    b_articles.blank? and return 
    transaction do
      b_articles.each(&:destroy_run!)
    end
  end
  
  # questionnaire version of responder
  def answer_responder(original_a_thread)
    # set result to be an assoc'ed article of original a_thread.
    result = original_a_thread.articles.build self
    result.run_id = nil
    # destination of answer is only sender of original article.
    result.to_individuals.build(:user_info_run_id => sender.run_id)
    result.body          = Questionnaire_Answer_Class
    result.article_class = Questionnaire_Answer_Class
    result
  end
  
  def answer_response?
    article_class == Questionnaire_Answer_Class
  end
  
  # self is supposed to be a questionnaire article
  def answer_responses_with_answers(options={})
    associated_with "Article", "[(>> :ArticleThread << :self)(<< .parent_run_id :Answer >> :Questionnaire)]",
      options.merge(:conditions => "articles.article_class = '#{Questionnaire_Answer_Class}'")
  end
  
  # creater of original answer_response
  #   when evaluated answers, the answer_response created_by is changed to evaluater,
  #   so this methode is necessary
  def answerer
    original_answer_response = Article.find( self.run_id )
    UserInfo.find :first, :scope => :self, 
                  :assert_time => :show_time,
                  :conditions => "run_id = #{original_answer_response.created_by}"
  end
  
  def answers_sorted_by_question_no
    answers or return []
    answers.sort_by do |answer|
      answer.questionnaire.question_no
    end
  end
  
  def all_answers(options={})
    associated_with "Answer", ">> :Questionnaire >> *questionnairable :self",
                    options.merge(:assert_time => :show_time)
  end
 
  # attached star label which include "read"  and/or "star"
  # DO NOT use "define_association" since class varilables are included.
  def star_label
    assoc_targets = associated_with "Star", "[(-> :self)(-> :UserInfo)]", 
                                    :assert_time => @@show_time,
                                    :conditions => "#{@@current_user.run_id} = user_infos.run_id"
    assoc_targets.first
  end
  
  # has current_user read this aritcle(self) read ?
  def read?
    star_label.blank? and return false
    star_label.name_include?("read")
  end
  
  # make self have read
  def has_read!(since = @@show_time)
    original = star_label
    original.blank? and return Star.create_run!(:name => "read", :article_run_id => self.run_id, :user_info_run_id => @@current_user.run_id)
    original.add_name(since, "read")
  end
  
  def star?
    star_label.blank? and return false
    star_label.name_include?("star")
  end
  
  def attach_star(since = @@show_time)
    original = star_label
    original.blank? and return Star.create_run!(:name => "star", :article_run_id => self.run_id, :user_info_run_id => @@current_user.run_id)
    original.add_name(since, "star")
  end
  
  def remove_star(since = @@show_time)
    original = star_label
    original.blank? and return
    original.remove_name(since, "star")
  end
  
  def toggle_star(since = @@show_time)
    star? ? remove_star(since) : attach_star(since)
  end
  
  def groups(options = {})
    associated_with "Group", "<< :ArticleGroup >> :self", options
  end

  # virtual attribute for time_place settings
  def time_place_settings=(value)
    @time_place_settings = (value.to_i == 1)
  end
  
  def time_place_settings
    @time_place_settings
  end
  
  def time_including_setting=(value)
    @time_including_setting = (value.to_i == 1)
  end
  
  def time_including_setting
    @time_including_setting
  end
  
  # for displaying lecture time in schedule time table
  # "date" is datetime format
  def self.create_lecture_day_article(date)
    create_run! :title => "授業日",
               :article_class => "講義連絡",
               :is_news => 0,
               :is_general => 1,
               :start_date => new.date_format(date),
               :end_date => new.date_format(date),
               :start_time => "00:00:00",
               :end_time   => "23:59:59",
               :schedule_class => "授業日",
               :since => "2001-01-01 00:00:00",
               :till  => Run::Future_db,
               :forum_type => "Forum",
               :schedule_day_of_week => date.wday,
               :start_datetime => date.beginning_of_day,
               :end_datetime   => date.end_of_day,
               :season => get_academic_season(date)
  end
  
  # modify param_receiver in put.
  # self is supposed to be param_receiver
  def modifier!
    self.sender_name = @@current_user.real_name
    # for time_place settings
    if self.time_place_settings
      unless time_including_setting
        self.start_datetime, self.end_datetime = self.start_date.beginning_of_day, self.end_date.end_of_day
      end
      set_schedule_time_attrs
    else
      self.start_date = self.end_date = self.start_datetime = self.end_datetime = self.schedule_day_of_week = nil
    end
    
    # modify place_run_id from id
    place_id = self.place_run_id
    if place_id
      self.place_run_id = Space.find(place_id).run_id
    end

    if !self.questionnaires.blank?
      self.article_class = Questionnaire_Class
    end
  end
  
  def set_schedule_time_attrs
    if self.start_datetime > self.end_datetime
      # set force end time as start time
      self.end_datetime = self.start_datetime
    end

    s_time, e_time = self.start_datetime, self.end_datetime
    self.start_date, self.start_time = date_format(s_time), time_format(s_time)
    self.end_date,   self.end_time   = date_format(e_time), time_format(e_time)
    self.schedule_day_of_week        = s_time.wday 
  end
  
  def date_format(time)
    "#{time.year}-#{time.month}-#{time.day}"
  end
  
  def time_format(time)
    "#{time.hour}:#{time.min}:#{time.sec}"
  end
  
 protected
 
  def response_body
    (ApplicationController.helpers.content_tag :div do
       "#{created_at.year}/#{created_at.month}/#{created_at.day} #{sender.real_name}（#{sender.name}）" 
    end) +
    (ApplicationController.helpers.content_tag :blockquote do
        body
    end) +
   "<span></span>" 
  end
 
end
