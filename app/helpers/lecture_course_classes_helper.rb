=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module LectureCourseClassesHelper
  # helpers for rendering lecture_course_classes in updating course
  
  def render_lecture_course_classes(prefix, div_class_name, cc_run_id, org_names, candidate, checked)
     prefix_for_candidate = prefix + "[#{candidate.to_param}]"
     # name and value for checkbox tag below
     name  = prefix_for_candidate + "[course_class_run_id]"
     value = cc_run_id  # mark to show not deleted
  
     content_tag( :div, :class => div_class_name) do
        check_box_tag( name, value, checked) +  label_tag( name, org_names)
     end +
     hidden_field_tag( prefix_for_candidate + "[since]", @default_since.to_s(:db))
  end

end