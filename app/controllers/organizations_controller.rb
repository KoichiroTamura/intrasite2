=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# for organizations

class OrganizationsController < RunsController
  
  def prepare_for_adding_assoc_target(organization, pre_assoc_items) 
    # set default affiliation and status when no designation given.
    organization.affiliation_run_id.blank? and organization.affiliation_run_id = Affiliation.tree_root.run_id
    organization.status_run_id.blank? and organization.status_run_id = Status.tree_root.run_id
  end
end