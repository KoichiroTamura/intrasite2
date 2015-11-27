=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module UserRegistHelper
  def render_name_help_field
    '<span id="user_name_scanner_result"></span>'
  end
  
  def render_name_helper
    '<div id="user_name_scanner"></div>' + 
    javascript_tag do 
      "NameUse('"+url_for(:action=>"scan_name")+"');"
    end
  end
end