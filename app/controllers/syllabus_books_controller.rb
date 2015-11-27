=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# for syllabus_books assoc_target

class SyllabusBooksController < SyllabusesController
    
  def prepare_for_adding_assoc_target(assoc_target, pre_assoc_items) 
    @def_syllabus_book_form_items = Def_Syllabus_Book_Form_Items
    @syllabus_book_form_items     = Syllabus_Book_Form_Items
  end
   
end