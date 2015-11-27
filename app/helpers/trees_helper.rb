=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# helpers for rendering trees


module TreesHelper
  
  # render tree structure for root's children
  # target is selected node of tree; target_fullname is its fullname
  # options[:node_template] is node template
  # options[:terminal_template] is terminal template
  # options[:radio_name] is name for radio button tag for nodes
  # rest of options are options to find children such as :select, :conditions.
  def render_tree_structure(root, target_fullname = nil, options = {})
    root or fail("root for 'render_tree_structure' is nil.")
    @target_fullname   = target_fullname || root.fullname
    @node_template     = options.delete(:node_template)
    @terminal_template = options.delete(:terminal_template)
    @radio_name        = options.delete(:radio_name)  || "tree_node"
    @tree_options      = options
    @children          = root.children
    render :partial => "shared/tree/structure"
  end
  
  def render_tree_select(root, selected_node = nil, options = {})
    root or fail("root for 'render_tree_select' is nil.")
    
    @parent_node   = root 
    @selected_node = (selected_node.blank? || selected_node.new_record?) ? root : selected_node
   
    @tree_name     = options[:tree_name]
    @selected_field_id = options[:selected_field_id] || "selected_#{@tree_name}"  # field id for hidden field to keep value
    @tree_options  = options[:tree_options]
    @out           = options[:out]
    
    render :partial => "shared/tree/node_select"
  end
  
  # rendering tree selection cluster
  # options ...
  #  :form => form proxy of owner of the tree
  #  :method => attribute name to have the selected entity run_id
  #  :out    => node name to be excluded from selection
  def render_tree_select_cluster(root, pre_selection, options = {})
    render :partial => "shared/tree/selection_cluster", 
           :locals => {:root => root, :pre_selection => pre_selection, :options => options}
  end
  
end