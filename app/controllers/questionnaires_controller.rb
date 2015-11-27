=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# questions for questionnaires（アンケート調査）

class QuestionnairesController < RunsController
    
  # questionnaire items
  Def_Items = item_struct( "Questionnaire", [:id, "", ".id"],  [:run_id, "", ".run_id"],
                      [:question,        "問", ".question"],
                      [:question_type,   "解凍形式", ".question_type"],
                      [:necessary,    "必須？",    ".necessary"],
                      [:question_no,    "番号" ,  ".question_no"],
                      [:option_count,    "選択数",     ".option_count"],
                      [:correct_ans, "正答番号",  ".correct_ans"],
                      [:correct_answer_point, "点数",  ".correnct_answer_point"],                      
                      *Base_Def_History_Items )
                        
  List_Items =  [:question_no, :question_type, :question]
  Sender_List_Items = List_Items + [:correct_ans, :correct_answer_point]
                

  # for responding to call by corner menu "アンケート"  
  def index
    if params[:article].blank?
      # called from corner menu
      redirect_to :controller => "/article_threads",
                  :params     => {:only_with_questionnaires => true,
                                 :menu_name1 => params[:menu_name1]}
     else
       super
     end    
  end  
  
  private
  
  def find_detail
    @def_items = Def_Items
    @detail_items = List_Items
  end
                   
end