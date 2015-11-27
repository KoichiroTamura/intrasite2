=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# for homepage of intrasite2
class HomeController < MaintenanceInfosController

  skip_before_filter :login_required
  
  
  def allow_to_add_new_entity?(options = {})
    false
  end
      
end