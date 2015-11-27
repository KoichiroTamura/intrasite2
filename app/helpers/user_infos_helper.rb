=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module UserInfosHelper
  # popup showing of user info detail
  # "user" is user_info entity; however if this is a number, it is regarded as id of UserInfo.
  # "text" is text of link such as user.name or user.real_name; default is "user.real_name(user.name)"
  
  # parameters of popup window to show user_info detail
  UserInfo_Popup_Params = "user_info_detail_page, width=620, height=600, scrollbars=1, location=0"

  def user_info_detail_link(user, text = nil, options = {}, html_options = {})
    user?(user) or return "不明"
    
    text ||= "#{user.real_name}(#{user.name})"    
    
    # popup is one of html options not options as RAIL API describes.
    html_opt = 
      if registered?
          html_options.merge(:popup => [UserInfo_Popup_Params])
      else
          html_options.merge(:onclick => "alert('ユーザ情報を見ることが出来るのは，ログインを行った登録ユーザのみです（セキュリティ規定参照のこと）');", :href => "#")
      end
    call_for_detail(user, text, options, html_opt)
  end
  
  # check if "user" is user?
  # caution: argument "user" would be changed.
  def user?(user)
    user.blank? and return false
    unless user.is_a?(UserInfo) # user is supposed to be given by its id.
      user = UserInfo.find(user.to_i)
    end
    user.is_a?(UserInfo)    
  end
  
  def render_members_detail_links(members, text = nil, options = {}, html_options = {})
    members.blank? and return ""
    seperator = options[:seperater] || "<br />"
    members.map do |member| user_info_detail_link(member.user, text, options, html_options) end.join(seperator)
  end
  
  def user_info_detail_by_run_id(user_run_id, text=nil, options = {}, html_options = {})
    user_run_id.blank?  and return "無記入"
    user = UserInfo.current_state( user_run_id, options )
    user_info_detail_link(user, text, options, html_options)
  end
  
end