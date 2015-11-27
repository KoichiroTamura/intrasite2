=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# for Run controllers

class RunsController < ApplicationController
    
  require "uuidtools"

  attr_accessor :simulation_mode
   
  before_filter :login_required
 
  # set whole system situation 
  #   action, show and assert_time (as defaults)
  #   current account and user
  #   available corner menu (rendered in layout) at show_time for current account
  before_filter :set_system_situation, :except => [:show_show_time, :change_show_time, :change_show_time_to_current]
  
  before_filter :set_menu_name
  
  # actions to preparing commitment to the system
  Committing_Actions = [:new, :edit, :updating, :correcting, :destroying]
  
  # actions to execute commitment
  Commitment_Actions = [:create, :update, :correct, :destroy, :universal_put]
  
  # actions allowed only for owner(creater) or admin
  Owner_Only_Actions = Committing_Actions - [:new]
  
  # actions to get entities
  Get_Actions = [:index, :search, :show, :history]
  
  # actions to designated entity
  To_Entity_Actions  = [:show, :history] + Owner_Only_Actions  
  
  # self entity name in Run#association's assoc_net
  Self_Entity = Run::Self_Entity
  
  # set @background_params to move and keep environmental settings to client's view documents.
  before_filter :set_background_params, :only => [:index, :search, :history]
  
  # receive and set @background_params to each action to entity.
  before_filter :receive_and_set_background_params, :only => [:show] + Committing_Actions + Commitment_Actions + [:adding_assoc_target]
  
  # find entity object from params[:id] and set it as @entity
  before_filter :find_entity, :only => To_Entity_Actions

  # allow logined user except guest to do committing and commit actions
  before_filter :registered_only, :only => Committing_Actions + Commitment_Actions
  
  # only owner(or admin) can change entity objects.
  before_filter :owner_only, :only => Owner_Only_Actions

  # number of entities for one page of pagination as default
  Default_Paginating_Size = 25
  
  # base of definition items for history
  Base_Def_History_Items = [
      [:since,        "〜から",   ".since",      [:time_in_japanese_style, :since]],
      [:till,         "〜まで",   ".till",       [:time_in_japanese_style, :till]],
      [:created_at,   "記録日時",   ".created_at", [:time_in_japanese_style, :since]],
      [:deleted_at,   "削除日時",   ".deleted_at", [:time_in_japanese_style, :till]]]
      
      
  Def_Since_Form_Item = [:since, nil, :datetime_select_for_since]
  Def_Till_Form_Item  = [:till, nil,  :datetime_select_for_till]
                             
  Form_Deleting_Items = [:since, :deleted_by]
  
  Def_Attached_File_Form_Item = [:attached_files, nil, :render_association_to_put, 
                                 [{:legend => "添付ファイル", :entity_template => "attached_files/input/collection"}]]
      
  # base of history items
  Base_History_Items = [:since, :till, :created_at]
  
  # base of definition of altering link items
  #  correcting is suspended.
  Base_Def_Altering_Items = [
#      [:correcting,   "",        :self,     :link_to_correcting],  # for correcting state in history
      [:updating,     "",        :self,     :link_to_updating],
      [:deleting,     "",        :self,     :link_to_deleting]]
  
  # base of altering link items
  # :correcting is suspended.
  Base_Altering_Items = [:updating, :deleting]
  
  #-- GET actions
  
  def index
    catch :flash_now do 
      find_collection 
    end
    if layout = params[:layout] 
      render :layout => layout
    end
  end
  
  # standard ajax version to retrieved entities
  def search
    @list_action = true
    render_response("shared/collection") do find_collection end
  end
  
  # to respond to "(remote_)call_for_detail request to show entity detail.
  def show
    if params && params[:mode] == "history"  # see detail of each history state in span
      span = @entity.since..@entity.till  # global assert time for each state of history as its since time
      set_global_assert_time(span) do 
        render_response("detail") do find_detail end          
      end
    else  # see detail at current time
      render_response("detail") do find_detail end
    end
  end

  # to respond to "(remote_)call_for_history request to show entity history.
  # obtained history is located in "working_div".
  def history
    @list_action = true
    render_response("shared/history/run_history", "working_div") do find_history end
  end
  
  #-- end of GET actions

  #-- COMMIT actions 
  
  # root attribute to show an entity of universe of discourse.
  Universal_Attribute = "_universal_attribute_"
  
  # for creating
  def new
    committing("新規作成","new") do prepare_for_new end
  end
  
  def create
    commit("新規作成") do put end
  end
  
  def edit
    updating
  end
  
  # Rails' "edit" action
  def updating
    committing("更新", "new") do prepare_for_updating end
  end
  
  def update
    commit("更新") do put end
  end
  
  def correcting
    committing("訂正", "shared/correcting") do prepare_for_correcting end
  end
  
  def correct
    commit("訂正") do put end
  end
  
  def destroying
    committing("削除", "shared/deleting") do prepare_for_destroying end
  end
  
  def destroy
    commit("削除") do put end
  end
  
  def universal_put
    p = params[Universal_Attribute]
    params_for_entities = case p
      when Hash
        [p]
      when Array
        p
      else
        fail "#{p} should be Hash or Array of Hash as Universal_Attribute."
    end
    params_for_entities.each do |params_for_entity|
      commit("実行") do put(params_for_entity) end
    end 
  end

  #-- end of COMMIT actions
 
  # called by observe_field of tree selection when tree selection is done and value of hidden field changed.
  # "selected_entity" is name of field to have value(=designified node id).
  def update_tree_select
    tree_select_div_id = params[:tree_select_div_id]
    root = Run.find_entity params[:locals][:root]
    selected_entity = Run.find_entity(params[:selected_entity])
    assert_time = transform_time_param_to_db_time(params[:locals][:assert_time])
    set_global_assert_time(assert_time)
    render :update do |page|
      page.replace_html tree_select_div_id,
         :partial => "shared/tree/selection",
         :locals  => params[:locals].merge(:root => root, :pre_selection => selected_entity)
    end
  end
  
  #-- show time actions
  
  # for showing show_time periodically
  def show_show_time
    render :partial => "layouts/show_show_time"
  end

  # changing show time situation and/or simulation mode
  def change_show_time
    session[:show_time_base]     = params[:show_time_base] ? time_from_date_params(params[:show_time_base]).to_s(:db) : nil
    session[:base_setting_time]  = session[:show_time_base] ? @real_time.to_s(:db) : nil
    session[:show_time_rate]     = params[:show_time_rate] ? params[:show_time_rate].to_i : 1  
    session[:show_time_mode]  = 
      session[:show_time_base].nil? ? 0 : ( session[:show_time_base] <= session[:base_setting_time]  ? -1 : 1 )
    session[:simulation_mode] = params[:simulation_mode] ? true : nil
    # redo setting system_situation under this artifact situation
    set_system_situation
  end
  
  # back to normal situation
  def change_show_time_to_current
    # reset artifact situation
    session[:show_time_base]  = nil
    session[:base_setting_time]  = nil
    session[:show_time_rate]  = nil
    session[:show_time_mode]  = nil
    session[:simulation_mode] = nil
    # redo setting system situation to be normal.
    set_system_situation
  end
  
  def simulation_mode=(boolian)
    @simulation_mode = Run.simulation_mode = boolian
  end
  
  # mode = -1 if past; 0 if present; 1 if future.
  def show_time_mode=(mode)
    @show_time_mode = mode
  end
  
  def at_present?
    @show_time_mode == 0
  end
  
  def simulation_mode?
    @simulation_mode
  end
  
  def commit_allowed?(entity = @entity)
    (admin_or_owner_of?(entity))   # modified to allow do in past or future　2013/03/19
  end
     
  # set global assert time while doing procedure.
  def set_global_assert_time(time=@show_time, &block)
    # temporal saving of assert_time
    temp_assert_time = Run.get_assert_time
    self.assert_time = time
    if block_given?
      yield
      # recover assert_time
      self.assert_time = temp_assert_time
    end
  end 
   
  #-- end of show time actions
       
  # finding corner menu clusters at show_time(= assert time)
  # result structure is ...
  #    [ [corner_root, its_menus], [next_corner_root, its_menus], ...]
  def find_menu_clusters
    cond = @current_account ? "role LIKE '%#{current_account.role}%'" : " role LIKE '%guest%' AND logined=0"   
    menus= Corner.find :all, :assert_time => @show_time, :scope => ":self", :conditions => cond
    corner_roots = menus.select do |m| m.parent_run_id == 0  || m.parent_run_id.nil? end
    @menu_clusters = corner_roots.map do |root|
      children = (menus.select do |m| m.parent_run_id == root.run_id end).sort_by(&:seq)
      [root, *children]
    end
  end

  
  def admin?
    @current_account && @current_account.role == "admin"
  end
  
  def test_user?
    @current_account && @current_account.role == "test"
  end
  
  def teacher?
    @current_user && @current_user.category == "教職員"
  end
  
  def student?
    graduate_student? || undergraduate_student?
  end
  
  def graduate_student?
    @current_user && @current_user.category == "院生"
  end
  
  def undergraduate_student?
    @current_user && @current_user.category == "学部生"
  end
  
  def public_user?
    @current_user && @current_user.category == "公開ユーザ"
  end
  
  def guest?
    @current_account && @current_account.role == "guest"
  end
  
  def guest_only
    render_flash_now_if(!guest?, "ゲストユーザのみ利用できます．")
  end
  
  def owner_of?(entity = @entity)
    entity or return false
    owner_run_id = entity.attribute_present?("created_by") ? entity.created_by : Run.find_entity(entity.to_param).created_by
    @current_user && @current_user.run_id == owner_run_id
  end
  
  def admin_or_owner_of?(entity = @entity)
    admin? || owner_of?(entity)
  end
  
  # current_account logged in? and not "guest"(not anonymouse) ?
  def registered?
    @current_account && @current_account.role != "guest"
  end
  
  # condition to allow to set simulation mode
  def allow_simulation_mode?
    admin? || test_user? || teacher?
  end
  
  def allow_to_change_show_time?
    (admin? || test_user? || teacher?) && at_present?
  end
  
  # get current_user info as member attribute
  def current_user_member_attributes(member_type)
    {:user_info_run_id => @current_user.run_id, :type => member_type}
  end  
  
  # find entity object and set as @entity
  def find_entity(*args)
    # special case for current_user
    (@current_user && params["id"] && params["id"].to_s == "0") and return @entity = @current_user
    
    # entity_id is in the form "id:Model"
    if args.blank? || args.first.is_a?(Hash)   # default case to follow show action
      entity_id = (@entity_id  || params[:id])
    else
      entity_id = args.shift                   # entity_id explicitly given
    end 
    @entity = Run.find_entity(entity_id, *args)
  end
  
  def find_by_entity_ref(default_since = nil, hash = params["entity_ref"])
    entity_ref = hash.to_h.to_entity_ref
    entity_ref.to_entity(default_since)
  end
                  
  # adding new assoced member with its template to input
  def adding_assoc_target
    params.symbolize_keys!
    controller = params[:controller]
    prefix            = params[:prefix]
    base_div_id       = params[:base_div_id]    # id of div to add
    template          = params[:template]     # assoc'ed entity template to add
    options           = params[:options].to_h
    single            = options[:single] ? 'yes' : 'no'
    uuid              = random_id  # generate random id (should be unique).
   
    # recover association from params[:prefix]
    pre_assoc_items    = pre_assoc_items_from_prefix(prefix)
    assoc_entity_name  = pre_assoc_items[-2]
    assoc_name         = pre_assoc_items[-1]
    assoc_entity       = find_entity(assoc_entity_name)
    @root_entity_since = assoc_entity.since || @show_time
    assoc              = assoc_entity.send(assoc_name)
    assoc_target_type  = assoc.assoc_target_type
    assoc_target       = assoc_target_type == :dependee ? assoc_entity.send("build_#{assoc_name}") : assoc.build(Run::Since => @root_entity_since)

    # prepare for adding new assoc_target.
    prepare_for_adding_assoc_target(assoc_target, pre_assoc_items)

    render :update do |page|
       # add assoc target entity template.
       page.insert_html :bottom, base_div_id, 
            :partial => template, 
            :locals  => {:uuid => uuid,
                         :prefix => prefix,
                         :assoc_name => assoc_name,
                         :assoc_target => assoc_target,
                         :options => options},
            :object  => assoc_target
        # set counter value of each assoc_target.
        page << "recount_assoc_target_counters('#{base_div_id}', '#{single}')"
    end
  end
  
  def prepare_for_adding_assoc_target(assoc_target, pre_assoc_items)
    # do nothing as default if not defined in each controller.
    # do something if defined in each controller.
  end  
  
  def pre_assoc_items_from_prefix(prefix = "")
    prefix.gsub(/\]/, '').split('[').map(&:strip)
  end
   
  # called by observe_field  when real_name of model is given as prompt as params[:real_name]
  # then set candidates corresponding to the real name to "selecting_template" as select options(choices)
  # params are 
  #  :model => target model name
  #  :template => rendering template to select
  #  :real_name => real_name, 
  #  :select_div_id => div id of select template
  #  :prefix  => prefix to the name of select tag to identify input param
  # returning varilable is :select_options
  def select_options_from_real_name
    template   = params[:template] || "shared/input/select"
    model      = params[:model]
    prefix     = params[:prefix]
    candidates = params[:real_name].blank? ? nil : model.to_model.query_by_real_name(params[:real_name])
    select_options = candidates.blank? ? nil : 
      candidates.map do |entity| 
        ["#{entity.real_name}（#{entity.name})", entity.run_id] 
      end
    
    render :partial => template, :locals => {:prefix => prefix, 
                                             :select_options => select_options,
                                             :model => model}
  end
  
  def select_options_from_name
    model    = params[:model]
    template = params[:template] || "shared/input/select"
    prefix   = params[:prefix]
    candidates = params[:name].blank? ? nil : model.to_model.query_by_name(params[:name])

    select_options = 
      if candidates.blank?
        nil
      else
        candidates.map do |entity|
          [entity.name, entity.run_id]
        end
      end
    render :partial => template, 
           :locals => {:prefix => prefix, 
                       :select_options => select_options,
                       :model => model}        
  end 
  
  def select_options_from_name_and_author
    model    = params[:model]
    template = params[:template] || "shared/input/select"
    prefix   = params[:prefix]
    author_name, name = params[:name].split('|').map(&:strip)
    candidates = model.to_model.query_by_name_with_author_name(name, author_name)

    select_options = 
      if candidates.blank?
        nil
      else
        candidates.map do |entity|
          [(entity.author_name || "") + ' : ' +  entity.name, entity.run_id]
        end
      end
    render :partial => template, 
           :locals => {:prefix => prefix, :select_options => select_options} 
  end 
  
  def select_options_from_lecture_class_name
    model        = params[:model]
    template     = params[:template] || "shared/input/select"
    candidates   = query_by_lecture_class_name(params[:lecture_class_name] )
    prefix = params[:prefix] + "[#{Run.run_foreign_key(model)}]"

    select_options = 
      if candidates.blank?
        nil
      else
        candidates.map do |entity|
          [entity.aggregated_lecture_class_name, entity.run_id]
        end
      end
    render :partial => template, :locals => {:prefix => prefix, :select_options => select_options}    
  end
  
  # value is 所属名+学年
  def query_by_lecture_class_name(value)
    value.strip!
    value.blank? and return nil
    aff_name, sta_name = value.split("　")                            # seperator is 全角スペース
    sta_name.blank? and ( aff_name, sta_name = aff_name.split(" ") )  # seperator is 半角スペース
    aff_cond = aff_name.blank? ? nil : ["aff.name LIKE :aff_name", {:aff_name => '%' + aff_name + '%'}]
    sta_cond = sta_name.blank? ? nil : ["sta.name LIKE :sta_name", {:sta_name => '%' + sta_name + '%'}]
    CourseClass.find :all, :scope => ":self *organized_entity << :Organization[( .affiliation_run_id >> aff:Position)
                                                                               ( .status_run_id >> sta:Position)]",
                           :conditions => Run.merge_conditions(aff_cond, sta_cond)
  end
  
 protected
 
  def find_detail
    # do nothing as default.
    # if do something, define it in its controller.
  end
  
  # for updating and destroying, set default since time of entity.
  def set_default_since_time(time = @show_time, entity = @entity)
    entity.respond_to?(:since) && entity.respond_to?(:till) or return true  # do nothing
    # if @show_time is between valid time span, set default since time to be @show_time  
    (entity.since.to_datetime..entity.till.to_datetime).include?(time) and entity.since = time
  end
  
  # rendering for remote(ajax) or standard(non ajax) request
  # "template" is partial template for ajax or standard call.
  # when ajax call, the template is used to relace collection part designated by "div_id".
  #     div[div_id] is replaced by template.
  #        "div_id" default is "collection".
  # "locals" is locals parameters for "template"
  # "block" is a method to do before rendering
  # params[:collection_id] is supposed to be id for collection div which is replaced by "template"; default is "collection"
  # params[:layout] for standard call is supposed to be layout; default is "applicationr"
  def render_response(template, div_id = "collection", locals = nil, &block)
    block_given? and catch :flash_now do yield end
    template = @response_template || template  # @response_template can be set by block proc.
    locals ||= {}
    if request.xhr?
      # for "remote_call_for_***"
      render :update do |page|
        if @list_action   # case of listing action such as "search"  and "history" to show on the background_params
          page.replace div_id, :partial => template, :locals => locals
        else
          page.replace_html "working_div" , :partial => template, :locals =>  locals
          page << "if ($('back_to_list')) {$('back_to_list').show();};"
          page.insert_html :top, "working_div" , :partial => "shared/flash_notice"
        end
      end
    else
      # for "link_to_***"   
      render :layout => params[:layout] || "application",
             :partial => template, :locals =>  locals
      # rendering usual response to action to be followed
    end    
  end
  
  def committing(action_name, template, &block)
    # wrapper to set entity_id as identifier shared by Model and View
    render_response("shared/committing_template", "working_div", :content_template => template) do yield end
  end
  
  # commit and confirm the result.
  # default confirmation is to show history.
  def commit(action_name, &block)
    catch :flash_now do 
      @entity = yield
    end
    unless @entity
      # when flash_now happened below, @entity is nil.
      render :update do |page|
        flash.now[:error] = "#{action_name}に失敗しました．"
        page.insert_html :top, "working_div" , :partial => "shared/flash_notice"
      end
      return false
    end
    # succeeded to commit
    flash.now[:notice] = @confirm_message || "#{action_name}に成功しました．"
    # @confirmation_method and @confirmation_template can be set by yield above
    confirmation_method   = @confirmation_method   || "find_history"
    confirmation_template = @confirmation_template || "shared/history/run_history"
    # this template can be changed in "find_history" as @commiting_template
    render_response(confirmation_template) do send(confirmation_method) end
  rescue ActiveRecord::RecordInvalid => e 
    render_error_messages(e)
  end
  
  # render errors of commit on committing page
  # CAUTION: applicable only when request is xhr
  def render_error_messages(e)
    all_errors = e.record.set_of_all_errors || [e]
    render :update do |page|
      all_errors.each do |e|
        entity = e.record
        entity_id = entity.entity_id
        errors = entity.errors
        page.assign "error_size", errors.size
        page.assign "spotted_error_count", 0
        errors.each do |attr, msg|
          message     = msg.is_a?(Array) ? msg.join('<br />') : msg
          page.assign "error_count", (msg.is_a?(Array) ? msg.size : 1)
          page.select("*[entity_id='#{entity_id}'] .validity-error-message.#{attr}").each do |field|
            page.replace_html field, message
            field.visual_effect :highlight
            page << "spotted_error_count += error_count"
          end
        end
        # for errors unspotted by attributes
        residue_error_message = errors.full_messages.join('\n')
        page << "if( error_size - spotted_error_count > 0 ) alert('#{residue_error_message}')"
        
        errors.clear
      end
    end
  end
  
  # general put of Universal_Attribute value of params
  def put(params_for_entity = params[Universal_Attribute])
    @current_user or fail "put action is limited only for identified users to use."
    @entity_ref = params_for_entity.to_entity_ref
    
    @put_method =
      if params[:put_method] == "delete"
        @entity_ref.content[Run::Deleted_by] == @current_user.run_id.to_s or return # do nothing for illegal action.
        :delete
      else
       @entity_ref.new? ? :create : :update
      end
  
    Run.transaction do
      # "true" means to allow private method.
      respond_to?(:before_put, true) and before_put()  # preprocessing for put
      @entity = @entity_ref.put
      flash_now @entity.blank?, "すでに削除されています．"
      @entity && respond_to?(:after_put, true)  and after_put()   # postprocessing for put
      # check validity errors with @entity
      @entity && !@entity.set_of_all_errors.blank? and fail ActiveRecord::RecordInvalid.new(@entity)
    end
    @entity
  end
  
  # re_search and list under background with @background_params
  def list_again(options = {})
    controller   = options[:controller] || controller_name
    action       = options[:action]     || "search"
    @background_params ||= {}  
    @background_params.merge!(:controller => controller, :action => action) 
    catch :flash_now do find_collection end
    div_id       = options[:div_id]     || "collection"
    template     = options.delete(:collection_template) || @response_template || "shared/collection"
    render :update do |page|
      page.replace div_id , :partial => template, :locals => options
    end 
  end

  def prepare_for_correcting
    # do updating as default handling
    prepare_for_updating
    @response_template = "new"
  end
  
  def prepare_for_destroying
    # do nothing as default
  end
    
  # for denoting items(values of entity's attributes and methods) through Controller, Model and View
  #  "name" is intrinsic name, attribute name of entity and name of params if it is used as input item.
  #  "view_name" is item's text name in View. humanized version of "name".
  #  "model_value" designates value in model.
  #      if the value is primitive, a string is given that shows the location in DB.
  #      if the value is not primitive, symbol or array is given.
  #         symbol is name of method to apply entity with args. when args needed, give them as array of method name and args.
  #  "template" is name of template for rendering.
  #      if model_value is single, "shared/entity_item" is defaulted, 
  #           when symbol given, it is regarded as helper method to apply the entity.item value.
  #                string      ,                   special template to embed entity.item value.
  #      else, it is entity template for the value(collection); "#{name}/entity" is defaulted.
  #  "options" is a hash to give any options except html_options
  #  "html_options" is a hash to give html options to <td> tag such as :class
  #  see ApplicationHelper method "render_entity_item" for implimentation in View.
  Item = Struct.new :name, :view_name, :model_value, :template, :options, :html_options
  
  # args is for helper; should be array of argments for helper.
  Form_Item = Struct.new :name, :view_name, :attribute, :form_helper, :args, :html_options

  # making hash from array of items with key(name) and its value(Item struct)
  # "model_name" is domain model's name
  def self.item_struct(model_name, *items)
    items.dup.inject({}) do |result, item|
      item_st = Item.new(*item)
      model_value = item_st.model_value
      if  model_value.is_a?(String) && model_value.first == "." 
        # compensate table_name for omitted one.
        item_st.model_value = model_name.to_model.table_name + model_value
      end
      # set default value
      item_st.options ||= {}
      item_st.html_options ||= {}
      result.merge!({item.first.to_sym => item_st})   
    end
  end
  
  def item_struct(model_name, *items)
    self.class.item_struct(model_name, *items)
  end
  
  # construct def_form_items with def_items
  # view_name is shared with def_items
  def self.form_item_struct(def_items, *form_items)
    def_items && form_items && (diff = (form_items.map(&:first) - def_items.keys)).compact.blank? or fail "items '#{diff.inspect}' are not defined."
    form_items.inject({}) do |sum, item|
      itm  = item.dup
      name = itm.shift
      view_name = def_items[name.to_sym].view_name
      item_st = Form_Item.new *([name, view_name] + itm)
      # set default value
      item_st.attribute    ||= item_st.name
      item_st.form_helper  ||= :text_field
      item_st.args         ||= []
      item_st.html_options ||= {}
      sum.merge! name.to_sym => item_st
      sum
    end
  end
  
  def form_item_struct(def_items, *items)
    self.class.form_item_struct(def_items, *items)
  end
  
  # items to be SELECT items in SQL
  # to be value of find option :select or :distinct
  def self.select_items(def_items = @def_items, s_items = @def_items.keys)
    def_items && s_items && (diff = s_items - def_items.keys).blank? or fail "def_items '#{diff.inspect}' are not defined. "
    s_items.dup.inject({}) do |memo, key|
      model_value = def_items[key].model_value
      # add item only if it is a String showing attribute name of DB.
      memo.merge!({key => model_value}) if model_value.is_a?(String)
      memo
    end
  end
  
  def select_items(def_items = @def_items, s_items = @def_items.keys)
    self.class.select_items(def_items, s_items)
  end  
    
  # condition from query bar with def_items(definition of items) and query_items and params[:query]
  def query_cond(def_items = @def_items, query_items = @queries)
    def_items ||= []
    query_items ||= []
    input_params = @background_params.to_h.symbolize_keys
    query_params = input_params[:query] || @query_params || {}
    query_conditions query_params, *query_from_items(def_items, query_items)
  end

  # query items from Item name(i_name)
  def query_from_items(def_items = @def_items, i_names = @queries)
    i_names.map do |i_name|
      item_struct = def_items[i_name]
      item_struct.nil? and fail "no item struct corrensponding to '#{i_name}'"
      [def_items[i_name].model_value, i_name]
    end
  end
    

  # making conditions from queries by key
  # "params" is a hash of query params; query_field => query_key.
  #   "query_key" includes comparison operator
  #   if the query_key is like "key*" , this means "query_attr LIKE 'key'%" in SQL; i.e. "*" is replaced by "%" of SQL.
  #   other operators are %w(<= >= > < =) on top of query_keys. The default operator is "="
  # "query_attr_field" is either
  #       a pair of [attribute, query_field] giving correspondence to query field; example : ["created_by", :sender]
  #    or
  #       only query_field; in this case, corresponding attribute name is the same as the field name; example : ["name", :name] is given by :name.
  def query_conditions(params, *query_attr_fields)
     params.blank? and return  # neglect this condition.
     c_init = {:q => [], :s => {}}
     cond =
       query_attr_fields.inject(c_init) do |c, qry|
         if qry.is_a?(Array)
           attr, field = qry.first.to_s, qry.last.to_sym
         else
           attr, field = qry.to_s, qry.to_sym
         end         
         key = params[field]
         unless key.blank?
           key.strip!
           op = pred = succ = ""
           if key.starts_with? "*"
             op = "LIKE"
             pred = "%"
             key = key[1..-1].strip
           end
           if key.ends_with? "*"
             op = "LIKE"
             succ = "%"
             key = key[0..-2].strip
           end
           if op == "LIKE"
             query_key = "#{pred}#{key}#{succ}"
           else
             op = %w{<= >= < > =}.detect {|p| key.starts_with?(p)}
             if op
               query_key = key[op.length..-1].strip
             else
               op ="="
               query_key = key
             end
           end
           c[:q]<<  "#{attr} #{op} :#{field}"
           c[:s].update(field => query_key)
         end
         c
       end
