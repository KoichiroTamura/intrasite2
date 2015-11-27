=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module GroupsHelper
        
  # popup showing of group detail
  # "group" is group entity; however if this is a number, it is regarded as id of Group.
  # "text" is text of link such as group.name or group.real_name; default is "group.real_name(group.name)"
  def group_detail_link(group, text = nil, options = {}, html_options = {})
    group?(group) or return "不明"
    
    text ||= "#{group.real_name}(#{group.name})"
    # popup is one of html options not options as RAIL API describes.
    html_opt = 
      if registered?  # current user is registered.
          html_options.merge(:popup => ["group_detail_link", "width=400, height=500, scrollbars= yes"])
      else
          html_options.merge(:onclick => "alert('グループ情報を見ることが出来るのはログインを行った登録ユーザのみです（セキュリティ規定参照のこと）．');", :href => "#")
      end
    call_for_detail(group, text, options, html_opt)
  end
  
  # check if "group" is a group.
  # caution: argument "group" would be changed.
  def group?(group)
    group.nil? || group.blank? and return false
    unless group.is_a?(Group)
      group = Group.find(group.to_i)
    end
    group.is_a?(Group)
  end

end