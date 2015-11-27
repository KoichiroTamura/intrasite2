=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module AttachedFilesHelper
  # helpers for rendering attached_files
  
  def add_attached_file_link(name, options = {})
    link_to_remote_with_params name,
                 :url => {:action => :adding_assoc_target},
                 :params => {:base_div_id => :attached_files,
                             :model_name => "AttachedFile",
                             :template => "attached_files/input/attached_file",
                             :options => options }
  end 
  
  def attached_file_link(attached_file)
    attached_file.original_name and link_to attached_file.original_name,:controller=>"/attached_files", :action=>"show", :id=>attached_file.checksum
  end
end