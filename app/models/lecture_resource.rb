=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# == Schema Information
# Schema version: 70
#
# Table name: course_resources
#
#  id              :integer(11)   not null, primary key
#  _old_subject_id :string(255)   
#  _old_class_id   :string(255)   
#  lecture_run_id  :integer(11)  
#  _old_youbi      :string(255)   
#  youbi           :integer(11)  # CAUTION: rename to day_of_week 
#  _old_jikan      :string(255)  
#  jikan           :integer(11)  # CAUTION: rename to lecture_time 
#  _old_roon       :string(255)   
#  room            :string(255)   
#  year            :string(255)   
#  run_id          :integer(11)   
#  create_at       :datetime      
#  created_by      :integer(11)   
#  create_comment  :text          
#  delete_at       :datetime      
#  deleted_by      :integer(11)   
#  delete_comment  :text          
#  version         :integer(11)   
#  count           :integer(11)   
#  since           :datetime      
#  till            :datetime      
#  parent_run_id   :integer(11)   
#  root_run_id     :integer(11)   
#  seq             :string(255)   
#  full_seq        :text          
#  marged_from     :string(255)   
#  splitted_from   :string(255)   
#  data_type       :string(255)   
#  name            :string(255)   
#  fullname        :string(255)   
#

class LectureResource < Run              # CAUTION; 2008/10/29  名前変更
	set_table_name "lecture_resources"

end
