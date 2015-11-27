=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  
  require "uuidtools"

  # current_account's role is admin
  def admin?
    controller.admin?
  end
  
  def teacher?
    controller.teacher?
  end
  
  def student?
    controller.student?
  end
  
  def undergraduate_student?
    controller.undergraduate_student?
  end
  
  def graduate_student?
    controller.graduate_student?
  end
  
  def public_user?
    controller.public_user?
  end
  
  def guest?
    controller.guest?
  end
  
  def test_user?
    controller.test_user?
  end
  
  def owner_of?(entity = @entity)
    controller.owner_of?(entity)
  end
  
  def admin_or_owner_of?(entity = @entity)
    controller.admin_or_owner_of?(entity)
  end
  
  # current_account logged in? and not "guest"(not anonymous) ?
  def registered?
    controller.registered?
  end
  
  def allow_simulation_mode?
    controller.allow_simulation_mode?
  end
  
  def allow_to_change_show_time?
    controller.allow_to_change_show_time?
  end
  
  # show_time == action_time ?
  def at_present?
    controller.at_present? 
  end
  
  # is in simulation mode?
  def simulation_mode?
    controller.simulation_mode
  end
  
  # is item allowed to view?
  def view_allowed?(item)
    @view_allowed.to_a.map(&:to_sym).include?(item.to_sym)
  end

  
  # "年度"
  def get_academic_year(ac_year = params[:academic_year])
    controller.get_academic_year(ac_year)
  end
  
  # "学期"
  def get_academic_season(ac_season = params[:academic_season])
    controller.get_academic_seasonr(ac_season)
  end
  
  # uuid generator
  def random_id()
    UUIDTools::UUID.random_create.to_s
  end
  
  # adding attachment in new and edit page
  def add_attachment_link(name, attachment_name, attachment_model_name)
    link_to_function name do |page|
      page.insert_html :bottom, attachment_name.pluralize.to_sym, :partial => attachments_name, :object => Run.attachment_model_name.to_model.new
    end
  end
    
  # improved content_tag methods; if given tag is nil, no tags attached
  def i_content_tag(tag, content)
    tag ? content_tag(tag, content) : content
  end
  
  #Gmail風　時刻表示　by 石川&田村
  def date_format(time_string, options = {})
    time_in_japanese_style(time_string, :since, :short => true)
  end
  
  # render time in japanese style
  # options[:short] => if true, show date or hour_min_sec if day is today.
  # options[:sec]   => if true, show second.
  def time_in_japanese_style(input_time, since_or_till = :since, options = {})
    time = input_time.to_datetime

    infinite_past?(time)   and return "ーーー"
    infinite_future?(time) and return "ーーー"
    now = DateTime.now
    year, month, day = time.year, time.month, time.day
    year_name = year == now.year ? "" : "#{time.year}年"
    date_name = year_name + "#{month}月#{day}日"
    
    hour, min, sec = time.hour, time.min, time.sec
    h0, m0, s0 = *([hour, min, sec].inject([]) do |sum, t| sum << (t < 10 ?  "0" : "") end)
    hour_min_sec_name = ""
    unless since_or_till == :till && (hour == 23 && min == 59 && sec == 59)
      hour == 0 && min == 0 or hour_min_sec_name += h0 + hour.to_s + ":"  + m0 + min.to_s
      sec  > 0 && options[:sec] and hour_min_sec_name += ":" + s0 + sec.to_s
    end
    if options[:short]
      time.to_date == now.to_date ? hour_min_sec_name : date_name
    else
      date_name + " " + hour_min_sec_name
    end
  end
  
  def render_time_without_date(time)
    time or return ""
    hour = time.hour == 0 ? "00" : "#{time.hour}"
    min  = time.min  == 0 ? "00" : "#{time.min}"
    result = hour + ":" + min   
    if (sec = time.sec) > 0
      if sec >= 59
        new_time = time + 1   # carry over
        return (new_time.hour == 0 ? "24:00"  :  render_time_without_date(time + 1))
      else
        result += ":" + sec
      end
    end
    result
  end
  
  def infinite_past?(time)
    time.year == Run::Past.year
  end
  
  def infinite_future?(time)
    time.year == Run::Future.year
  end
  
  def odd_or_even_row(entity_counter)
    entity_counter%2 == 0 ? "even" : "odd"
  end
  
  # shorten too long strings to show
  def shorten(s, no_of_chars = 10)
    s ||= ""
    strip_tags(s).mb_chars[0..no_of_chars] + "．．．"
  end
  
  def formatting_float_number(n, format)
    n ||= 0
    sprintf(format, n)
  end
  
  # if s is nunber and count > 1, sandwich by "(" and ")" 
  def sandwich_by_parentheses(s, count = 1)
   ( s.to_i <= 0 || s.to_i > count) ? "（#{s}）" : ""
  end
  
  def render_h3(text)
    content_tag :h3 do
      text
    end
  end
 
  def notice(*content)
    content_tag "span", :class => "notice" do
      content.each do |c| c end
    end
  end
  
  def local_information(infos)
    infos.blank? and return ""
    info_string = local_info_string(infos)
    render :partial => "shared/local_information", :locals => {:infos => info_string}
  end
  
  def local_info_string(infos)
    infos.blank? and return ""
    info_chain = infos.dup
    case info_chain
      when String then infos
      when Symbol then send(infos)
      when Array
        head, *rest  = *infos
        case head
          when String then "<p>#{head}</p>" + local_info_string(rest)
          when Symbol then send(head, *rest)
          when Array  then local_info_string(head) + local_info_string(rest)
        end
      else  fail "illegal local information"
    end   
  end
  
  def render_hide_button(text = "X")
    content_tag :p, :style=>"text-align:right; cursor:pointer;", :onclick=> "this.up().hide()" do
      text + "&nbsp;&nbsp;"
    end
  end
  
  def render_close_button(text = "X", options={})
    background_color = options[:background_color] || '#fff'
    content_tag :p, :style=>"text-align:right; background: #{background_color};" do
      content_tag :span, :style=>"cursor:pointer;font-size:small; ", :onclick=> "this.up(1).remove()"  do
        text
      end
    end
  end 
  # label_set is string expression of set with IN_Seperator
  def has_label?(label_set, label)
    label_set && label_set.split(Run::IN_Separator).map(&:strip).include?(label)
  end
  
  # render collection of entities
  # "collection" is collection for rendering; default is @collection
  # options are ...
  # :collection_template : template for collection; default is "shared/collection"
  # :div_id : id of div which contains collection of entities; default => "collection".
  # :text_for_adding_new : text to show adding new entity
  # and
  #  options for "render_collection_only"
  def render_collection(collection = nil, options = nil)
    collection ||= @collection
    options    ||= @collection_options || {}
    
    # to inherit to "render_pure_collection"
    @collection = collection
    @collection_options = options    
    collection_template = options.delete(:collection_template) || @response_template || "shared/collection"
    render :partial => collection_template,
           :locals  => {:collection => collection}.merge(options)  
  end
     
  # render pure collection wrapped by "working_div"
  #  "working_div" division is for working place to show detail, committing, or confirmation pages.
  # options are ...
  # :working_div : div_id of working space for such as detail, history, altering form and the confirmation
  #  and 
  #  options for "render_pure_collection"
  def render_collection_only(collection = nil, options = nil)
    collection ||= @collection
    options ||= {}
    @collection_options and options.merge! @collection_options
    content_tag :div, :id => (options[:working_div] || "working_div"), :class => "op-set" do 
      render_pure_collection(collection, options)
    end
  end
  
  # render pure collection; not wrapped by "working_div"
  #   actually inside of "working_div" of "render_colleciton_only" helper
  # options are ...
  # :collection_template : template for collection; default is "shared/collection"
  # :entity_template : template for viewing element of collection; default => "#{controller}/entity"
  # :def_items  : definition of items for display; default => @def_items
  # :list_items   : list of items for list up; default => @list_items
  # :table_header : template name for table header item; 
  #    if set by "shared/head_item", item names are given as table header.
  # :controller : controller of entity for consiting entity_template name; default => current controller
  # :entity     : name of element of the collection for consisting entity_template name; default => "entity"
  # :spacer_template  : tempate as spacer between rendered entities
  # :preamble : template name for rendering before collection ; default => nothing
  # :postscript : template name for rendering after  collection ; default => nothing
  def render_pure_collection(collection = nil, options = {})
    collection ||= @collection
    @collection_options and options.merge! @collection_options
    render :partial => "shared/pure_collection",
           :locals  => {:collection => collection}.merge(options)
  end

  
  def render_link_to_url(url)
    link_to url,url, :target => "_new"
  end
 
  # render just value itself in form (the value is not to be input) 
  def render_value_per_se(form, method, options = {})
    form.object.send(method, options)
  end
  
  # render input value on template given by options[:template]
  def render_input_value(form, method, options = {}, html_options = {})
    template = options.delete(:template)
    render :partial => template, :locals => {:form => form, :method => method, :options => options, :html_options => html_options}
  end
  
  def render_select_by_existing_values(form, method, options = {}, html_options = {})
    render :partial => "shared/input/select_by_existing_values", :locals => {:form => form, :method => method, :options => options, :html_options => html_options}    
  end
  
  # render entity's items for display
  # "def_items" is definition of items; "selected" is selected items to render. 
  # see RunsController for details of item struct
  # options[:detail] is true for detail rendering; 
  # options[:prompt] is true for rendering prompt word. 
  def render_entity_items(entity, def_items = @def_items, list_items = @list_items, options = {})
    @entity = entity or fail ArgumentError, "entity is not given."
    
    def_items.is_a?(Hash) or fail "illegal def_items; #{def_items.inspect}"
    list_items.is_a?(Array)  or fail "illegal list_items; #{list_items.inspect}"
    (rest = (list_items - def_items.keys)).blank?  or fail ArgumentError, "items '#{rest.inspect}' are not defined by def_items."
   
    render :partial => options[:entity_template] || "shared/entity_item", 
           :collection => list_items, 
           :locals => {:entity => entity, :def_items => def_items, :list_items => list_items, :options => options}
  end
  
  # render entity's each item(item struct) for display
  def render_entity_item(entity, item)
     entity && item or fail "no item given for 'render_entity_item'" 
     name         = item.name.to_s
     model_value  = item.model_value
     template     = item.template
     options      = item.options || {}
     html_options = item.html_options || {}

     case  model_value 
       when String         # name designates attribute of entity defined by the string( model_value ).
         value  = entity.send(name)  
       when Symbol, Array  # a method(Simbol) or  Array of a method(Symbol) and its args to apply entity.
         method, *args = *model_value
         value = method == :self ? entity : entity.send(method, *args) 
       else
         fail "'#{model_value} is illegal as model value of entity item."
     end

     case template
       when nil  # template is omitted.
         if value.is_a?(Array) 
           render_pure_collection value, :div_id => name, :entity_template =>  (template || "#{name}/entity")
         else
           value
         end
       when String  # name of partial template to embed the value  
         options ||= {}; html_options ||= {}   
         if value.is_a?(Array)
           render_pure_collection value, :div_id => name, :entity_template => template
         else
           render :partial => template, :locals => {:value => value, :options => options, :html_options => html_options}
         end
       when Symbol, Array  # apply helper method 
         helper_method, *args = *template
         self.send(helper_method, value, *args)
       else
         fail ArgumentError, "'#{template}' is illegal as template for entity item."
      end
  end
 
  # rendering form items
  def render_form_items(form, def_form_items = @def_form_items, form_items =  @form_items)
    form or fail ArgumentError, "lacks form."
    def_form_items  or fail ArgumentError, "lacks def_form_items."
    form_items ||= def_form_items.keys

    (rest = (form_items - def_form_items.keys)).blank? or fail ArgumentError, "form_items '#{rest.inspect}' are not defined by def_form_items."

    render :partial => "shared/form_items",
           :locals => {:form => form, :def_form_items => def_form_items, :form_items => form_items}
  end
  
  # japanese style of datetime_select helper
  def datetime_select_jp(form, method, options ={})
    options[:use_month_numbers].nil? and options[:use_month_numbers] = true
    options[:end_year] ||= (form.object.send(method)  || @show_time).year + 10 
    form.datetime_select(method, options)
  end
  
  def date_select_jp(form, method, options ={})
    options[:use_month_numbers].nil? and options[:use_month_numbers] = true
    form.date_select(method, options)
  end
  
  # datetime_select_for_since setting
  def datetime_select_for_since(form, method = :since, options = {})
    time = @default_since || @show_time
    form.object.since = time
    options[:end_year] ||= time.year + 10 
    datetime_select_jp(form, :since, options)
  end
  
  # datetime_select_for_till setting
  def datetime_select_for_till(form, method = :till, options = {})
    if time = @default_till  # given default till other than Future
      form.object.till = time
      default_since = @default_since || form.object.since || @show_time
      options[:start_year] ||= [time.year - 5, default_since.year].max
      options[:end_year]   ||= [time.year + 5, default_since.year].max
      datetime_select_jp(form, :till, options)
    end
  end
  
  # radio button selection
  # top of args is pair of value and its label
  def radio_button_selection(form, method, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    args.inject("") do |sum, pair|
      sum += form.radio_button(method, pair.first, options) + form.label(method + "_" + pair.first.to_s, pair.last) + "  "
    end    
  end
    
  # observe form "search" and  "search"  action is called to update partially when form params changed.
  # "form_id" is form id; default is "search"
  def observe_search(frequency = nil, form_id = nil, params = {})
    form_id ||= "search"
    observe_form form_id, :url => {:action => "search"}, 
                          :frequency => frequency             
  end
  
  def remote_submit_to_search(text = "設定更新")
    render :partial => "shared/remote_submit_to_search", :locals => {:text => text}
  end
  
  # cause periodical state change of element(given by div id)  with interval of time sec.
  def cause_periodical_change(time = 60, element = "periodical_change")
    time <= 0 and return ""  # no effective setting
    
    javascript_tag do 
      <<-CODE
      function toggleStateOfElement(element){
        if (element == null) clearInterval(intervaled);
        else{ if  (element.getValue() <= 0) element.value = 1;  else element.value = 0;}
      }
      function setPeriodicalChange(time, element){
        intervaled = setInterval( toggleStateOfElement, time*1000, element ); 
      }
      setPeriodicalChange(#{time}, $('#{element}'))
      CODE
    end
  end
  
  # render entities' method value(s); if given multiple entities,  join their values by seperator.
  # if method has args, then express them as array [method, *args].
  def render_entities(entities, method, seperator = "<br />")
    entities or return
    seperator.is_a?(String)  or fail "'#{seperator}' must be a string."
    entities.is_a?(Array) ?  (entities.map {|e| e.send(*method)} ).join( seperator ) :
                              entities.send(*method)
  end

  
  # render query bar
  # default items are given by @def_items(all items definition) and @queries(item names for query)
  def render_query_bar(*queries)
    @def_items && @queries or return
    queries = queries.blank? ? query_items() : queries
    content_tag :div, :class => "query-window" do
      render :partial => "shared/query", :collection => queries
    end
  end
  
  # for query bar with @queries (given by item names) of @def_items
  def query_items(items = @def_items, q_items = @queries)
    q_items.map do |q|
      [items[q].view_name, q]
    end
  end
  
  # for listing up items
  def entity_items(entity, items = @def_items, l_items = @list_items)
    l_items.map do |l|
      v = entity.send( l )
      items[l].escape.nil? ? v : h(v)
    end
  end
  
  # rendering paginating links for "collection" in "controller" with ajax link
  def render_paginating_links(collection, controller, action = nil)
    if collection.respond_to?(:page_count) && collection.page_count > 1
      action ||= "search"
      render :partial => "shared/paginating_links",
             :locals => {:url => "#{controller}\/#{action}"}
    end
  end
 
  # improved "link to remote" with query parameters given by options[:params]
  def link_to_remote_with_params(name, options, html_options = {})
    change_params_to_with(options)
    label = "<span style = 'white-space:nowrap'>#{name}</span>"
    link_to_remote label, options, html_options
  end
  
  def remote_function_with_params(options)
    change_params_to_with(options)
    remote_function(options)
  end
  
  def button_to_remote_with_params(name, options = {}, html_options = {})
    button_to_function(name, remote_function_with_params(options), html_options)
  end
  
  def observe_field_with_params(field_id, options)
    change_params_to_with(options)
    options[:frequency] ||= 0.6
    observe_field(field_id, options)
  end
  
  def change_params_to_with(options)
    param = options[:params] ? options[:params].to_query : ""
    options[:with] ? options[:with] += "+'&#{param}'" : options[:with]  = "'#{param}'"
  end
  
  # CAUTION: don't apply this constant to the method below. makes it unpredictable. why?
  Universal_Attribute = "_universal_attribute_"
  
  # universal remote form for root entity with or without associations.
  # applicable to create, correct, update and destroy
  def universal_remote_form_for(entity, options = {}, &block)
    # set default action as "universal_put"
    url_options = options[:url].blank? || options[:url][:action].blank? ? 
                  options[:url].to_h.merge(:action => "universal_put") : options[:url]
    url_options[:params] = url_options[:params].to_h.merge(:background_params => (@background_params || {}))
    opt = options.merge(:index  => entity.to_param,
                        :url    => url_options)
    opt[:html] ||= {}
    # set method "post" and  multipart true
    opt[:html].merge! :method => :post, :multipart =>  true
    
    remote_form_for( "_universal_attribute_", entity, opt, &block ) 
  end
  
  def remote_call_on_event(event, options)
    "#{event} = " + '"' +  remote_function_with_params(options) + '"'
  end
  
  # ajax call for detail of entity with its controller
  # options[:event] is the event to call such as :onclick
  # "find_detail" method will be called via standard show action.
  def remote_call_for_detail(entity, options = {})
    unless @view_allowed.to_a.include?(:no_detail_call)
      opt = options.dup
      action = opt[:action] || :show   # possibly action for detail other than :show.
      opt[:params] = opt[:params].to_h.merge(:background_params => @background_params)
      remote_call_for_action(action, entity, opt)
    end
  end
  
  Loaded_Class_Name = "'_loaded_'"
  
  # if detail has not been gotten, get it; else toggle.
  def get_detail_if_not_yet(entity, detail_div_id, options = {})
    controller = entity.controller_name
    options.merge! :url => "\/#{controller}\/show\/#{entity.to_param}"
    options[:params] ||= {}
    options[:params].merge! :div_id => detail_div_id
    options[:success] = "$('#{detail_div_id}').className = #{Loaded_Class_Name}; "
    "if ($('#{detail_div_id}').className != #{Loaded_Class_Name}) { #{remote_function_with_params(options)};}; " +
    "if ($('#{detail_div_id}').className == #{Loaded_Class_Name})  Element.toggle('#{detail_div_id}') ;"    
  end
  
  # "find_history" method will be called in standard history action.
  def remote_call_for_history(entity, options = {})
    remote_call_for_action(:history, entity, options)
  end
  
  def remote_call_for_updating(entity, options = {})
    remote_call_for_action(:updating, entity, options)
  end
  
  def remote_call_for_deleting(entity, options = {})
    remote_call_for_action(:destroying, entity, options)
  end
  
  def remote_call_for_action(action, entity, options = {})
    action && entity or fail "helper 'remote_call_for_action' lacks of params．"
    event = options.delete(:event) || "onclick"    
    action = action.to_s
    controller = options[:controller] || entity.controller_name
    entity_id  = options[:id]         || entity.entity_id
    options.merge!(:url => "\/#{controller}\/#{action}\/#{entity_id}")
    remote_call_on_event(event, options)
  end
  
  # event excluded version of remote_call_for_action
  def remote_call_for_action_on_entity(action, entity, options = {})
    action or fail "helper 'remote_call_for_action' lacks of input params．"
    entity or return # do nothing
    action = action.to_s
    controller = options[:controller] || entity.controller_name
    options.merge!(:url => "\/#{controller}\/#{action}\/#{entity.to_param}")
    remote_function_with_params(options)  
  end
  
  # standard (non ajax) call for entity detail to show
  # entity is supposed to have id and model_name
  # options[:force_controller], options[:force_controller] and options[:force_id] are forced params to change entity character
  def call_for_detail(entity, text, options = {}, html_options = {})
    text ||= "..."
    opt = options.dup
    opt[:controller] = options[:force_controller] || entity.controller_name
    opt[:action]     = options[:force_action] || "show"
    opt[:id]         = options[:force_id] || entity.to_param
    opt[:background_params] = @background_params
    if html_options[:popup] || html_options[:target]
      # for the case of new window to render
      opt[:layout] ||= "base_layout_for_non_collection"
    end
    link_to text, opt, html_options
  end
  
  def call_for_new(text, options = {}, html_options = {})
    opt = options.dup
    opt[:action]     = options[:action] || "new"
    opt[:background_params] = @background_params
    # for the case of another window to render
    html_options[:popup] || html_options[:target] and opt[:layout] ||= "base_layout"
    link_to text, opt, html_options    
  end

  # ajax version of "pagenating_links"(a plug in)
  DEFAULT_OPTIONS = PaginatingFind::Helpers::DEFAULT_OPTIONS     
  def remote_paginating_links(paginator, options = {}, html_options = {})    
    name = options[:name] || DEFAULT_OPTIONS[:name]
    params = (options[:params] || DEFAULT_OPTIONS[:params]).clone
    # commented out to avoid IE8 bug which caches for get method
    # options[:method] ||= :get
    
    new_options = options.clone
    paginating_links_each_modified(paginator, options) do |n, link|
      if link == :link
        params[name] = n
        content_tag :p do 
          link_to_remote_with_params(n, new_options.merge(:params => params), html_options)
        end
      else # no link to n
        content_tag :p, :class => link.to_s do
          n.to_s
        end
      end
    end
  end
  
  def paginating_links_each_modified(paginator, options = {})
      options = DEFAULT_OPTIONS.merge(options)

      window = ((paginator.page - options[:window_size] + 1)..(paginator.page + options[:window_size] - 1)).select {|w| w >= paginator.first_page && w <= paginator.last_page }

      html = ''

      if options[:always_show_anchors] && !window.include?(paginator.first_page)
        html << yield(paginator.first_page, :link)
        html << yield(' ... ', :text)  unless window.empty? || (window.first - 1 == paginator.first_page)
        html << ' '
      end

      window.each do |p|
        if paginator.page == p && !options[:link_to_current_page]
          html << yield(p, :current)
        else
          html << yield(p, :link)
        end
        html << ' '
      end

      if options[:always_show_anchors] && !window.include?(paginator.last_page) && paginator.first_page != paginator.last_page
        html << yield(' ... ', :text) unless window.empty? || (window.last + 1 == paginator.last_page)
        html << yield(paginator.last_page, :link)
      end

      html
    end
  
  # ishikawa design to link
  def designed_button_link(&block)
     content_tag :div, :class => "op-control" do 
      content_tag :ul, :class => "cf" do
        content_tag :li do
          content_tag :button do
           yield
          end
        end
      end
    end   
  end
  
  def back_to_list(text = "一覧に戻る", html_options = {})
    ctrl   = (@background_params && @background_params[:controller]) || controller_name
    action = @back_to_action || "search"
    url = "\/#{ctrl}\/#{action}"
  
    link_to_remote_with_params text, {:url => url, :params =>  @background_params},  html_options

  end
  
  def allow_to_add_new_entity?(opts = {})
    controller.respond_to?("allow_to_add_new_entity?") or return true # default when no definition given in controller
    controller.allow_to_add_new_entity?(opts)
  end
  
  # remote link to create new entity
  def remote_link_to_new(text = "新規追加",  options = {}, html_options = {})
    if registered? && (at_present? || simulation_mode?) && allow_to_add_new_entity?(options)
      options[:controller] ||= controller_name
      options[:url] = {:controller => options[:controller], :action => "new"}
      options[:params] = options[:params].to_h.merge( :background_params => @background_params )
      html_options[:class] ||= "op-control"
      link_to_remote_with_params( text,  options, html_options ) 
    end
  end
  
  def remote_call_to_new(event, options = {}, html_options = {})
    opt = options.dup
    if registered? && (at_present? || simulation_mode?)  && allow_to_add_new_entity?(opt)
      opt[:controller] ||= controller_name
      opt[:url] = {:controller => opt.delete(:controller), :action => "new"}
      opt[:params] = opt[:params].to_h.merge( :background_params => @background_params )
      remote_call_on_event(event,  opt) 
    end    
  end
  
  # remote link to correcting a state
  def link_to_correcting(entity = @entity, text = "訂正する", options = {}, html_options = {})
    link_to_altering(entity, text, :correcting, options, html_options)
  end
  
  # remote link to updating entity from state(id)
  def link_to_updating(entity = @entity, text = "更新する", options = {}, html_options = {})
    link_to_altering(entity, text, :updating, options, html_options)
  end
  
  # remote link to delete run entity
  def link_to_deleting(entity = @entity, text = "削除する", options = {}, html_options = {})
    link_to_altering(entity, text, :destroying, options, html_options)
  end
  
  # :exception option is set to be true if allowing to render link_to_remote as exception
  #   example:  seminar modification by teachers of seminar not creater.
  # refer Run#to_entity_ref for explanation of options[:assoc_ref] to limit associations to entity.
  #  too many associations cause HTTP request trouble to be too long.
  def link_to_altering(entity, text, action, options={}, html_options={})
    entity.is_a?(Run) or fail TypeError, "entity for updating is not a Run entity"
    controller = options[:controller] || entity.controller_name
    entity_ref = entity.to_entity_ref(:only_primary_attributes, options[:assoc_ref])
    if commit_allowed?( entity) || options[:exception]
        link_to_remote_with_params( text, 
                        {:url => {:controller => controller, :action => action, :id => entity.to_param}, 
                         :params => {:entity_ref => entity_ref, :background_params => @background_params},
                         :method => :get},
                        html_options) 
    end    
  end
  
  # improved "options_for_select" with suppressed names
  # "selected" is standard pre selected entity
  # out is array of names(text) to be suppressed(not appeared)
  def options_for_select_with_out(container, selected = nil, out = nil)
    if out.blank?
      options_for_select container, selected
    elsif out.is_a?(Array) && out.all?{|s| s.is_a?(String)}
      container = container.to_a if Hash === container
      new_container = container.inject([]) do |sum, element|
        unless out.include?(element) || (element.is_a?(Array) && out.include?(element.first))
          sum << element
        end
        sum
      end
      options_for_select new_container, selected
    else
      fail "out '#{out}' is not adequate."
    end
  end
      
  # improved by Tamura 2009/07/11
  # this is the same method of "to_query" in RAILS, so we use "to_query" instead of this.
  def params_to_with_format(params, pre = "")
    params.to_a.inject([]) do |s, kv|
      key, value = kv
      head =  pre == "" ? "'#{key}" : pre + "[#{key}]"
      if value.is_a?(Hash)
        value.each do |v| 
          v_key, v_value = v
          s << params_to_with_format({v_key => v_value}, head)
        end  
      else
        s <<  "#{head}=' + encodeURIComponent('#{value}')"
      end
      s
    end.join("+ '&' + ")
  end
  
  # --- not exist for RAILS 2.1 ---
  def button_to_remote(name, options = {}, html_options = {})
    button_to_function(name, remote_function(options), html_options)
  end

  # for organization representation by strings  
  def organization_list(organizations)
    organizations or return ""
    
    organizations.inject([]) do |s, unit|
     s << "#{unit.aff_fullname}（#{unit.sta_fullname}"
    end
    s.join(", ")
  end
  
  def toggle_div(div_id)
    update_page do |page|
      page[div_id].toggle
      page[div_id].highlight
    end
  end
  
  def show_password_field(pass_id, checked = true)
    update_page do |page|
      page[pass_id].type =  (checked ? "text" : "password")
      page[pass_id].highlight
    end
  end  
 
  # going back （戻る）.
  def button_to_back(text = "戻る")
    button_to_function text, "history.back();"
  end
  
  def button_to_history(entity = @entity, text = "履歴")
    @view_allowed.to_a.include?(:no_history) and return
    render :partial => "shared/buttons/history", :locals => {:text => text, :entity => entity}
  end

  def render_run_history(entity = @entity)
    render :partial => "shared/history/run_history", :locals => {:entity => entity}
  end
  
  def button_to_updating(text = "更新する", entity = @entity)
    if commit_allowed?( entity)
      render( :partial => "shared/buttons/updating", :locals => {:text => text, :entity => entity})
    end
  end
  
  def button_to_deleting(text = "削除する", entity = @entity)
    if commit_allowed?( entity) 
      render( :partial => "shared/buttons/deleting", :locals => {:text => text, :entity => entity})
    end
  end
  
  # condition for rendering commitment action 
  def commit_allowed?(entity = @entity)
    controller.commit_allowed?(entity)
  end

  # instant function generator by Toshy Namimatsu
  def function_define(name="",&block)
    "function #{name}() { #{block.call} }"    
  end
  
  # improved Rails "select" helper with pre-selected value
  # default value is original method value
  def select_with_default(form, method, choices, default=nil, options = {}, html_options = {})
    choices.blank? and return # do nothing.
    default ||= form.object.send(method).to_s
    form.select( method, options_for_select(choices, default), options, html_options )
  end
  
  # given object_name instead of form to select_with_default method
  def select_with_default_object(object_name, method, choices, default=nil, options = {}, html_options = {})
    choices.blank? and return # do nothing.
    select(object_name, method, options_for_select(choices, default), options, html_options )
  end
  
  # render set with checkbox which is checked for selected element in "set".
  # "selected_elements" is a string with comma seperated format(adapted for SQL format of set).
  def render_select_set_elements(selected_elements, set)
    set.is_a?(Array) or fail "#{set} should be an array."
    render :partial => "shared/selected_set_elements", :locals => {:selected_elements => selected_elements, :set => set}
  end
  
  # render to select elements of set by check boxes
  #  method ... the value is expressed by string with seperator ","
  #  options[:set]  ... elements of set to be selected
  #  options[:selected_elements_div_id] ... location of hidden field to keep selected_elements
  def render_input_select_set_elements(form, method, set, selected_elements_div_id = nil, options = {})
    set.is_a?(Array) or fail "#{set} should be an array."
    render :partial => "shared/input/select_set_elements", :locals => {:form => form, :method => method, :set => set.uniq,
                                                                       :selected_elements_div_id => selected_elements_div_id,
                                                                       :options => options}
  end
  
  # javascript function to change selected_elements in set
  # element is selected by checking its checkbox and removed by unchecking.
  # and input (id = "selected") value results in comma separated set of selected elements
  def change_selected_elements(element, selected)
    code  = "var selected_elements = $('#{selected}').value.split(',').without('');"
    code += "if ($(this).checked) {$('#{selected}').value = selected_elements.concat('#{element}').join(',')}"
    code += "else {$('#{selected}').value = selected_elements.without('#{element}').join(',')};"
  end
  
  # 組織図の一覧データ取得 (OrgDependency連携) By Toshy Namimatsu
# select affliation.fullname,status.fullname from 
# org_dependencies as od,positions as aff,positions as sts,positions as affliation,positions as status where od.affiliation_run_id=aff.run_id and od.status_run_id=sts.run_id and affliation.fullseq like aff.fullseq_sub and status.fullseq like sts.fullseq_sub ;
  def get_positions(cond=Hash.new)
      query="true"
      
      query+=" and affiliation.fullname like '%#{cond[:affiliation]}%'" unless cond[:affiliation].blank?
      query+=" and status.fullname like '%#{cond[:status]}%'" unless cond[:status].blank?
      query+=" and #{cond[:options]}" unless cond[:options].blank?
      
      collection = OrgDependency.find :all,
              :distinct   => "affiliation_run_id,status_run_id,affiliation.name as affilation_name, status.name as status_name,affiliation.fullname as affilation_fullname, status.fullname as status_fullname",
              :scope      => ":self [(.affiliation_run_id >> aff:Affiliation contains affiliation:Affiliation) (.status_run_id>> sts:Status contains status:Status)]" ,
              :conditions => query
  end
  
  def render_calendar_show_script
    javascript_tag do
      "cal_view("+
        "new Calender("+
          "'#{@show_time.year}/#{@show_time.month}/#{@show_time.day} 00:00:00 UTC+0900',"+
          "'#{@show_time.year}/#{@show_time.month}/#{@show_time.day} 00:00:00 UTC+0900'"+
          "),"+
          "'mini_calendar',"+
          "'side-calendar',"+
          "'year_month'"+
        ");"
    end
  end
  
  def render_org_dependency_script
    "<div id='scan_form'></div>"+
    javascript_include_tag("org_dependency")+ 
    javascript_tag {
      "OrgDependency.init('scan_form','#{url_for :action=>"search_json",:controller=>"org_dependencies"}');"+
      "OrgDependency.onclick_push('search','affiliation');"+
      "OrgDependency.onclick_recall('search','affiliation');"
    }
  end
  
  def set_all_check_box_flag(title, css_id )
    link_to_function(title) do |page|
      page.select(css_id).each do |cb|
        cb.checked = true
      end
    end
  end
  
  def reset_all_check_box_flag(title, css_id )
    link_to_function(title) do |page|
      page.select(css_id).each do |cb|
        cb.checked = false
      end
    end
  end
end
