=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# for lecture_times

class LectureTimesController < RunsController

 def prepare_for_adding_assoc_target(new_lecture_time, pre_assoc_items)
    @def_lecture_time_form_items = CoursesController::Def_Lecture_Time_Form_Items
    @lecture_time_form_items     = CoursesController::Lecture_Time_Form_Items
    @academic_year = @background_params.to_h[:academic_year]
    @academic_season = @background_params.to_h[:academic_season]
    @default_since = beginning_of_academic_season
 end
end