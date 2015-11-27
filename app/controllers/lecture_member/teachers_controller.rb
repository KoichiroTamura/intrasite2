=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# for teachers of lecture

class LectureMember::TeachersController < RunsController

  def prepare_for_adding_assoc_target(assoc_target, pre_assoc_items)
    @academic_year = @background_params.to_h[:academic_year]
    @academic_season = @background_params.to_h[:academic_season]
    @default_since = beginning_of_academic_season
  end  
end