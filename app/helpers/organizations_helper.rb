=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module OrganizationsHelper
    
  # render hierarchy of organization
  # options
  #   :without : items to be excluded from listing.
  def hierarchy_style(org, options = {})
    out = (options[:without] || []) + %w{全員 ステータス}
    items = org.split(Run::Level_Separator) - out
    items.blank? ?  "すべて" :  items.join("　")
  end
end