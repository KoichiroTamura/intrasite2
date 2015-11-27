=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# comments by lecture teachers

class ReportCommentsController < ReportsController
   
  protected
    
  def find_history
    @def_items  = Def_Report_Comment_Items
    @list_items = Base_History_Items
    @collection = @entity.history  
  end
  
  def find_detail
    @def_items = Def_Report_Comment_Items
    @detail_items = Report_Comment_Items
    @entity = find_entity :select => select_items(@def_items, @detail_items + [:id, :run_id])
  end
  
  def prepare_for_new
    preparation_for_altering
    @report = find_entity(params[:report])
    @report_comment = @entity = ReportComment.new_run
    @report_comment.build_report(@report)
    @report_comment.report_tennsaku = @report.body
  end
  
  def preparation_for_altering
    @def_form_items = Def_Report_Comment_Form_Items
    @form_items     = Report_Comment_Form_Items    
  end
	
end
