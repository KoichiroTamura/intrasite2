=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module AssociationHelper
  
  # render assoc_targets for input
  # options in args
  #   association_template ... template to show collection of associations: default is "shared/input/association"
  #   single ... if true, assoced is only one
  #   collection_name ... assoc_targets collection name(folder name)
  #   legend ... legend for inputting entity
  #   entity_template ... template name for entity; default is item name.
  def render_association_to_put(form, method, *args)
    options = Run.get_options_from_args!(args)
    method_args = options.to_h[:method_args]
    assoc_entity = form.object
    assoc = assoc_entity.send(method, *method_args)
    if assoc.is_a?(Run)
      # assoc itself is a target entity when dependency is dependee.
      # change it to be collection with single element.
      new_assoc = Association.new([assoc])
      new_assoc.move_assoc_attrs_from!(assoc)
      assoc = new_assoc
    end
    association_template = options[:association_template ]|| "shared/input/association"
    render :partial => association_template, 
           :locals => {:form => form,
                       :association => assoc, 
                       :assoc_name => method.to_s,
                       :options => options}
  end
  
  # render individual assoc_target for input
  def render_assoc_target_to_put(assoc_target, prefix, assoc_name, options = {})
    assoc_target.blank? and return
    
    options[:assoc_target_body_template] ||= "#{options[:collection_name]}/input/assoc_target_body"
    content_tag :div, :entity_id => assoc_target.entity_id, :class => "assoc_target" do
      render(:partial => "shared/input/assoc_target",
             :locals  => {:assoc_target => assoc_target, 
                          :prefix => prefix,
                          :assoc_name => assoc_name.to_s,  # in View, assoc_name should be String, not Symbol as in association.
                          :options => options})
    end
  end
    
  def prefix_for_form(form)
    # assoc_entity name heritating all ancestors' and adding own name(index if any)
    object_name = form.object_name.to_s
    index       = form.options[:index]
    index ? object_name + "[#{index}]" : object_name
  end
  
  # rendering button to delete(remove) assoc_target entity in association
  def button_to_delete_assoc_target(name, assoc_target, assoc_name, options=nil, html_options = {})
    registered? or return ""  # illegal access
    
    options ||= {}
    single = options[:single] ? 'yes' : 'no'
    base_div_id = options[:base_div_id]
    assoc_body_elem = "this.up('.#{assoc_name}')"
    function_to_remove = if assoc_target.blank? || assoc_target.new_record? 
         # new_record; remove whole assoc target elem
        "this.up('.assoc_target').remove();"
      else
        # existing record
        "#{assoc_body_elem}.previous('.deletion_mark_field').value=#{@current_user.run_id};" +  # mark disconnection
        "#{assoc_body_elem}.remove();"
      end + 
      "n_of_assoc_target = recount_assoc_target_counters('#{base_div_id}',  '#{single}');"  # recount assoc_target counters

    button_to_function name, function_to_remove, html_options
  end
  
  # options(:show_items) is array of items to show in assoc target view
  def show_item?(options, item)
    options.nil? and return false
    show_items = options.to_h[:show_items].to_a.map(&:to_sym)
    show_items.include?(item.to_sym)
  end
  
end