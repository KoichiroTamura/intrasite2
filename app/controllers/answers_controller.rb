=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


class AnswersController < RunsController
  
  Def_Question_Wise_Items    = item_struct "Questionnaire",  [:id, "",     ".id"], [:run_id, "", ".run_id"],
              [:question_no, "問", ".question_no"],
              [:question_type, "回答方式", ".question_type", :translate_question_type],
              [:question_option_count, "選択肢数", ".option_count"],
              [:sum_up_answers, "回答要約", :sum_up_answers, :render_sum_up_answers], # for each questions
              [:no_of_answers,  "回答数", "COUNT(answers.run_id)"],
              [:answer_point_average, "得点平均", "AVG(answers.point)", [:formatting_float_number, "%.1f"]]
  Qustion_Wise_Items         = [:question_no, :question_type, :no_of_answers, :sum_up_answers, :answer_point_average]

  Def_Answer_Response_Wise_Items = item_struct "Article",  [:id, "",     ".id"],
              [:run_id, "", ".run_id"],
              [:answerer, "回答者",    :answerer, :user_info_detail_link],
              [:send_time, "回答時", ".created_at", :time_in_japanese_style],
              [:answer_point_sum, "総得点", "SUM(answers.point)"],
              [:answer_point_average, "得点平均", "AVG(answers.point)", [:formatting_float_number, "%.1f"]]
  Answer_Response_Wise_Items = [:answerer, :send_time, :answer_point_sum, :answer_point_average]
    
  def stochastics
    @entity = find_entity  # questionnairable entity
                                                  
    @def_question_wise_items   = Def_Question_Wise_Items
    @question_wise_items       = Qustion_Wise_Items
    @question_wise_stochastics = @entity.questionnaires :group => "questionnaires.question_no",
                                              :select => select_items(@def_question_wise_items, @question_wise_items + [:run_id]),
                                              :assert_time => :show_time
                                                       
    @def_answer_response_wise_items   = Def_Answer_Response_Wise_Items
    @answer_response_wise_items       = Answer_Response_Wise_Items
    @answer_response_wise_stochastics = @entity.answer_responses_with_answers :group => "articles.id",
                                               :select => select_items(@def_answer_response_wise_items, @answer_response_wise_items + [:id, :run_id]),
                                               :assert_time => :show_time
                                               
    render :partial => "stochastics", :layout => "base_layout"
  end

  protected

end