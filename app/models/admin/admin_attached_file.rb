=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class Admin::AdminAttachedFile < ActiveRecord::Base
  set_table_name "attached_files" 

  def self.cleaner(times=86400)
    case ENV["RAILS_ENV"]
      when "development"
        if ENV["OS"] && ENV["OS"].include?("Windows")
          @UploadFileRoot="C:/windows/temp"
        else
          @UploadFileRoot="/tmp"
        end
      when "production"
        @UploadFileRoot = "#{RAILS_ROOT}/data"
    end

    rds = self.find(:all,:conditions=>["(file_attachable_type IS NULL OR file_attachable_run_id IS NULL) and created_at<=?",Time.now.ago(times)])
    rds.each do |rd|
      begin
        File.unlink("#{@UploadFileRoot}/#{rd.directory}/#{rd.filename}")
      rescue
      end
      
      begin
        rd.destroy
      rescue
      end
    end
  end

end