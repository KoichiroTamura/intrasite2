=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class MailTosController < RunsController

  Def_Items = item_struct( "MailTo", [:id, "", ".id"],  [:run_id, "", ".run_id"],
                      [:to_type,   "種別",  :from, ".to_type"],
                      [:mailaddress,  "メールアドレス", ".mailadress"],
                      *Base_Def_History_Items )
                        
  Def_Form_Items = form_item_struct Def_Items,
                   [:to_type, nil,  :radio_button_selection, [["To","To"],
                                                                  ["Cc","Cc"],
                                                                  ["Bcc","Bcc"]
                                                              ]],
                   [:mailaddress, nil, :text_field]
              
  Form_Items = [:to_type,:mailaddress ]

  
  def prepare_for_adding_assoc_target(assoc_target, pre_assoc_items)
    @def_mailto_form_items = Def_Form_Items
    @mailto_form_items     = Form_Items
  end
  

end