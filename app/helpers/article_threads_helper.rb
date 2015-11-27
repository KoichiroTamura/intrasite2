=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module ArticleThreadsHelper
  # helpers for rendering article_threads view
  
  
  # labels attached to article_thread except "read" and "star"
  def normal_labels(article_thread)
    label_name = article_thread.label_name
    label_name.blank? and return ""
    (label_name.split(",") - ["read", "star"]).join(",")
  end
  
    
  def star?(article_thread)
    has_label?(article_thread.cumulative_star_label, "star")
  end

  
  def window_close_or_not
    if @display_mode == "schedules" 
      "window.close();"
    else
      "false;"
    end
  end
  
  def receive_mode_name(receive_mode_type)
    ArticleThreadsController::Receive_Mode_Names[receive_mode_type]
  end
  
  def submenu_class_name(receive_mode_type)
    @receive_mode == receive_mode_name(receive_mode_type) ? "current" : ""
  end

end