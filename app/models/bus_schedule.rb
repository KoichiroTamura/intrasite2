=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# == Schema Information
# Schema version: 70
#
# Table name: bus_schedules
#
#  id                  :integer(11)   not null, primary key
#  schedule            :string(255)   
#  diagram             :string(255)   
#  holiday             :string(255)   
#  year                :string(255)   
#  diagram_type_run_id :integer(11)   
#  run_id              :integer(11)   
#  create_at           :datetime      
#  created_by          :integer(11)   
#  create_comment      :text          
#  delete_at           :datetime      
#  deleted_by          :integer(11)   
#  delete_comment      :text          
#  version             :integer(11)   
#  count               :integer(11)   
#  since               :datetime      
#  till                :datetime      
#  parent_run_id       :integer(11)   
#  root_run_id         :integer(11)   
#  seq                 :string(255)   
#  full_seq            :text          
#  marged_from         :string(255)   
#  splitted_from       :string(255)   
#  data_type           :string(255)   
#  name                :string(255)   
#  fullname            :string(255)   
#

class BusSchedule < Run
  
  set_table_name "bus_schedules"
  
  # options for holiday( holiday or not)
  Is_Holiday = %w{off on}

  def modifier!
    self.year = Run.get_academic_year(since)
  end
end
