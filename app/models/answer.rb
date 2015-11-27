=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# answers for questionnaire
class Answer < Run
	set_table_name "answers"
  
  define_association :questionnaire, :dependee,
                     "Questionnaire", "<< :self",
                     :assert_time => :show_time
                     
  define_association :answer_response, :dependee,
                     "Answer", " << .parent_run_id",  # the foreign key name is temporal; should be changed to "article_run_id".
                     :assert_time => :show_time
                     
  def question
    questionnaire.question
  end
  
  # "created_by" is changed when evaluated by someone else, so do not use it as answered_by
  def answered_by
    answer_response.answerer
  end
  
  # get array of answers from multiple choice type question's answer string.
  def multiple_choice_answers
    answer.blank? and return []
    answer.strip.split(/\s+/).map(&:to_i).compact
  end

end
