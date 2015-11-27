=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end



class CourseClass < Run
	set_table_name "course_classes"
  
  # abreviated notation for course_classes
  def org_name_and_self_id
    orgs = organizations
    orgs.blank? and return "", ""
    org_names = 
      orgs.inject([]) do |sum, org|
        name = org.org_affiliation.name 
        status = org.org_status.name
        status == "学部生" || status == "院生" or name += "（#{status}）"
        party.blank?  or name += "：#{party}"
        sum << name
      end
    return org_names.join(' ; '), run_id
  end

end
