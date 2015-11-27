=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# for menus

class MenusController < CornersController
  
  private
  
  def prepare_for_adding_assoc_target(assoc_target, pre_assoc_items)
    @def_menu_form_items = Def_Form_Items
    @menu_form_items     = Menu_Form_Items
  end
  
end