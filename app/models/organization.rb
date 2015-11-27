=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# organization units which have affiliation（所属), status（状態，地位など),title and post.
class Organization < Run
	set_table_name "organizations"
  
  # for select options of titles
  def self.all_titles
    find( :all, :distinct => "title").map(&:title).compact
  end
  
  # for select_options of posts
  def self.all_posts
    find( :all, :distinct => "post").map(&:post).compact
  end
  
  def org_affiliation
   assoc_dependee "Affiliation", "<< .affiliation_run_id :self", :assert_time => self.since
  end
  
  def org_status
   assoc_dependee "Status", "<< .status_run_id :self", :assert_time => self.since
  end

  def affiliation
    org_affiliation.blank? ? "" : org_affiliation.fullname
  end
  
  def status
    org_status.blank? ? "" : org_status.fullname
  end
  
  def affiliation_and_status
    affiliation + "　：　" + status
  end
  
  def lecture_class_name
    affiliation + " : " + status
  end
end
