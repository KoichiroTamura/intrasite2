=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


class GroupsController < RunsController
  
  Def_Items = self.item_struct  "Group", [:id,        "",         ".id"], [:run_id, "", ".run_id"],
                                [:real_name, "グループ名", ".real_name"],
                                [:name, "グループコード名", ".name"],
                                [:role, "種別", ".role"],
                                [:email, "Eメール", ".email"],
                                [:url,      "URL", ".url"],
                                [:room_no, "部屋番号", ".room_no"],
                                [:room_phone, "TEL", ".room_phone"],
                                [:group_members, "メンバー", :group_members, "members/entity"],
                                [:organizations, "所属とステータス", :organizations],
                                [:attached_files, "添付ファイル", :attached_files],
                                *(Base_Def_History_Items + Base_Def_Altering_Items)
                                
  History_Items = [:real_name, :name] + Base_History_Items
                                
  Detail_Items = [:real_name, :name, :organizations, :role, :email, :url, :group_members, :attached_files]
  
                               
  Def_Form_Items = form_item_struct Def_Items,                       
                             [:real_name, nil, nil , [:required => true]],
                             [:name, nil, nil, [:required => true]],
                             [:role],
                             [:email],
                             [:url],
                             [:room_no],
                             [:room_phone],
                             [:attached_files, nil, :render_association_to_put, [{:legend => "添付ファイル", :entity_template => "attached_files/input/collection"}]],                    
                             [:organizations, nil, :render_association_to_put],
                             [:group_members, nil, :render_association_to_put, [{:entity_template => "members/input/member", :show_items => [:member_role]}]],
                             Def_Since_Form_Item
                             
  Form_Items_For_Admin = [:since, :real_name, :name, :role, :email, :url, :organizations, :group_members, :attached_files]
  Form_Items_For_User  = [:since, :real_name, :name, :email,:url,:room_no,:room_phone, :organizations, :group_members, :attached_files]
  
  def allow_to_add_new_entity?(opts = {})
    admin?  # for the moment... deliberate in the future
  end

  protected

    
  def find_collection  
    @def_items = Def_Items
    @list_items = [:real_name, :name, :role]
    @queries = [:real_name]
    
    @affiliation = params[:affiliation] || Group::Affiliation_Default
    @status      = params[:status]      || Group::Status_Default
    
    @collection = Group.find :all, 
       :page       => current_page,
       :scope      => a_net,
       :distinct   => select_items(@def_items, @list_items + [:id, :run_id]),
       :conditions => query_cond,
       :order      => "name"
    @entity_template = "shared/entity_with_remote_detail_call"
    @view_allowed = [:adding_new_call,:detail_call]
    flash_now @collection.blank?, "該当グループはありません．"
  end
  
  def find_detail
    @def_items    =  Def_Items
    @detail_items =  Detail_Items
    admin? and @detail_items += Base_Altering_Items
  end
  
  def find_history
    @def_items = Def_Items
    @list_items = History_Items
    @collection = @entity.history :distinct => select_items
  end
  
  
  def a_net
    ":self" + organization_net("", "aff", "sta")
  end
  
  def query_cond
    merge_conditions(query_conditions(params[:query], *query_from_items),
                     tree_condition(@affiliation, "aff"), 
                     tree_condition(@status, "sta"))
  end  

  #--
  # altering

  # creating user_info                  
  def prepare_for_new
    @group = @entity = Group.new_run(:role => "委員会")
    @group.organizations.build
    @group.group_members.build
    preparation_for_altering
  end

  
  def prepare_for_updating
    @group = @entity
    # default value for "since" of update
    @group.since = @action_time
    preparation_for_altering
  end
  
  def preparation_for_altering
    @def_form_items = Def_Form_Items
    @form_items     = (admin? ? Form_Items_For_Admin : Form_Items_For_User)
  end  
  
  def prepare_for_destroying
    @time_to_delete = end_of_academic_year
  end
 
end