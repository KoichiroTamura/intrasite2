=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class PositionsController < RunsController
    
  before_filter :admin_only
  
  def index
    # default target position to edit
    @position = Position.find( :first, :scope => :self, :order => "fullseq" )
    
    @mark = ''
    
    prepare_for_altering
  end
  
  def search
    @fullname = params[:position] || Affiliation::ROOT
    prepare_in_search
    # keep position in session
    session[:target_position] = @position.to_param
    render :update do |page|
      page.replace_html "form_for_position_tree_edit" , :partial => "editing_position"
      page["editing_target_node"].highlight
      page.replace_html "form_for_position_tree_move" , :partial => "moving_position"
    end
  end
  
  def search_for_move
    @moving_fullname = params[:moving] || Affiliation::ROOT
    prepare_in_move  
    render :update do |page|
      page.replace_html "form_for_position_tree_move" , :partial => "moving_position"
    end
  end
  
  def after_put
    # if name of a node is updated, fullnames of its children should be changed.
    # if a node is deleted, its children should be all deleted.
    case @put_method
      when :create
        @fullname = @entity.fullname
      when :update
        @entity.class.update_children_fullseq_fullname(@entity.attributes)
        @fullname = @entity.fullname
      when :delete
        terminate_time = @entity.till
        terminate_time < Run::Future and
          @entity.delete_all_descendant_runs!(terminate_time.in(Run::QTIME)..Run::Future)
    end
    # confirmation rendering
    @list_action = true
    @confirmation_method   = "index"
    @confirmation_template = "collection"
  end
    
 protected
 
  def prepare_in_search_and_move
    prepare_in_search
  end
  
  def prepare_in_search
    find_target_node
    prepare_for_altering
  end
  
  def prepare_in_move
    find_moving_node
    prepare_for_moving
  end

  # target location to create(as its prev, succ or child), update, delete or move to(as its prev, succ or child)
  def find_target_node
    fullname = @fullname
    mark = ''
    if fullname.end_with?(Position::With_Singular_Leaf)
      mark = Position::With_Singular_Leaf
    elsif fullname.end_with?(Position::Without_Singular_Leaf)
      mark = Position::Without_Singular_Leaf
    end
    fullname.gsub!(/#{mark}/, '')
    @position = Position.find :first, :scope => :self, :conditions => {:fullname => fullname}
  end

  def find_moving_node
    fullname = @moving_fullname
    @moving = Position.find :first, :scope => :self, :conditions => {:fullname => fullname}
  end
  
  def prepare_for_altering
    # default since time for altering
    @position.since = @show_time
    model = @position.to_param.to_model_name.to_model
    @pred  = model.new_run :since => @show_time, :location => "pred_to_#{@position.to_param}"
    @succ  = model.new_run :since => @show_time, :location => "succ_to_#{@position.to_param}"
    @child = model.new_run :since => @show_time, :location => "child_to_#{@position.to_param}"  
  end
  
  def prepare_for_moving
    # recover position entity
    @position = Run.find_entity session[:target_position], :scope => :self
    @moving.since  = @show_time
    @pred =  @moving.dup
    @succ = @moving.dup
    @child = @moving.dup
    @pred.location  = "pred_to_#{@position.to_param}"
    @succ.location  = "succ_to_#{@position.to_param}"
    @child.location = "child_to_#{@position.to_param}"  
  end

end