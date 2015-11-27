=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module LecturesHelper
  
  def render_lecture_times(lecture_times, options = {})
    content_tag :table do
      render :partial => "lecture_times/entity", :collection => lecture_times, :locals => {:options => options}
    end
  end
  
  def member_of_teachers?(lecture)
    admin? || (@current_user && lecture.teachers.map(&:run_id).include?(@current_user.run_id))
  end
  
  def link_to_lecture_forum(lecture)    
    link_to "授業フォーラム",
      {:controller=>"/article_threads",
      :forum  =>  lecture,
      :article_class => "授業メッセージ",
      :academic_year => @academic_year, 
      :academic_season => @academic_season,
      :menu_name1=>"授業フォーラム:#{@entity.name}" },
      :target => "_new"
  end
  
  def link_to_exercise(lecture)
    link_to "レポート課題",
      {:controller=>"/exercises",
      :lecture => lecture,
      :all_or_related=>"all",
      :academic_year => @academic_year, 
      :academic_season => @academic_season,
      :menu_name1=>"レポート課題:#{@entity.name}"   },  
      :target => "_new"
  end
  
  def link_to_lecture_schedule(lecture)
    link_to "授業スケジュール",
      {:controller=>"/schedules",
      :forum     => lecture,
      :article_class => "授業メッセージ",
      :academic_year   => @academic_year, 
      :academic_season => @academic_season,
      :menu_name1=>"授業スケジュール:#{@entity.name}"},
      :target => "_new"     
  end
end