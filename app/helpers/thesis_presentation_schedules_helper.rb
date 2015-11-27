=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module ThesisPresentationSchedulesHelper
  
  def link_to_thesis_presentation(entity)
    link_to "発表論文", theses_path(:presentation_entity => entity.run_id,
                           :thesis_status => entity.thesis_degree,
                           :academic_year => entity.academic_year)
  end
end