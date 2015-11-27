=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

#  id              :integer(11)   not null, primary key
#  lecture_time_run_id   :integer(11)
#  space_run_id    :integer(11)
#  room_comment    :string(255)
#  year            :string(255)   
#  run_id          :integer(11)  
#  name            :string(255)   # room name
#  create_at       :datetime      
#  created_by      :integer(11)   
#  create_comment  :text          
#  delete_at       :datetime      
#  deleted_by      :integer(11)   
#  delete_comment  :text          

# necessary due to usage of multiple rooms for one lecture time
class LectureRoom < Run
  set_table_name "lecture_rooms"

end