#     return 'TRUE' if cond[:q].blank?
     cond[:q].blank? and return  
     [cond[:q].compact.join(" AND "), cond[:s]]
  end
 
  # for paginating_find
  def current_page(size = Default_Paginating_Size)
     {:size => size, :current => params[:page]}
  end
   
  def current_account
    Run.current_account
  end
  
  def current_account=(account)
    @current_account = Run.current_account = account
  end
  
  def current_user
    current_account ? Run.current_user : nil
  end
  
  # virtually(temporally) setting
  def current_user=(user)
    @current_user = Run.current_user=(user)
  end 

  def merge_conditions(*conditions)
    Run.merge_conditions *conditions
  end

  # get latest value of entity's attr in sql grouping
  SQL_Group_Separator = "'_/]}[{@|¥~^=-)(&%$#!'"
  def self.latest_value_in_sql_group(entity, attr)
    "SUBSTRING_INDEX(GROUP_CONCAT(#{entity}.#{attr} ORDER BY #{entity}.id DESC SEPARATOR #{SQL_Group_Separator}), #{SQL_Group_Separator}, 1)"
  end
  
  # set environmental parameters
  def set_background_params
      @background_params ||= params.to_h.symbolize_keys
  end
  
  # receive environmental parameters
  def receive_and_set_background_params
    @background_params = 
      (background_params = params.to_h.symbolize_keys[:background_params]).blank? ? {} : background_params.to_h.symbolize_keys
  end

  def organization_net(org_name = "", affiliation_name = "affiliation", status_name = "status")
    " *organized_entity << #{org_name}:Organization [(.affiliation_run_id >> #{affiliation_name}:Affiliation)(.status_run_id >> #{status_name}:Status)]"
  end
  
  def organization_query_cond(aff_query, sta_query, affiliation_name = "affiliation", status_name = "status")   
    ["#{affiliation_name}.fullname LIKE :affiliation  AND #{status_name}.fullname LIKE :status",
     {:affiliation => "#{aff_query}%", :status => "#{sta_query}%"}]    
  end
  
  # for selection by radio button of tree
  def tree_condition(query, entity_name)
    leaf_mark = Position::With_Singular_Leaf
    if query.end_with?(leaf_mark)
      query = query.mb_chars[0..-2]
      ["#{entity_name}.fullname = :query", {:query => query}]
    else
      ["#{entity_name}.fullname LIKE :query", {:query => "#{query}%"}]
    end
  end
  
  def check_flash_redirect(check, success_flash = "成功しました．", success_redirect = nil, fail_flash = "失敗しました．", fail_redirect = :back)
