=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


class Position < Run
  # representing full ordered hierarchies
  # STI root
  
	set_table_name "positions"
  
  With_Singular_Leaf    = "┳"  # mark attached to tree node name to show that the node has a singular leaf; example... company and the director.
  Without_Singular_Leaf = "┓"  # mark attached to tree node name to show that the node has children none of which is a singluar leaf.
  Marks = ["", With_Singular_Leaf, Without_Singular_Leaf] # ""(blank) means the node is a leaf of tree.
  
  attr_accessor :location  # virtual attribute for position tree editing
  
  attr_accessor :target_to_move_to # virtual attribute for target position to move to
  
  validates_presence_of :name, :message => "名前がありません．"
  
  def modifier!
    loc_name, position_id = self.location.split("_to_")
    
    # when updating (or deleting) self
    if loc_name.blank? 
      self.deleted_by.blank? and set_fullname
      return
    end

    # when added as :pred or :succ, 
    #   find its nearest neighbor sibling, 
    #   set its parent_run_id, seq, fullname and fullseq attributes to insert it between the node and the target.    
    # when added as :child, 
    #   set its parent_run_id, seq, fullname and fullseq attributes in order for it to be the first child.
    time_span = self.since..Future
    loc_option = loc_name.to_sym  # :pred, :succ, or :child
    target = Run.find_entity(position_id)
    case loc_option
      when :pred, :succ
        state_attr = self.class.state_attr_list_relative_to(loc_option, target, [self.attributes]).last
        self.parent_run_id = state_attr[Parent_run_id]
        self.seq = state_attr[Seq]
        self.fullseq  = state_attr[Fullseq]
        self.fullname = state_attr[Fullname]
      when :child
        # show that target has child(ren).
        target.mark.blank? and target.update_run!(self.since, {:mark => Without_Singular_Leaf})
        self.parent_run_id = target.run_id
        self.seq = Run.seq_between(nil, nil)
        self.fullseq  = Run.make_fullseq(self.seq, target.fullseq)
        self.fullname = Run.make_fullname(self.name, target.fullname)
    end
  end
  
end
