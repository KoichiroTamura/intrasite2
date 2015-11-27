=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module QuestionnairesHelper
     
  # render queationnaires(アンケート)
  def render_questionnaires(entity)
    questionnaires = entity.questionnaires
    questionnaires.blank? and return nil # do nothing

    render_collection_only  questionnaires,
                       :entity_template => "shared/entity_with_toggled_detail_call",
                       :div_id      => "questionnaires",
                       :working_div => "questionnaire_working_div",
                       :entity_locals => {:def_items   => @def_questionnaire_items,
                                          :list_items  => @questionnaire_list_items}
                       
  end
  
  # render new answer form template.
  # "form" is answer_responder form
  def render_answer_form(form, question_entity)
    prefix  = prefix_for_form(form) + "[answers]"
    answer  = form.object.build_answers  # answer belonging to answer_responder(form.object)
    answer.questionnaire_run_id = question_entity.run_id # answer also belongs to question_entity
    options = question_entity.options_from_question
    case question_entity.question_type
      when Questionnaire::Free_Form_Type
        render :partial => "answers/textarea_answering",
               :locals   => {:answer => answer, :prefix => prefix}
      when Questionnaire::Single_Choice_Type
       render :partial => "answers/radio_answering",
               :locals   => {:answer => answer, :prefix => prefix, :options => options}
      when Questionnaire::Multiple_Choice_Type
        render :partial => "answers/checkbox_answering",
               :locals   => {:answer => answer, :prefix => prefix, :options => options}
    end    
  end
  
  # render answer style for question_entity
  def render_answer_style(question_entity)
    # choice options
    options = question_entity.options_from_question
    case question_entity.question_type
      when Questionnaire::Free_Form_Type
        render :partial => "answers/textarea_style"
      when Questionnaire::Single_Choice_Type
       render :partial => "answers/radio_options",
               :locals   => {:options => options}
      when Questionnaire::Multiple_Choice_Type
        render :partial => "answers/checkbox_options",
               :locals   => {:options => options}
    end    
  end
  # display answer_entity to question_entity
  def render_answer_entity(answer_entity, question_entity)
    (answer = answer_entity.answer).blank? and return ""
    options = question_entity.options_from_question
    case question_entity.question_type
      when Questionnaire::Free_Form_Type
        answer
      when Questionnaire::Single_Choice_Type
        choiced = answer.to_i
        correct_answer = question_entity.correct_ans
        render :partial => "answers/radio_answer",
               :locals   => {:options => options, :choiced => choiced, :correct_answer => correct_answer}
      when "checkbox"
        choiced = answer_entity.multiple_choice_answers
        render :partial => "answers/checkbox_answer",
               :locals  => {:options => options, :choiced => choiced}
    end    
  end
  
  def change_checkbox_option(option_id, value_set_id)
    <<-CODE
     if (this.checked){
        $(#{value_set_id}).value += ' ' + #{option_id}
     }
     else{
        $(#{value_set_id}).value = $(#{value_set_id}).value.replace(/\s#{option_id}/, '')
     }
    CODE
  end
  
  # for answer stochastics
  def render_sum_up_answers(count_array = nil)
    count_array.blank? and return "．．．"
    render :partial => "answers/sum_up_answers", :locals => {:count_array => count_array}
  end

  def translate_question_type(question_type)
    Questionnaire::Question_Type_Meaning[question_type]
  end

end