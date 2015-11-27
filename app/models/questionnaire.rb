=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# アンケート処理

class Questionnaire < Run            
	set_table_name "questionnaires"
  
  Free_Form_Type       = "textarea"
  Single_Choice_Type   = "radio"
  Multiple_Choice_Type = "checkbox"
  
  Question_Type_Meaning = {Free_Form_Type       => "自由記述",
                           Single_Choice_Type   => "単一選択",
                           Multiple_Choice_Type => "複数選択"}

  define_association :answers, :dependant,
                     "Answer", ">> :self",
                     :assert_time => :show_time
                     
  attr_accessor :option_text  # virtual attribute for choice option of multiple choice questions
  
  Separator_Of_Question_And_Options = '<br /><!--***choice options***--><br />'
  Separator_Of_Options              = '<!--***choice option***--><br />'
  
  # rearrange question content to be answered
  def modifier!
    new_record? or return # do nothing when making answer template.
    question or return    # do nothing when receiving answers.
    
    if question_type.blank?
      errors.add "question_type", "回答方式が与えられていません．選んでください．"
    else
      question_content = question + Separator_Of_Question_And_Options;
      if (question_type == 'textarea')
        question_content += '' ;
      else
        if option_text.blank?
          errors.add "option_text", "選択肢がありません．｢選択肢の追加」により作成してください"
        else
          question_content += option_text.join(Separator_Of_Options)
          self.option_count = option_text.size
        end
      end
    end
    errors.empty? or fail ActiveRecord::RecordInvalid.new(self)
    self.question = question_content;
  end
  
  # separatote options from question
  def question_content
    question.blank? and return ''
    question.split(Separator_Of_Question_And_Options).first
  end
  
  # take options from question
  def options_from_question
    question.blank? and return ''
    option_part = question.split(Separator_Of_Question_And_Options).last
    option_part.blank? and return ''
    option_part.split(Separator_Of_Options)
  end
  
  # for questionnaire wise stochastics
  # return count array of selected choices
  def sum_up_answers
    (no_of_answers = answers.size) <= 0 and return []
    case question_type
    when Free_Form_Type
      []
    when Single_Choice_Type
      count_array = answers.inject([]) do |sum, a|
        unless a.answer.blank?
          index = a.answer.to_i - 1
          sum[index].nil? ? sum[index] = 1 : sum[index] += 1
        end
        sum
      end
      count_array.map do |count|
        count ||= 0
        count * 100.0 / no_of_answers
      end
    when Multiple_Choice_Type
      count_array = answers.inject([]) do |sum, a|
        unless a.answer.blank?
          answer_series = a.multiple_choice_answers
          answer_series.each do |ans_value|
            index = ans_value - 1 
            sum[index].nil? ? sum[index] = 1 :sum[index] += 1
          end
        end
        sum
      end
      count_array.map do |count|
        count ||= 0
        count * 100.0 / no_of_answers
      end
    end    
  end
end