#    success_redirect = {:action => "index"} if success_redirect == :index
#    fail_redirect    = {:action => "index"} if fail_redirect    == :index
    success_redirect == :index and success_redirect = {:action => "index"}
    fail_redirect    == :index and fail_redirect    = {:action => "index"}
    
    if check
#      flash[:notice] = success_flash if success_flash
#      redirect_to success_redirect   if success_redirect
      success_flash     and flash[:notice] = success_flash
      success_redirect  and redirect_to success_redirect
    else
#      flash[:error]  = fail_flash  if fail_flash
#      redirect_to fail_redirect    if fail_redirect
      fail_flash    and flash[:error]  = fail_flash
      fail_redirect and redirect_to fail_redirect
    end
  end
  
  # flash back if condition is true.
  def flash_back(condition, message = nil)
    if condition
      flash.now[:error] = message
      if request.xhr?
        render :update do |page|
          page.redirect_to :back
        end
      else
        redirect_to :back
      end
      return false
    end
  end
  
  # flash.now message and throw :flash_now if condition is true.
  def flash_now(condition, message)
    if condition
      flash.now[:notice] = message
      throw :flash_now
    end
  end
  
  def flash_now_unless(condition, message)
    unless condition
      flash.now[:error] = message
      throw :flash_now
    end
  end
  
  # time setting controll

  def real_time=(time = DateTime.now)
    @real_time = time
  end
  
  def action_time=(time=@real_time)
    @action_time = Run.action_time = time
  end
  
  def show_time=(time=@real_time)
    @show_time = Run.show_time = time
  end
  
  def show_time_base=(time=@real_time)
    @show_time_base = time
  end
  
  def base_setting_time=(time = @real_time)
    @base_setting_time = time
  end
  
  def show_time_rate=(ratio = nil)
    @show_time_rate = (ratio || 1.0)
  end
  
  def assert_time=(time)
    @assert_time = Run.assert_time = time
  end

  # corresponding to partial view "shared/_select_date.rhtml"
  def date_params_to_date(params)
    params.blank? and return
    now = @action_time
    params[:year].blank?  and params[:year]  = now.year
    params[:month].blank? and params[:month] = now.month 
    params[:day].blank?   and params[:day]   = now.day  
    
    s = [params[:year], params[:month], params[:day]].map(&:to_s).join("-") 
    
    # change illegal date to normal one (ex. '2007-2-29' => '2007-3-1')
      # CAUTION: Don't use Date._parse since it returns ArgumentError when illegal date is given.
    Time.parse(s).to_date.to_s
  end
  
  def get_academic_year_and_season_from_date_params(date_params)
    time = date_params_to_date(date_params).to_datetime(:local)
    return Run.get_academic_year(time), Run.get_academic_season(time)
  end
  
  # "年度"
  def get_academic_year(ac_year = params[:academic_year])
    ac_year.blank? ? Run.get_academic_year :  ac_year.to_i
  end
  
  # "学期"
  def get_academic_season(ac_season = params[:academic_season])
    ac_season || ""
  end
     
  def set_assert_time_as_academic_season_range(academic_year = @academic_year, academic_season = @academic_season)
    self.assert_time = academic_season_time_range( academic_year, academic_season ) 
  end
  
  def set_assert_time_as_end_of_academic_season_range(academic_year = @academic_year, academic_season = @academic_seaon)
    self.assert_time = end_of_academic_season(academic_year, academic_season)
  end
  
  # range is given in :db format
  def academic_season_time_range(ac_year = get_academic_year, ac_season = get_academic_season)
    Run.academic_season_time_range(ac_year, ac_season)
  end 
  
  def beginning_of_academic_season(academic_year = @academic_year, academic_season = @academic_season)
    academic_season_time_range(academic_year, academic_season).begin.to_datetime
  end
  
  def end_of_academic_season(academic_year = @academic_year, academic_season = @academic_season)
    academic_season_time_range(academic_year, academic_season).end.to_datetime
  end
  
  def end_of_academic_year(academic_year = @academic_year)
    Run.academic_season_time_range(academic_year).end.to_datetime
  end
  
  # useful for :assert_time option in association
  def self_created_time()
    Run::Self_Created_Time
  end
  
  # determin time from params
  # fixing illegal date params such as "2009-02-30"
  # Time.parse can do so. Date._parse or other parses do not allow illegal date.
  def time_from_date_params(date_params = {})
    date_params.blank? and return @show_time
   "#{date_params[:year]}-#{date_params[:month]}-#{date_params[:day]} #{date_params[:hour]}:#{date_params[:minute]}".to_datetime(:local)
  end
 
  
 private

  # for before_filter
  def admin_only
    render_flash_now_if(!admin?, "管理者のみ許可されます．")
  end

  # for before_filter
  def registered_only
    render_flash_now_if !registered?, "登録ユーザのみ許可されます．"
  end
  
  def local_registered_only
    registered_only
  end
      
  # for before_filter against Commitment Actions except :new and :create.
  def owner_only
    render_flash_now_if !admin_or_owner_of?, "作成者のみ許可されます．"
  end
  
  def owners_and_teachers_only
    render_flash_now_if !(admin_or_owner_of? || teacher?), "作成者と教員のみ許可されます．"
  end
  
  def render_flash_now_if(cond, message = "利用できません", div_id = "working_div")
    cond or return
    flash.now[:error] = message
    if request.xhr?
      render :update do |page|
        page.insert_html :top, div_id, :partial => "/shared/flash_notice"
      end
    else
      render :partial => "/shared/flash_notice", :layout => "application"
    end
    return false
  end
  
  def set_system_situation
    set_basic_times
    set_current_account_and_user
    if allow_simulation_mode? 
      if session[:simulation_mode] 
        # when in simulation mode, only records with simulation_mode are found from database.
        self.simulation_mode = session[:simulation_mode]
        # action_time is normally real_time but show_time when in simulation_mode.
        self.action_time = @show_time
      end
    else
      # reset simulation mode
      session[:simulation_mode] = self.simulation_mode = nil
    end
  end

  # set real_ and action_ and show_ and assert_time as default time setting
  # real_time is always literally now(digitized).
  # show_time = show_time_base + (real_time - show_time_base) * show_time_rate
  # session[:simulation_mode] is true if simulation_mode
  # assert time is set to show_time as default.
  def set_basic_times
    self.real_time         = DateTime.now
    self.action_time       = @real_time
    self.show_time_base    = session[:show_time_base] ? session[:show_time_base].to_datetime(:local) : @real_time
    self.base_setting_time = session[:base_setting_time] ? session[:base_setting_time].to_datetime(:local) : @real_time
    self.show_time_rate    = session[:show_time_rate] || 1 
    self.show_time         = @show_time_base + (@real_time - @base_setting_time) * @show_time_rate
    self.show_time_mode  = session[:show_time_mode] || 0   
    # as default of academic year
    @academic_year = Run.get_academic_year
    
    # as default of assert_time
    self.assert_time = @show_time
  end
  
  def set_menu_name
    @menu_name = params[:menu_name1]
  end
      
  def login_required
    respond_to do |format|
      format.html do
        if session[:account]
          return true
        else
          if request.xhr?
            render :update do |page|
              page << "alert('ログインを行ってからやり直してください．')"
            end
          else
            # store the request uri for it to be done after success of authentication
            session[:last_request] = request.request_uri
            flash[:notice] = "ログインが必要です．" 
            redirect_to new_session_url
          end         
        end
      end
    end
  end
  
  def render_no_response_if(condition)
    condition and render(:status => 204,:nothing => true)
  end
  
  # if session[:account], then set current_account and current_user.
  # else set both nil.
  def set_current_account_and_user
    if session[:account]
      # set current(at action_time) state of current account
      @current_account = Run.set_current_account(session[:account])
      current_user = Run.set_current_user or fail
      @current_user = Run.current_user  # set current_user with current main affiliation and status, and set user category
    else
      @current_account = @current_user = nil
    end
  rescue
    reset_session
    flash[:error] = "アカウントまたは対応するユーザ情報が変更されています．イントラweb委員会にお問い合わせください．"
    redirect_to :controller => "/home"
    return false    
  end
  
  # for before_filter
  def guest_out
    flash_back @current_user.nil?, "ログインが必要です．"
    flash_back guest?,
                 "****ゲストユーザはこの機能を使用できません．使用するためには登録が必要です*****．"
  end
  
  # uuid generator
  def random_id
    UUIDTools::UUID.random_create.to_s
  end
  
  def transform_time_param_to_db_time(time_param)
    if time_param && time_param.include?('..')
      first, last = time_param.split('..')
      first..last
    else
      time_param
    end
  end
  
  # 添付ファイル用の追加メソッド
  #
  # 2011. 2. 5 仕様変更に対応
  def attached_files_connection(entity=@entity, sw="")
    entity and entity.attached_files_connection(params[:afc_codes],sw)
    entity
  end

end