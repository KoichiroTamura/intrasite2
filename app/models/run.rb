=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


require 'strscan'

require 'set'

require "uuidtools"

class String  

  # convert model name to model
  def to_model
#    return nil if self.blank?
    self.blank? and return nil
    self.gsub(/\s/, "")
    eval self
  rescue
    fail ArgumentError, " There is no model named '#{self}'."
  end
  
  
  # for entity id notation("id:Model") 
  def to_id_and_model_name
    split(Run::ID_Model_Separator, 2)
  end
  
  def to_id
    to_id_and_model_name.first
  end
  
  def to_model_name
    to_id_and_model_name.last
  end
  
  # for default assoc_name of association; self is supposed to be its target model name.
  def to_assoc_name(assoc_target_type = :dependant)
    # class hierarchy separator "::" is changed to "/" by method "underscore" of RAILS
    # this character is not allowed by Ruby, so change them to "__"
    result = underscore.gsub(/\//, "__")
    assoc_target_type == :dependee and return result
    result.pluralize
  end
  
  # convert entity id notation to id and model name 
  def to_id_and_model
    id, model_name = self.to_id_and_model_name
    id  or fail ArgumentError, "#{self.inspect} has no id as entity_id."
    id =  id.start_with?("new") ? id : (id.to_i > 0 ? id.to_i : fail(ArgumentError, "#{self.inspect} is illegal as entity_id.") )
    model = (model_name.blank? ? nil : model_name.to_model)
    return id, model
  end
  
  # toggle string
  def toggle(x, y)
    self == x.to_s ? y.to_s : x.to_s
  end
  
  # transform to datetime keeping UTC offset
  # CAUTION: holding 2038 problem due to to.time of Ruby
  def to_datetime(mode = nil)
    mode == :local and return to_time(:local).to_datetime
    super()
  end
  
  def to_s(type = nil)
    self
  end
  
  def strip_quotation
    gsub( /\'/, "" )
  end

end

class Hash
  # remove items with nil value
  def compact!
    delete_if do |k,v| v.nil? end
  end
  
  def to_h
    # when self.class is HashWithIndifferentAccess in Rails
    #   self.to_hash causes to stringfy keys !
    self  
  end
  
  # input params hash to entity_ref
  #  dummy arg is to keep compatibility with Run#to_entity_ref
  def to_entity_ref(dummy = nil)
    entity_id = keys.first
    # verify entity_id
    id, model = entity_id.to_id_and_model if entity_id
    content = values.first || {}
    content.is_a?(Hash) or fail ArgumentError, "content part of #{self.inspect} should be a Hash."
    new_content = {}
    content.each_pair do |attr_name, attr_value|
      new_content.merge! attr_name => Hash.attr_value_to_entity_ref(attr_value)
    end
    EntityRef.new entity_id => new_content
  rescue ArgumentError => e
    fail ArgumentError, e
  end
  
  # transform params for attribute value to entity_ref
  def self.attr_value_to_entity_ref(attr_value)
    case attr_value
    when String, Array  # supposed to be a literal or array of literals
      attr_value   
    when Hash    # assoc target(s)
      # transform to Array of entity_refs
      collection = []
      attr_value.each_pair do |name, value|
        collection += [{name => value}.to_entity_ref]
      end
      collection.compact      
    else
      fail "'#{attr_value.inspect}' is illegal as attribute value in params."
    end
  end

end

#-- end of Hash


class NilClass  
    
  # guards when initial value not given.

  def to_a
    []
  end
  
  def to_h
    HashWithIndifferentAccess.new
  end
  
  def to_assocs
    Association.new([])
  end
end

class Array
  # to hash array element of which is pair array [key, value]
  # necessary to recover hash after selected
  def to_h
    blank? and return {}
    inject({}) do |sum, a|
      key, rest = *a
      sum.merge! key => rest
    end
  end
end


# parameter expression of run entity {entity_id => content}
class EntityRef < Hash
  
  attr_accessor :entity_id, :content
  
  def initialize(entity_expression)
    entity_hash = case entity_expression
      when String  # case of literal
        {entity_expression => {}}
      when Hash
        entity_expression
      else
        fail "'#{entity_expression}' is illegal for an EntityRef."
      end
    @entity_id = entity_hash.keys.first
    @content = entity_hash.values.first || {}
    @content.is_a?(Hash) or fail "'#{entity_ref}' is illegal for an entity_ref."
    @content.stringify_keys!  # CAUTION to access content of entity_ref
    merge! @entity_id => @content
  end
  
  def id
    entity_id.to_id
  end
  
  def model
    entity_id.to_model_name.to_model
  end
  
  def table_name
    model.table_name
  end
  
  def new?
    entity_id && entity_id.start_with?('new')
  end
  
  # convert self(entity_ref) to Run entity and put it to DB.
  #  root_entity is owner(assoc_entity) of self
  #  root_since is demanded since for modification to root_entity
  #  omit root_entity and root_since at initial entry.
  def put(root_entity = nil, root_since = nil)
    # to accumulate errors of ActiveRecored::RecordInvalid
    set_of_all_errors = []
     
    (value = content[Run::Literal.to_s])  and return value
    (value = content[Run::Per_Se.to_s]) and return model.find(value.to_i)
    # receive all attributes(including virtual ones) in content and assign their values
    receiver = model.new(self.content)
    receiver.entity_id = self.entity_id
    
    # modify attributes if receiver has method "modifier!"
    begin
      receiver.respond_to?("modifier!") and receiver.modifier!
    rescue ActiveRecord::RecordInvalid => e
      set_of_all_errors << e
    end
    
    since = receiver.send(Run::Since)
    # demanded since for root entity
    root_entity.nil? and root_since = since
    # default root_entity
    root_since ||= Run.get_action_time
    # since setting for dependees and depandants
    since ||=  root_since

    locked_states = receiver._received_states_to_be_locked_    
  
    Run.transaction do    
            
      # put dependees if any and connect them to receiver.
      # if no dependee given, disconnect association with dependee.
      receiver._assoc_dependee.to_a.each do |assoc|
        assoc.assoc_entity = receiver
        dependee_refs = assoc.map(&:to_entity_ref).select{ |t| t.content[Run::Assoc_Deleted.to_s].blank? }
        if dependee_refs.blank?
          assoc.disconnect()  # disconnect association to dependee.
        elsif dependee_refs.size > 1
          fail ArgumentError, "dependee should be only one."
        else
          dependee_ref = dependee_refs.first
          dependee = dependee_ref.put(receiver, root_since)
          assoc.connect(dependee)
          set_of_all_errors +=  (dependee.set_of_all_errors || [])
        end
      end
      
      # put pure part of receiver to DB; the result is pure_entity
      begin
        real_content = receiver.attributes
        pure_entity = 
          if new? 
            entity = model.new_run(real_content)
            entity.entity_id = self.entity_id
            entity.since = since
            entity.create_run!
          else
            update_content = extract_updating_content(real_content)
            original = model.find_entity(self.entity_id) 
            original.update_run!(since, update_content, locked_states)
          end
      rescue ActiveRecord::RecordInvalid => e
        record = e.record # record with save validation errors
        record.set_of_all_errors = set_of_all_errors << e
        fail ActiveRecord::RecordInvalid.new(record)
      end
      
      # set root_entity pure_emntity at initial entry
      root_entity.nil? and root_entity = pure_entity

      # connect all dependants if any to the pure_entity and put them.
      receiver._assoc_dependant.to_a.each do |assoc|
        assoc.assoc_entity = pure_entity
        assoc.each do |target_ref_list|
          target_ref_list.keys.each do |key|
            target_ref = {key => target_ref_list[key]}.to_entity_ref 
            target_ref.content[Run::Assoc_Deleted.to_s].blank? ? 
               assoc.connect(target_ref) : assoc.disconnect(target_ref)
            dependant = target_ref.put(root_entity, root_since)
            set_of_all_errors += (dependant.set_of_all_errors || [])
          end
        end
      end
    end
    root_entity.set_of_all_errors = set_of_all_errors
    return root_entity
  end
  
  # transform to Run active entity, no save to DB as put does.
  # "default_since" is forced since as default
  #   "if default_since" is nil, since is unchanged.
  def to_entity(default_since = nil)
    (value = content[Run::Literal.to_s])  and return value
    (value = content[Run::Per_Se.to_s]) and return model.find(value.to_i)
    
    pure_entity = model.find_entity(entity_id)
    default_since and pure_entity.since = default_since
 
    receiver = model.new
    # set value for only respondable attributes in content
    content.each_key do |attr|
      receiver.respond_to?("#{attr}=") and receiver.send("#{attr}=", content[attr.to_s])
    end
    receiver._assoc_dependee.to_a.each do |assoc|
      pure_entity.send("#{assoc.assoc_name}=", assoc.map(&:to_entity_ref).map(&:to_entity))
    end
    receiver._assoc_dependant.to_a.each do |assoc|
      # assoc might be an array due to parameter construction by RAILS
      entity_hash_list = assoc.is_a?(Array) ? assoc.first : assoc
      value = 
        entity_hash_list.keys.inject([]) do |sum, key|
          sum << {key => entity_hash_list[key]}.to_entity_ref.to_entity(default_since)
        end
      pure_entity.send("#{assoc.assoc_name}=", value)
    end
    return pure_entity
  end
  
  private
  
  def extract_updating_content(real_content)
    # normalize select_time parameters with "(i)" in Rails
    real_content_keys = real_content.keys.map(&:to_s)
    real_content_keys.inject({}) do |result, key|
      real_content[key] and result.merge!(key => real_content[key])
      result
    end 
  end

end


#  **** end of EntityRef ******


# extension of Array as proxy of associated collection
# see Run#association
class Association < Array
 
  # "assoc_entity" is associated with "assoc_targets"
  # assoc_attrs...
  #    assoc_name... name of association
  #    assoc_target_type... either :dependant or :dependee, showing dependency between assoc_entity and assoc_targets
  #    target_model... model of assoc_targets.
  #    connection_factors... array of condition_pairs(= [pre_table.pre_column, pos_table.pos_column])
  Assoc_Attrs = [:assoc_name, :assoc_target_type, :assoc_entity, :target_model, :connection_factors]
  attr_accessor *Assoc_Attrs
  
  Self_Entity = "__self__"  # Run's Self_Entity
  
  # for :dependant type
  def move_assoc_attrs_from!(entity)
    Assoc_Attrs.each do |attr|
      self.send("#{attr}=", entity.send(attr))
    end
    self
  end
  
  # for :dependee type
  def move_assoc_attrs_to!(entity)
    Assoc_Attrs.each do |attr|
      entity.send("#{attr}=", send(attr))
    end
    entity
  end
  
  # add target content to association
  def build(target = nil)
    target.is_a?(Array) and return target.each do |t| build(t) end
    
    target_existing = target.is_a?(Run)
    content = target_existing ? target.attributes : target 
    content ||= {}

    case assoc_target_type
      when :dependee
        # assoc_entity is dependant
        added_entity = target_existing ? target : target_model.new_run(content)
        connect(added_entity)
        assoc_entity.send("#{assoc_name}=", [added_entity]) # dependee is only one so make association empty before adding
      when :dependant
        # assoc_entity is dependee.
        # default since of assoc_target is assoc_entity.since.
        content[Run::Since] ||= assoc_entity.send(Run::Since)
        target_ref = EntityRef.new({"new#{Run::ID_Model_Separator}#{target_model.name}" => content})
        connect(target_ref)
        added_entity = target_model.new_run(target_ref.content) 
        assoc_targets = assoc_entity.send("#{assoc_name}") || []
        assoc_entity.send("#{assoc_name}=", assoc_targets << added_entity)
      else
        fail "assoc_target_type is expected to be :dependant or :dependee."
    end
    return added_entity
  end
  
  # connect target to self association
  # assoc_target_type shows dependency; :dependant or :dependee
  def connect(target)
    connection_factors.to_a.each do |cond|
      if cond.is_a?(Array)
        precond, poscond = cond
        pre, pos = precond.split('.'), poscond.split('.')
        case assoc_target_type
          when :dependee  # target is dependee and an entity; assoc_entity is dependant and an entity. 
            if pos.first == Self_Entity
              value = pre.first == target_model.table_name ? target.send(pre.last) : pre.first
              self.assoc_entity.send "#{pos.last}=", value
            elsif pre.first == Self_Entity
              value = pos.first == target_model.table_name ? target.send(pos.last) : pos.first
              self.assoc_entity.send "#{pre.last}=", value
            end
          when :dependant  # target is dependant and an EntityRef; assoc_entity is dependee and an entity.
            if pos.first == target.table_name
              target.content[pos.last] =  (pre.first == Self_Entity ? assoc_entity.send(pre.last) : pre.first)
            elsif pre.first == target.table_name
              target.content[pre.last] =  (pos.first == Self_Entity ? assoc_entity.send(pos.last) : pos.first)
            end
        end
      end
    end
  end
  
  def disconnect(target_ref = nil)
    connection_factors.to_a.each do |cond|
        if cond.is_a?(Array)
          precond, poscond = cond
          pre, pos = precond.split('.'), poscond.split('.')
          case assoc_target_type
            when :dependee  # dependant is assoc_entity. target is dependee and an entity
              if pre.first == target_model.table_name && pos.first == Self_Entity
                self.assoc_entity.send "#{pos.last}=",  0 # don't set nil, since nil means "keep original value".
              elsif pos.first == target_model.table_name && pre.first == Self_Entity
                self.assoc_entity.send "#{pre.last}=", 0 # don't set nil, since nil means "keep original value".
              end
            when :dependant  # dependant is assoc_target and an EntityRef. assoc_entity is dependee and an entity.
              target_ref.is_a?(EntityRef) or fail ArgumentError, "#{target_ref.inspect} should be an EntityRef."
              if pos.first == target_ref.table_name && pre.first == Self_Entity
                target_ref.content[pos.last] =  0  # don't set nil, since nil means "keep original value".
              elsif pre.first == target_ref.table_name && pos.first == Self_Entity
                target_ref.content[pre.last] =  0  # don't set nil, since nil means "keep original value".
              end
          end
        end
    end
  end
  
  def to_assocs
    self
  end

end



# root of classes of runnable entities
# see intrasite2/doc for concepts and details.

# common attributes of runnable entities
# each record represents a state of an entity

#  run_id             :integer(11)     # runnable entity's id
#  name               :string(255)     # entity name at the state
#  since              :datetime        # when the state starts
#  till               :datetime        # when the state ends. default is Future.
#  created_at         :datetime        # when the record starts
#  created_by         :integer(11)     # user who created the record(current_user.run_id)
#  deleted_at         :datetime        # when the record deleted. default is Future.
#  deleted_by         :integer(11)     # user who deleted the record(current_user.run_id)
#  parent_run_id      :integer(11)     # parent entity in tree structure
#  seq                :string(255)     # sequencial code in ordered list of entities
#  fullseq            :text            # full seq code in ordered tree structure of entities
#  fullseq_sub        :text            # for representing fullseq as sub part of other entities' fullseq
#  fullname           :text            # fullname in tree structure
#  merged_to          :integer(11)     # entity merged to
#  split_from         :integer(11)     # entity split from
#  simulation_mode    :boolian         # true when created in simulation mode

class Run < ActiveRecord::Base
  
  self.abstract_class = true
  
  attr_protected :id
  
  # id for new record(not saved in DB yet)
  attr_accessor :id_for_new
  
  # errors with entity; should be a set since entity could be composite
  attr_accessor :set_of_all_errors
    
  # collection to be built
  attr_accessor :_to_be_associated
  
  # association attributes for assoc_target entity
  attr_accessor :assoc_name, :assoc_target_type, :assoc_entity, :target_model, :connection_factors
  
  # virtual attribute to receive list of associations
  attr_accessor :_assoc_dependee, :_assoc_dependant
  
  validate :valid_and_exist_terms_for_state?
  
  # special attributes for assoc_target entity to show named entity's type
  Literal, Per_Se, Assoc_Deleted = :_literal_, :_per_se_, :_assoc_deleted_
  Assoc_Target_Attributes = [Literal, Per_Se, Assoc_Deleted]
  attr_accessor *Assoc_Target_Attributes
  
  States_Separator = ','
   
  # for entity_id of id and model_name
  ID_Model_Separator = ":"
  # override for identifying an entity with id and its model
  def to_param
    model_name = self.class.name
    if new_record?
      self.id_for_new ||= "new#{random_id}#{ID_Model_Separator}#{model_name}"
    else
       "#{self.id}#{ID_Model_Separator}#{model_name}"
    end
  end
  
  def entity_id
    @entity_id || to_param
  end
  
  def entity_id=(value)
    @entity_id = value
  end

  # genereate string to show list of states in current history
  # for use in optimistic lock.
  def _states_to_be_locked
    new_record? ? nil : history(:assert_time => :anytime).map(&:id).sort.join(States_Separator)
  end
    
  # virtual attributes for optimistic lock
  # the value is at the time of rendering for committing.
  def _states_to_be_locked=(list_of_ids)
    @_received_states_to_be_locked_ = list_of_ids
  end
  
  def _received_states_to_be_locked_
    @_received_states_to_be_locked_
  end

  # AttachedFiles 
  # Link Method ( By Toshy Namimatsu)
  def attached_files_connection(checksums,time="base")
    checksums or return false
    cond = "checksum = '" + checksums.join("' or checksum = '") + "'"
    a = AttachedFile.find(:all,:scope=>":self",:conditions=>cond)
    AttachedFile.transaction do 
      a.each do |aa|
        since = aa.since
        since = self.since if time=="self"
        t = aa.attributes
        t[:file_attachable_run_id]=self.run_id
        t[:file_attachable_type]=self.class.to_s
        aa.update_run!(since, t)
      end
      ActiveRecord::Base.connection.execute("DELETE FROM attached_files where file_attachable_run_id=#{self.run_id} and file_attachable_type='#{self.class.to_s}' and checksum IS NULL")
    end
  end
  
  # uuid generator
  def random_id
    UUIDTools::UUID.random_create.to_s.gsub(/ID_Model_Separator/, "")
  end
  
  # convert run entity to entity_ref format
  # option1 ...
  #   nil ... full set of attributes with associated entities
  #   :no_assocs ...  without associatiated entities.
  #   :only_primary_attributes ... only id and run_id attributes for entities including associated entities.
  # assoc_ref ... Hash. value should be array of strings of assoc names.
  #   :only   ...  assocs to include
  #   :except ... exclude assocs to include
  def to_entity_ref(option1 = nil, assoc_ref = {})
    entity_id = self.to_param
    content = {}
    attributes.each_pair do |attr, value|
      if value.is_a?(Time) or value.is_a?(DateTime)
        # transform time attributes to db strings to keep coherency of time format.
        value = value.to_s(:db)
      end
      if [:no_assocs, :only_primary_attributes].include?(option1)
        if Primary_Attributes.include?(attr.to_s)
          content.merge! attr => value 
        end
      else
        content.merge! attr => value   
      end
    end 
    option1 == :no_assocs and return EntityRef.new( entity_id => content )
  
    # for associations
    _assoc_dependee.to_a.each do |assoc|
       content.merge! assoc.assoc_name => assoc.first.to_entity_ref(option1)
    end
    _assoc_dependant.to_a.each do |assoc|
      if assoc_ref.blank? || ((assoc_ref[:only] && assoc_ref[:only].include?(assoc.assoc_name.to_s)) || (assoc_ref[:exclude] && !assoc_ref[:exclude].include?(assoc.assoc_name.to_s)))
        assoc_content = []
        assoc.each do |target|
          target_ref = target.to_entity_ref(option1)
          assoc_content <<  target_ref
        end
        content.merge! assoc.assoc_name => assoc_content
      end
    end
    EntityRef.new( entity_id => content )
  end
  
  # default controller name to handle 
  def controller_name
    self.class.name.underscore.pluralize
  end
 
  
  # characters in seq code  
  Chars = ((0.to_s..9.to_s).to_a + ("A".."Z").to_a + ("a".."z").to_a).sort
  Zero, One, Pre_Omega, Omega = Chars[0], Chars[1], Chars[-2], Chars[-1]
  
  #---
  # all records are states of runnable entities(runs)

  Id      = "id"
  
  # column name of run's surrogate ID
  Run_id = "run_id"
  
  Type    = "type"
  
  # column names of state term for runnable entities
  Since = "since"
  Till  = "till"
  
  # column names for recording of state
  Created_at   = "created_at"
  Deleted_at   = "deleted_at"
  Created_by   = "created_by"   # user_info_run_id
  Deleted_by   = "deleted_by"   # user_info_run_id
  Updated_to   = "updated_to"   # id updated to

  Primary_Attributes = [Id, Run_id]
  
  # column names of sequencial code, its full path code and its subordinate path code
  # for building and retrieving ordered hierarchy
  Seq         = "seq"
  Fullseq     = "fullseq"
  Fullseq_sub = "fullseq_sub"
  
  # column names for name and full name
  Name        = "name"
  Fullname    = "fullname"
  # hierarchical level separator
  Level_Separator = '|'
  
  # column name for hierarchical tree parent
  Parent_run_id = "parent_run_id"
  
  # column names for merge and split of objects
  Merged_to   = "merged_to"
  Split_from  = "split_from"
  
  # column name for simulation mode; if recorded in simulation mode, set true.
  Simulation_Mode = "simulation_mode"

  # partial a_net for organization structure
  Organization_A_Net = " *organized_entity << :Organization[(.affiliation_run_id >> affiliation:Affiliation)
                                                            (.status_run_id      >> status:Status)     ] "

  @@current_account = @@current_user =  nil  
  @@simulation_mode = nil
  
  # owner of each run(entity)
  def run
    run_id = self.class.find(self.id).send(Run_id)
    self.class.find(run_id)
  end
  
  # set current(now) state of account specified by its id.
  def self.set_current_account(account_id)
    @@current_account = Account.find(account_id)
  end
  
  # current_user corresponding to current_account
  def self.set_current_user
    @@current_account or return @@current_user = nil
    @@current_user = @@current_account.user_info
  end
  
  def self.current_account
    @@current_account
  end
  
  # for virtual setting
  def self.current_account=(account)
    @@current_account = account
    set_current_user
    return @@current_account
  end
  
  # current_user's current state with main affiliation_name(fullname), main status_name(fullname) and category
  def self.current_user
    @@current_user or return nil
    @@current_user.current_state_in_organization
  end
  
  # state at @@action_time
  # "args" are to find args; if no args, set as :first
  def current_state(*args)
    states_at_action(@@show_time, *args).first
  end
  
  def self.current_state(id, *args)
    find(id).current_state(*args)
  rescue
    return nil
  end
  
  # is self(state) exist and valid at time?
  def current_state?(time = @@show_time)
    (created_at <= time  && time <= deleted_at) && (since <= time && time <= till)
  end
  
  # all states(sequence of states) of run of self(state) which exist at @show_time
  # options are options for find to be added.
  # options[:assert_time] is span for history; if nil, :assert_time is set to :anytime meaning Past..Future
  def history(options = {})
    self.class.history(self.id, options)
  end
  
  def self.history(id, options = {})
    state = find(id)
    # should be run find.
    options[:scope] ||= ":self"
    cond = merge_conditions(options.delete(:conditions), {Run_id.to_sym => state.run_id})
    options.update :conditions => cond, :order => "#{self.table_name}.#{Since}"
    options[:group] ||= Id
    temp_a_time = get_assert_time # save for restoring assert_time
    self.assert_time = options.delete(:assert_time) || :anytime
    result = find :all, options
    self.assert_time = temp_a_time
    result
  end
  
  def parent(options = {})
    self.class.find :first, options.merge(:scope => :self, :conditions => {Parent_run_id.to_sym => self.parent_run_id})
  end
  
  def self.query_by_real_name(real_name)
    query_by(:real_name, real_name)
  end
  
  def self.query_by_name(name)
    query_by(:name, name)
  end
  
  # find by name and its author_name(real_name of created_by)
  # if author_name is blank, do not care about author.
  def self.query_by_name_with_author_name(name, author_name)
    name_cond = name.blank? ? nil : ["#{table_name}.name LIKE :name", {:name => ('%' + name + '%')}]
    author_name_cond = author_name.blank? ? nil : ["user_infos.real_name LIKE :author_name", {:author_name => ('%' + author_name + '%')}]
    find :all, :scope => ":self .created_by >> :UserInfo",
           :select => {:id => ".id", :run_id => ".run_id", :name => ".name", :author_name => "user_infos.real_name"},
           :conditions => merge_conditions(name_cond, author_name_cond),
           :group  => "#{table_name}.id"    
  end
  
  # query by attr value; get entities with attribute of which value includes "value"
  def self.query_by(attr, value)
    column_names.include?(attr.to_s) or fail "{attr} should be a column."
    find :all, :scope => ":self",
         :conditions => ["#{attr} LIKE :#{attr}", {attr => '%' + value + '%'}],
         :group  => Id   
  end

  # name attribute handling
  # attribute "name" is a string which may contain multiple names with IN_Seperarer(Comma) below.
  # multiple name examples : labels for article_thread and article, user_category for article

  # separator of SQL IN operand set
  IN_Separator = ','
  
  def name_include?(string)
    string.is_a?(String) or fail "string is expected for '#{string}'."
    name && name.split(IN_Separator).map(&:strip).include?( string )
  end
  
  def add_name(since, string)
    since.is_a?(DateTime) or fail "datetime is expected for '#{since}'"
    string.is_a?(String) or fail "string is expected for '#{string}'."
    new_name = (name.split(IN_Separator).map(&:strip) << string).uniq.join(IN_Separator)
    update_run! since, :name => new_name   
  end
  
  def remove_name(since, string)
    since.is_a?(DateTime) or fail "datetime is expected for '#{since}'"
    string.is_a?(String) or fail "string is expected for '#{string}'."
    new_name = (name.split(IN_Separator).map(&:strip) - [string]).join(IN_Separator)
    update_run! since, :name => new_name    
  end

  #.........  TEMPOLARITY .................................#

  # time is supposed to be discrete with quantum time
  
  # simulate infinite past and future
  # should use DateTime, not Time
  # db time is local time.
  Past_db   = "0000-01-01 00:00:00"
  Future_db = "9999-12-31 23:59:59"
  Past      = Past_db.to_datetime(:local)
  Future    = Future_db.to_datetime(:local)
  @@show_time = @@assert_time = @@action_time = @@pred_action_time = nil
  # hash setting of local assert(show) time
  # key => name of entity; value => assert_time for the entity
  @@local_assert_time_setting = {}
  @@local_show_time_setting   = {}

  # time granularity(quantum time) in second
  QTIME = 1
   
  # the time to do action to records of runnable entities
  # should be set in Controller
  def self.action_time=(time=DateTime.now)
    verify_time_type(time)
    @@action_time = time.to_datetime
  end
  
  def self.get_action_time
    @@action_time || DateTime.now
  end
 
  # "time" below can be range to cover time span

  # "show_time" is the time to get existing records of runnable entities 
  # should be set in Controller
  def self.show_time=(time=nil)
    time ||= @@action_time
    verify_time_type(time)
    @@show_time = time
  end
  
  def self.get_show_time(entity_name = nil)
    local_show_time(entity_name) || @@show_time || DateTime.now
  end
  
  # get show time in db format
  def self.get_show_time_db(entity_name = nil)
    time_to_db get_show_time(entity_name)
  end
  
  # "assert_time" is the time to see states of runnable entities
  # "time" can be table column name(symbol), ex. ":article.datetime" in schedule article
  # "time" can be time span as range of time
  # if "time" is :anytime, all valid conditions are TRUE regardless of entity's valid term.
  # if "time" is :show_time, it is @@show_time
  def self.assert_time=(time=nil)
    time ||= :show_time
    time == :show_time and time = get_show_time
    verify_time_type(time)
    @@assert_time = time
  end
  
  def self.get_assert_time(entity_name = nil)
    local_assert_time(entity_name) || @@assert_time || get_show_time
  end
  
  # get assert_time in db format
  def self.get_assert_time_db(entity_name = nil)
    time_to_db get_assert_time(entity_name)
  end
  
  # "年度" of time
  def self.get_academic_year(time = @@show_time)
     time.year - ((1..3).include?(time.month) ? 1 : 0)
  end
  
  def self.get_academic_year_range_for_time(time = @@show_time)
    ac_year = get_academic_year(time)
    "#{ac_year}-04-01 00:00:00".."#{ac_year.to_i + 1}-03-31 23:59:59"
  end
  
  def self.get_academic_year_range_cond(table_name, attr_name = :since, time = @@show_time)
    academic_year_range = get_academic_year_range_for_time(time)
    return "#{table_name}.#{attr_name} BETWEEN '#{academic_year_range.begin}' AND '#{academic_year_range.end}'"
  end
  
  # "学期" of time
  def self.get_academic_season(time = @@show_time)
    time == :all  and return "春,秋"
     (4..8).include?(time.month) ? "春" : "秋"
  end
  
  def self.get_academic_season_range_for_time(time = @@show_time)
    ac_year  = get_academic_year(time)
    ac_season = get_academic_season(time)
    academic_season_time_range(ac_year, ac_season)
  end
  
  # range is given in db format
  def self.academic_season_time_range(ac_year = nil, ac_season = nil)
    ac_year = ac_year.blank? ? get_academic_year(@@show_time) : ac_year
    case ac_season
      when "春", "前"
        "#{ac_year}-04-01 00:00:00".."#{ac_year}-08-31 23:59:59"
      when "秋", "後"
        "#{ac_year}-09-01 00:00:00".."#{ac_year.to_i + 1}-03-31 23:59:59"
      else
        "#{ac_year}-04-01 00:00:00".."#{ac_year.to_i + 1}-03-31 23:59:59"
    end     
  end
  
  # simulation mode accessor
  def self.simulation_mode
    @@simulation_mode
  end
  
  def self.simulation_mode=(boolian)
    @@simulation_mode = boolian
  end 
  
  #................................................................#
  #                CRUD on Runnable Entities operations                                 #
  #................................................................#

  #................FIND and CALCULATE operations .................................#
  
  # find runnable entities in model complex scoped by :scope option.
  # without :scope option, perform pure find.
  # CAUTION: dynamic find methods such as find_by_a_and_b cannnot be applied; Use conditions
  def self.find(*args)
    options = get_options_from_args!(args)

    # for :distinct option
    if distinct = options.delete(:distinct)
      options[:select] = "DISTINCT " + hash_select_to_strings(distinct)
    end
    
    # change hash form :select option to strings for SQL SELECT
    options[:select] = hash_select_to_strings(options[:select])
    
    a_net = options.delete(:scope)
    # without :scope option, 
    return super(*(args << options)) unless (a_net)

    # for temporal saving of global show and assert time in find operation
    if s_time = options.delete(:show_time)
      temp_show_time = @@show_time
      self.show_time = s_time
    end
    if a_time = options.delete(:assert_time)
      temp_assert_time = @@assert_time
      self.assert_time = a_time
    end
    
    @@local_assert_time_setting = options.delete(:local_assert_time) || {}
    @@local_show_time_setting   = options.delete(:local_show_time) || {}

    # with :scope option, 
    a_net == :self and a_net = ":self" # special a_net, only using timing conditions.
    scope = a_net_to_scope(a_net)
    result = with_scope(:find => {:joins => scope[:joins], :conditions => scope[:conditions]}) do
      super(*(args << options)) 
    end

    # recovery of global show and assert time
    s_time and @@show_time   = temp_show_time
    a_time and @@assert_time = temp_assert_time
    
    return result
  end
   
  def self.get_options_from_args!(args)
    args.blank? and return {}
    if args.respond_to?(:extract_options!)
      args.extract_options!
    else
      extract_options_from_args!(args)
    end    
  end

  
  
  # ---  methods for association ---

  # extension of belongs_to. has_one, has_many definisitons and associated actions
  # "dependency is type of dependency of target; :dependee or :dependant
  # "target_model_name" is the targetted entities' model name.
  # "assoc_net" gives association from target to self
  #    ":self" in "assoc_net" designifies self model.
  # "options" are default options for associatee(s) to find
  def self.define_association(assoc_name, dependency, target_model_name, assoc_net, options = {})
    [:dependee, :dependant].include?(dependency) or fail "#{dependant} is illegal."
          
    # get assoc targets and set the result to "_assoc_#{dependency}" attribute if not obtained yet.
    define_method assoc_name do |*args|
      # return assoc if already on "_assoc_#{dependency}"
      assoc_list = send("_assoc_#{dependency}").to_a
      registered = assoc_list.detect{|assoc| assoc.assoc_name.to_s == assoc_name.to_s}
      if registered
        dependency == :dependant and return registered
        if dependency == :dependee
          dependee = registered.first  # registered is [dependee] i.e. Array with single element.
          return registered.move_assoc_attrs_to!(dependee)
        end
        fail "#{registered.inspect} is wrong registered association on _assoc_dependency."
      end
    
      # load from db.
      # order to display assoc targets
      options[:order] ||= target_model_name.to_model.table_name + ".seq"  # CAUTION: DO NOT use here Run.get_table_name(model_name)

      new_options =  options.merge( Run.get_options_from_args!(args) )
      # for setting assoc_net dynamically
      assoc_net = new_options.delete(:assoc_net) || assoc_net
      targets = get_assoc_targets( target_model_name, assoc_net, dependency, assoc_name, *(args << new_options) )
      # set targets as assoc attribute value.
      self.send "#{assoc_name}=", targets
      return targets
    end
    
    # add new entity with its attributes
    define_method "build_#{assoc_name}" do |*args|
      attrs = *args  # expecting only attributes(Hash).
      assoc_builder( attrs, dependency, target_model_name, assoc_net, assoc_name )
    end
    
    # setter for association
    # register association with its assoc_target(s) on "_assoc_#{dependency}" attribute
    # each of targets is hash when receiving from params.
    define_method "#{assoc_name}=" do |target|
      target.blank? and return
      targets = target.is_a?(Array) ? target : [target]  # when dependee, target results as single.
      send "_assoc_#{dependency}=", send("_assoc_#{dependency}").to_a <<  new_assoc(targets, target_model_name, assoc_net, dependency, assoc_name)
    end
    
    # get and set assoc_targets
    define_method "#{assoc_name}!" do |*args|
      targets = send(assoc_name, *args)
      self.send "#{assoc_name}=", targets
      return targets
    end
  end
  
  # find generally associated entitie(s) as attribute of an entity instance(self)
  # if top of args is a symbol, it is assoc_name which is different from target_modle_name.to_assoc_name.
  def association(target_model_name, assoc_net, assoc_target_type, *args)
    assoc_name = args.first.is_a?(Symbol) ? args.shift.to_s : nil
    options = Run.get_options_from_args!(args).to_h.dup 
    options[:scope] =  assoc_scope(assoc_net)
    collection = [] 
    assoc = new_assoc(collection, target_model_name, assoc_net, assoc_target_type, assoc_name)
    if new_record?   # assoc_entity is not recorded(saved) yet
      connection_conds = connection_conditions_from(assoc.connection_factors)
      unless connection_conds.blank? 
        options[:conditions] = Run.merge_conditions(options[:conditions].to_a, *connection_conds) 
        collection +=  assoc.target_model.find(:all, *(args << options)).to_a
      end
    else  # self has been saved.
      connection_cond =  "#{Self_Entity}.run_id = #{self.run_id}"
      options[:conditions] = Run.merge_conditions(options[:conditions], connection_cond)
      collection +=  assoc.target_model.find(:all, *(args << options)).to_a
    end
    Association.new(collection).move_assoc_attrs_from!(assoc)
  end
  
  # generate new association with collection of targets
  # targets are either entity or entity_ref
  def new_assoc(targets, target_model_name, assoc_net, assoc_target_type, assoc_name = nil)
    assoc_name ||= target_model_name.to_assoc_name(assoc_target_type)
    assoc = Association.new(targets)
    assoc.assoc_name = assoc_name
    assoc.connection_factors = get_assoc_connection_factors(target_model_name, assoc_net)
    assoc.assoc_entity = self
    assoc.target_model = target_model_name.to_model
    assoc.assoc_target_type   = assoc_target_type
    assoc
  end
  
  # association of received target(s)
  def received_assoc(list_of_targets, target_model_name, assoc_net, assoc_target_type, assoc_name = nil, options = {})
    list_of_targets ||= {}
    if list_of_targets.is_a?(Hash)  # from input params of view page.
      target_refs = []
      # hash to array of entity_refs
      list_of_targets.each_key do |name|
        content = list_of_targets[name]  
        target_refs << EntityRef.new( {name => content} )
      end
    else  # for output to view page
      target_refs = list_of_targets
    end
    new_assoc(target_refs, target_model_name, assoc_net, assoc_target_type, assoc_name)
  end

  # collection associated with self via assoc_net
  def associated_with(target_model_name, assoc_net, *args)
    association target_model_name, assoc_net, :dependant, *args
  end
  
  # get association target(s) following its dependency.
  def get_assoc_targets(target_model_name, assoc_net, dependency, *args)
    assoc = association(target_model_name, assoc_net, dependency, *args)
    case dependency
      when :dependee
        assoc.blank? ? assoc :  assoc.move_assoc_attrs_to!(assoc.first )
      when :dependant
        assoc
      else
        fail "'#{depedency}' is illegal as dependency of association."
    end      
  end
  
  def assoc_dependee(target_model_name, assoc_net, *args)
    get_assoc_targets(target_model_name, assoc_net, *([:dependee] + args))
  end
  
  def assoc_dependant(target_model_name, assoc_net, *args)
    get_assoc_targets(target_model_name, assoc_net, *([:dependant] + args))
  end

  # for "build_#{assoc_name}" method called in define_association.
  def assoc_builder(attrs, dependency, target_model_name, assoc_net, assoc_name = nil)
    assoc = association( target_model_name, assoc_net, dependency, assoc_name )
    case dependency
      when :dependee
         Association.new([]).move_assoc_attrs_from!(assoc).build(attrs)
      when :dependant
         assoc.build(attrs) 
    end
  end
  
  # for putting "dependant" target_refs
  # assoc_targets depending on assoc_entity.
  def dependant(assoc_targets, target_model_name, assoc_net, assoc_name = nil, options = {})
    @_assoc_dependant =  @_assoc_dependant.to_a <<
       new_assoc(assoc_targets, target_model_name, assoc_net, :dependant, assoc_name) 
  end

  # for putting "dependee" target_refs.
  # assoc_entity depends on assoc_targets.
  def dependee(assoc_targets, target_model_name, assoc_net, assoc_name = nil, options = {})
    @_assoc_dependee = @_assoc_dependee.to_a << 
       new_assoc(assoc_targets, target_model_name, assoc_net, :dependee, assoc_name)
  end
     
  # for organizations association  
  define_association :organizations, :dependant, 
                     "Organization",
                     " [( >> *organized_entity :self)
                        ( .affiliation_run_id >> aff:Affiliation)
                        ( .status_run_id      >> sta:Status)]",
                     :group => "organizations.id",
                     :order => "organizations.seq, organizations.since, aff.fullseq, sta.fullseq" 
 
  # attached file entities associated to self entity
  define_association :attached_files, :dependant,
                      "AttachedFile", ">> *file_attachable :self",
                      :group => "attached_files.id"
  
  # for members association
  define_association :members, :dependant, 
                     "Member", "[(>> *memberable :self)(-> user:UserInfo)]",
                     :group => "members.id",
                     :order => "members.description DESC"
                     
  # for questions of questionnaires
  define_association :questionnaires, :dependant,
                     "Questionnaire", "[(>> *questionnairable :self)(~<< :Answer)]",
                     :group => "questionnaires.id"

  
  # transfer assoc targets of "assoc_name"(associationa) to "new_owner"
  def move_assocs(assoc_name, new_owner)
    original_targets = send(assoc_name)
    new_owner.send(assoc_name).build original_targets
  end
  
  def connection_conditions_from(connection_factors)
    connection_factors.blank? and return
    connection_factors.inject([]) do |sum, pair|
      pre, pos = *pair
      sum << cond_for_assocs_from(pre, pos)
      sum << cond_for_assocs_from(pos, pre)
    end.compact
  end
  
  # condition for Self_Entity in association definition
  def cond_for_assocs_from(self_part, counter_part)
    self_entity, self_attr       = self_part.split(".").map(&:strip)
    counter_entity, counter_attr = counter_part.split(".").map(&:strip)
    self_entity == Self_Entity &&  (value = send(self_attr))  ? "#{counter_part} = #{value}" : nil      
  end
  
  # get association connection_factors from assoc_net.
  # for the moment, only direct association with "=" comparator.
  def get_assoc_connection_factors(target_model_name, assoc_net)
    target_model = target_model_name.to_model
    arrows = target_model.a_net_to_arrows(assoc_scope(assoc_net))
    assoc_arrows = arrows.detect do |arrow|      
       arrow.pre_value_ref.entity.name == Self_Entity && arrow.pos_value_ref.entity.model_name == target_model_name or
       arrow.pre_value_ref.entity.model_name == target_model_name && arrow.pos_value_ref.entity.name == Self_Entity
    end    
    assoc_arrows.blank? and return # not direct association
    assoc_arrows.cond.split(" AND ").map {|c| c.strip.split("=").map(&:strip).map(&:strip_quotation)}
  end
  
  # ---  end of methods for association ---


  # change select option of find given by hash to strings for SQL SELECT statement
  # when items = nil given, return *  to select all column values
  # when string items given, return as is for select statement in SQL,
  # when hash given, return "value AS key.to_s" for each item in items.
  #   where the value omitts table name like  ".attr", the table name is compensated from self model.
  def self.hash_select_to_strings(items = nil)
    case items
    when NilClass  # neither :select nor :distinct option given
      return "DISTINCT #{table_name}.*"   # CAUTION: "DISTINCT" is attached to avoid to pick up multiple association. 
    when String  
      return items
    when Hash
      result = items.inject([]) do |s, key_value|
        key, value = key_value
        value.is_a?(String) or fail "value '#{value}' for select items should be a String."
        value.strip!
        # for omitting self table name
        value.start_with?('.') and value = table_name + value
        s << "#{value} AS #{key.to_s}" 
      end
      return result.join(", ")
    else
      fail "'#{items}' should be String or Hash."
    end  
  end
  
  # entity_id is expressed by string "id:Model"
  #   if id start with "new"; result is new entity 
  def self.find_entity(entity_id, options = {})
    entity_id or fail ArgumentError, "'entity_id' is nil. "
    id, model = entity_id.to_id_and_model
    model ||= self
    id.is_a?(Fixnum) ? model.find(id, options) : model.new_run(options)
  end
  
  
  # making public
  def self.with_scope(*args)
    super
  end
  
  def self.tree_root(all_or_one = :first, options = {})
    options[:scope] ||= ":self"
    options[:order] ||= "seq"
    result = with_scope(:find => {:conditions => "parent_run_id IS NULL OR parent_run_id = 0"}) do
      find all_or_one, options
    end
    result.blank? and fail "tree root of #{self.name} not found."
    result
  end
  
  # height of tree element
  def tree_height
    self.fullseq.nil? and return 0
    self.fullseq.count("|")
  end
  
  # self entity's children in tree model
  # options are any options for find
  def children(options ={})
    # default options
    options[:scope]  ||= ":self"
    options[:order]  ||= "seq"
    self.class.with_scope(:find => {:conditions => "#{self.run_id} = parent_run_id"}) do
      self.class.find(:all, options)
    end    
  end

  # monkey patching to RAILS2.1
  def self.calculate(operation, column_name, options = {})
    opt = {}.merge options
    if g = opt[:group]
      g.gsub!(/DESC/i, "")    # RAILS2.1 misrecognizes 'DESC' for :group options
    end
    super operation, column_name, opt
  end
  
  # make the private method in ActiveRecord::Base public for using in controller
  def self.merge_conditions(*conditions)
    super *(conditions.compact)
  end

  #..... Create, Update, Destroy Runnable Entities(Runs) ................#
  #      these are not operations on records(resources)                  #
  #      if something wrong happens, return nil                          #

  # initiate run with the first state of default attributes
  def self.new_run(attrs = {})
    attrs ||= {}
    attrs.stringify_keys!
    new  with_default_state_attrs(attrs) 
  end

     
  # altering entity

  
  # create run with initial state.
  # if succeed, return its record; if fail, return original new run with attrs and errors.
  def self.create_run!(attrs = {})   
    run = new_run(attrs)
    run.create_run!
  end
  
  def create_run!
    save!
    # set initial run_id
    update_attribute(:run_id, self.id)
    return self
  end
  
  def add_state!(attrs = {}, perform_validation = true)
    # inherit original run_id as new state of the run
    # entity_id is also inherited to hand over to errors info when failed during save!.
    new_state_attrs = attrs.merge(:run_id => self.run_id, :entity_id => self.entity_id)
    new_state = self.class.new_run( new_state_attrs )
    if new_state.save(perform_validation)
      return new_state
    else
      fail ActiveRecord::RecordInvalid.new(new_state)
    end
  end
  
  # setting default values for states with given attr for self's run
  # CAUTION: attrs hash's keys are strings not symbols
  # CAUTION: when set time to attrs, time should be in db format. if not, attrs time is set in UTC time!!
  def self.with_default_state_attrs(original_attrs = {})
    attrs = original_attrs.dup
    attrs.stringify_keys!
    cols = self.column_names
    attrs.delete(Id)
    attrs[Created_by]    = @@current_user.run_id  
    attrs[Created_at]    = @@action_time.to_s(:db) 
    attrs[Deleted_at]  ||= Future_db 
    attrs[Since]       ||= attrs[Created_at] 
    attrs[Till]        ||= Future_db
    attrs[Seq]         ||= One                          if cols.include? Seq
    attrs[Fullseq]     ||= One + Level_Separator        if cols.include? Fullseq
    attrs[Fullseq_sub]   = attrs[Fullseq] + "%"         if cols.include?(Fullseq) && cols.include?(Fullseq_sub)
    attrs[Simulation_Mode] ||= true                     if cols.include?(Simulation_Mode) && @@simulation_mode
    attrs
  end
  
  def with_default_state_attrs(attrs)
    self.class.with_default_state_attrs(attrs)
  end
  
  # update operations  
  # not idempotent operation
   
  # correct data of self(state)
  def correct!(change = {})
    update_run!(self.send(Since)..self.send(Till), change)
  end  
   
  # make run up to date from "since" to Future; "since" must be given explicitly. if :now, set as @@show_time.
  # "updating_attrs" is hash of attributes to update. updating_attrs["since"] is forced to be "since" argument value.
  #    updating_attrs keys are Strings.
  def update_run!(since = :now, updating_attrs = {}, locked_states = nil)
    since == :now || since.nil? and since = @@show_time
    till = updating_attrs["till"] ? updating_attrs["till"].to_datetime : Future
    # if updating_attrs is unchanging self, return self without updating
    changing_run?( updating_attrs, since, till) or return self
    state = self
    transaction do
      optimistic_lock!(locked_states)           # validate by optimisic lock
      state = update_run(since..till, updating_attrs)   # updating_attrs is to be validated to save
    end
    return state
  end
  
  # check if updating state is changed from states of original run(self).
  def changing_run?(updating_attrs, since, till)
    corresponding_state = history(:assert_time => (since..till)).detect do |s| s.since <= since && s.till >= till end or return true
    original_attrs = corresponding_state.attributes
    (updating_attrs.keys - ["since", "till"]).detect do |key| 
      original_attrs[key] != updating_attrs[key]
    end
  end
  
  # destroy entity operations

  # terminate run at 'time' - QTIME
  def self.destroy_run!(id, time)
    (state = find(id)) or fail "Entity does not exist."
    state.run.destroy_run!(time)
  end
  
  def destroy_run!(time = nil)
    time ||= @@show_time
    time.is_a? DateTime or fail "'#{time} must be a DateTime."
    delete_run!( time..Future )  # returns ids of states deleted
    self
  end
  
  # convert usual destroy and delete
  
  def self.destroy(id)
    admin_only and super
  end
  
  def destroy()
    admin_only and super
  end
  
  def self.destroy_all(conditions)
    admin_only and super(conditions)
  end

   
  # logically delete records of states of self's run in span time range
  # return set of ids of states deleted
  def delete_run!(span = (@@show_time..Future), time = @@action_time)
    # reject against anonymous user
    @@current_account && @@current_account.role != "guest" or fail
    span.is_a?(Range) or span = (span..Future)
    span.begin.is_a?(DateTime) || span.end.is_a?(DateTime) or fail "span '#{span}' must be Range of DateTime"
    
    delete_related_state_ids = []
    involved_states = history(:show_time => time.ago(QTIME), :assert_time => span)
    involved_states.blank? and return []
    delete_related_state_ids = involved_states.map(&:id)
    first_state, last_state = involved_states.first, involved_states.last
    delete_attrs = {Deleted_at => time.ago(QTIME).to_s(:db), Deleted_by => @@current_user.run_id}      
    transaction do
      # mark logical deletion to states even in the case that invalid state is originally saved with some reason.
      #  do not apply Rails "update" method since it veriifies when save.
      involved_states.each do |state|
        state.attributes = state.attributes.merge(delete_attrs)
        state.save(false)
      end
      # recreate first and last edge states of the run if overlapped in span
      if first_state.send(Since).to_s(:db) < span.begin.to_s(:db) && span.begin.to_s(:db) < first_state.send(Till).to_s(:db)
        attrs = first_state.attributes.update Till=> span.begin.ago(QTIME)
        attrs.delete(Created_at)
        attrs.delete(Deleted_at)
        attrs.delete(Deleted_by)
        state = add_state! attrs, false
        delete_related_state_ids << state.id
      end
      if last_state.send(Since).to_s(:db)< span.end.to_s(:db) && span.end.to_s(:db)< last_state.send(Till).to_s(:db)
        attrs = last_state.attributes.update Since => span.end.in(QTIME)
        attrs.delete(Created_at)
        attrs.delete(Deleted_at)
        attrs.delete(Deleted_by)
        state = add_state! attrs, false
        delete_related_state_ids << state.id
      end
    end
    delete_related_state_ids
  end
  
  #............  MERGE and SPLIT run operations ................................................#
  
  # merge runs to new_attr since time
  def self.merge_runs(time, new_attr, *runs)
    transaction do
      merged_run = create_run! time, new_attr
      fail unless merged_run
      runs.each do |r| 
        r.states_at_action(time).update_run! time, Merged_to => merged_run.send(Run_id)
        fail unless r.delete time.ago(QTIME)
      end
    end
    merged_run
  rescue
    return
  end
  
  # split self's run to split_attrs since time
  def split_run(time, split_attrs)
    transaction do
      fail unless delete time.ago(QTIME)
      split_runs = split_attrs.map do |attr| 
        new_run = self.create_run! time, attr.update(Split_from => self.send(Run_id))
        fail unless new_run 
      end
    end
    split_runs
  rescue
    return
  end
 
  #---
  
  #...............  a_net to express model complex of scope for finding  .....2007/11/30

  # terminology and syntax 
  #  <, >, ||, + are meta symbols
  #  "<x>" means that x is ommittable.
  #  "x || y"  means x OR y
  #  "x+"  means x is more than one time repeatable.
  # a_net is an expression or array of expressions
  #   expression   := entity_list || [(left_end_branch)+] entity_list || entity_list [(right_end_branch)+]
  #   entity_list  := Entity || Entity assoc_list Entity                   
  #   left_end_branch  := Entity assoc_list                         # Entitty is the end of branch.
  #   right_end_branch := assoc_list Entity
  #   assoc_list   := assoc <entity_list assoc> || [(route)+]       # the latter expresses parallel routes between entities
  #   assoc        := <Polymorphic> <Attr> Op <Attr> <Polymorphic>  # Op is association operator. If Attr omitted, defalt value is assigned.
  #   route        := assoc_list || branch
  #   branch       := left_end_branch || right_end_branch           
  #   Entity       := Literal || Variable                           
  #   Literal       see literal pattern defined below      
  #   Variable     := <name>:Model                                  # variable entity on Model. corresponding to sql table. can be ":self" for self model.
  #                                                                 # when name is omitted, the table name of the Model is given.
  #                                                                 # the base model cannot have entity name different from the table name, since RAILS does not recognize the aliasing name for the table.

  #   Polymorphic  := *name                                         # name of polymorphic referee of "<<", corresponding to ":as" in "has_many"
  #   Attr         := .name                                         # corresponding to columns of sql tables
  #   Elem         := Literal || Variable || Polymorphic || Attr || Op           # elements of network
  

  # association operators
  # association is a binary directed relation between models with association operator.
  #  "~" means "partial association" i.e. "any instance of the model of this side has possibly no counterpart instance of the model of the other side".
  # two types of operators
  #  reference type
  #   ">>" means "refers to", "belongs to" or "depends on" and the reverse is "<<" ("has_many")
  #   "->" means the same except the reverse "<-" means "has_one"
  #    example: car to owner
  #     ">>"   :  all cars corresponds to one and only one owner, and all owners have at least one car."epimorphism". "epimorphism"
  #     ">>~"  :  some owners may have no car. "morphism"
  #     "~>>"  :  some cars may not correnspond to any owner, but any owner has his/her car. "partial morphism"
  #     "~>>~" :  some of both may not have their counterpart. 
  #     "=="   :  injection
  #  comparison type
  #   "contains" means super or equal in partial order set(tree). "contained by" is the reverse
  #   "x includes y" means x LIKE CONCAT('%', y, '%') of SQL and "in" is its reverse. CAUTION: "in" is not "IN" of SQL.
  #   SQL comparison operator or logical operator can be used if it is binary. 
  #   non binary operators such as BETWEEN or IN are not available yet.
  #   comparison operators intensionally express  "join model" standing for many_to_many relations.
  
  Association_ops  = %w{<< >> <- -> == = <= >= < > <> <=> contains contained_by in includes is like and or xor}
  Assoc_op_alias   = {"&&" => "and", "||" => "or"}
  
  # patterns of association graph elements
  Literal_pattern = '-?\d+(?:\.\d+)?|\'[^\']*\'|NULL|TRUE|FALSE'
  Var_pattern     = '(\w+)?(:self|:([A-Z]\w*)+(::([A-Z]\w*))*)'           # entity_name:Model_name
  Polymorphic_pattern = '\*\w+'                                             # polymorphic name pattern.....added on 2008/10/02
  Attr_pattern    = '\.\w*'
  Op_pattern      = '\~?[\w,\=,\<,\>,\-]+\~?'
  Scan_pattern    = Literal_pattern + '|' + Var_pattern + '|' + Polymorphic_pattern + '|' + Attr_pattern + '|' + Op_pattern + '|' + '[\[,\],\(,\)]'
  Scan_rxp        = /#{Scan_pattern}/x
  Literal_rxp     = /\A(#{Literal_pattern})\z/x
  Var_rxp         = /\A(#{Var_pattern})\z/x
  Polymorphic_rxp = /\A(#{Polymorphic_pattern})\z/x
  Attr_rxp        = /\A(#{Attr_pattern})\z/x

  Elem       = Struct.new :elem_type,     :name,       :model_name               # elem_type is :var, :literal, :op, :attr or :polymorphic; model_name is only for var
  Arrow      = Struct.new :pre_value_ref, :op,         :pos_value_ref,  :cond    # op is binary operator. :cond is for ON conditions for JOIN
  ValueRef   = Struct.new :entity,        :attr,       :sql,  :polymorphic       # when entity is proxied, polymorphic is given.
  
  ClusterTree = Struct.new :cluster,       :conditions, :parent, :children       # outer join tree of inner join cluster. See ReadMe for detail.attributes are sets except :parent
  JoinEntity  = Struct.new :entity,        :cluster_tree
  
  class << self  # class methods

    # transform a_net to SQL join and conditions chains as find scope
    # the result is hash {:joins =>" AS self's alias name" + sql join chain, :conditions => conditions}
    def a_net_to_scope(a_net)
      return unless a_net
      arrows = a_net_to_arrows(a_net)
      arrows_to_cluster_hedge_to_sql(arrows)
    end
    
    # transform a_net to set of arrows
    def a_net_to_arrows(a_net)
      a_net.blank? and return
      if a_net.is_a? Array 
        a_net.inject([]) do |sum, g| 
          element = a_net_to_arrows(g)
          element and sum += element
          sum
        end.uniq 
      else
        a_net.is_a?(String) or fail "'#{a_net}' should be String"
        parse_elem_list_to_arrows(parse_a_net_to_elem_list(a_net).first)
      end
    end
    
    # transform arrows to cluster hedge(set of cluster trees) to SQL joins and conditions
    def arrows_to_cluster_hedge_to_sql(arrows)
      self_arrow = arrows.detect{|arw| arw.pre_value_ref.entity.model_name == self.name || arw.pos_value_ref.entity.model_name == self.name}
      fail "#{arrows.inspect} does not have base model."  unless self_arrow
      
      # self as base for cluster_hedge
      base = self_arrow.pre_value_ref.entity.model_name == self.name ? self_arrow.pre_value_ref.entity : self_arrow.pos_value_ref.entity   
      # fail "Since RAILS calculation misses aliasing in :from option, :self as base cannot have entity name (alias in SQL) different from the table name." unless base.name == self.table_name
      
      cluster_hedge = [].to_set << 
                      ClusterTree.new([].to_set << base, 
                                      [].to_set<< eigen_cond(base), 
                                      nil, 
                                      [].to_set)
      partial_arrows = [].to_set
      odd_arrows     = [].to_set
      global_cond    = [].to_set
      
      register_full_arrow(cluster_hedge, arrows.to_set, partial_arrows)
      assign_parent_to_cluster_tree(cluster_hedge, partial_arrows, odd_arrows) 
      merge_top_level_clusters(cluster_hedge)
      register_odd_arrow(cluster_hedge, global_cond, odd_arrows)
      
      cluster_hedge_to_sql(cluster_hedge, global_cond)
    end
    
    # STI type condition for STI model
    # if the entity model is base of STI , no conditions added, 
    #  that means the entity is constrained as an element of direct sum of all subcmodels of the base.
    # CAUTION: for the moment, accepts only one level hierarchy of STI.
    def sti_cond(entity)
      model_name = entity.model_name
      model = model_name.to_model
      if column?(model_name, inheritance_column) && model.base_class != model
        # STI model except base model
        "#{entity.name}.#{inheritance_column} = '#{model_name}'" 
      else
        "TRUE"
      end
    end
      
    # transform a_net expressed by string to array of elements
    def parse_a_net_to_elem_list(string)
      result, rest = [], string
      until rest.blank? do
        s = StringScanner.new(rest)
        s.scan_until(Scan_rxp)
        elem, rest = s.matched, s.rest
        case elem
          when "(", "[" then content, rest = parse_a_net_to_elem_list(rest) # start of route or set of routes
          when ")", "]" then break                                    # end of route or set of routes
          else          content = parse_elem(elem)                    # atomic element to be parsed
        end
        [result << content, rest]
      end
      [result, rest]
    end
    
    def register_full_arrow(cluster_hedge, arrow, partial_arrows)
#      return if arrow.blank?
      arrow.blank? and return
#      return arrow.each do |a| register_full_arrow(cluster_hedge, a, partial_arrows) end if arrow.is_a? Set
      arrow.is_a? Set and return arrow.each do |a| register_full_arrow(cluster_hedge, a, partial_arrows) end 
      
      if arrow.op.nil?  # arrow consists of only pre_value_ref.entity(isolated entity).
        detect_or_add_variable_to_cluster_hedge(arrow.pre_value_ref.entity, cluster_hedge)
        return
      end 
      
      op, pre_value_ref, pos_value_ref, cond =
        arrow.op.name, arrow.pre_value_ref, arrow.pos_value_ref, arrow.cond

      # exclude partial arrow
      if /\~/ =~ op  # partial join (outer join)
        partial_arrows << arrow
        return
      end
      
      is_literal?(pre_value_ref) && is_literal?(pos_value_ref) and fail "one of associated entities should be a variable in A_Net."
      is_literal?(pre_value_ref) and (pre_value_ref,  pos_value_ref = pos_value_ref, pre_value_ref)
      
      pre_join, pos_join = 
        detect_or_add_variable_to_cluster_hedge([pre_value_ref.entity, pos_value_ref.entity], cluster_hedge)  
      
#      merge_clusters(pre_join.cluster_tree, pos_join.cluster_tree, cluster_hedge)  if pos_join
      pos_join and merge_clusters(pre_join.cluster_tree, pos_join.cluster_tree, cluster_hedge)
      pre_join.cluster_tree.conditions << cond
    end
    
    def is_literal?(value_ref)
      value_ref && value_ref.entity && value_ref.entity.elem_type == :literal
    end
    
    # assign parent to cluster_tree for partial arrow
    # if arrow shows different parent than cluster's registered one, the arrow is to odd_arrows.
    def assign_parent_to_cluster_tree(cluster_hedge, arrow, odd_arrows)
#      return if arrow.blank?
#      return arrow.each do |a| assign_parent_to_cluster_tree(cluster_hedge, a, odd_arrows) end if arrow.is_a? Set
      arrow.blank? and return
      arrow.is_a? Set and return arrow.each do |a| assign_parent_to_cluster_tree(cluster_hedge, a, odd_arrows) end
      
      op, pre_value_ref, pos_value_ref, cond = arrow.op.name, arrow.pre_value_ref, arrow.pos_value_ref, arrow.cond
      pre_value_ref, pos_value_ref = pos_value_ref, pre_value_ref if op.end_with?('~')
      
      pre_join, pos_join = 
        detect_or_add_variable_to_cluster_hedge([pre_value_ref.entity, pos_value_ref.entity], cluster_hedge)  
        
      fail "literal cannot be an entity for partial association" unless pre_join && pos_join
      
      if pos_join.cluster_tree.parent.nil?
        pos_join.cluster_tree.parent = pre_join.cluster_tree
        pre_join.cluster_tree.children << pos_join.cluster_tree
      end
      
      if pos_join.cluster_tree.parent == pre_join.cluster_tree
        pos_join.cluster_tree.conditions << cond    
      else
        odd_arrows << arrow 
      end
    end
    
    # merge all cluster_trees of top level in cluster_hedge
    def merge_top_level_clusters(cluster_hedge)      
      first = cluster_hedge.detect{|t| t.parent.nil?}
      cluster_hedge.delete(first)
      top_cluster = cluster_hedge.inject(first) do |sum, cluster_tree|
#        merge_clusters(sum, cluster_tree, cluster_hedge) if cluster_tree && cluster_tree.parent.nil?
        (cluster_tree && cluster_tree.parent.nil?) and merge_clusters(sum, cluster_tree, cluster_hedge)
        sum
      end
      cluster_hedge << top_cluster
    end
    
    def register_odd_arrow(cluster_hedge, global_cond, arrow)
#      return if arrow.blank?
#      return arrow.each do |a| register_odd_arrow(cluster_hedge, global_cond, a) end if arrow.is_a? Set
      arrow.blank? and return
      arrow.is_a?(Set) and return arrow.each do |a| register_odd_arrow(cluster_hedge, global_cond, a) end
      
      op, pre_value_ref, pos_value_ref, cond = arrow.op.name, arrow.pre_value_ref, arrow.pos_value_ref, arrow.cond
      pre_value_ref, pos_value_ref = pos_value_ref, pre_value_ref if op.end_with?('~')
      
      pre_join, pos_join = 
        detect_or_add_variable_to_cluster_hedge([pre_value_ref.entity, pos_value_ref.entity], cluster_hedge)  
      
      if pos_join.cluster_tree.parent == pre_join.cluster_tree # pre_join cluster may be top level
        pos_join.cluster_tree.conditions << cond
      else                                                     # more than two parents (outer clusters)
        copy = Elem.new(:var, pos_join.entity.name + "_x", pos_join.entity.model_name)
        copy_cond = replace_entity_in_cond(pos_join.entity, copy, cond)
        pre_join.cluster_tree.children << 
          ClusterTree.new([].to_set<< copy, [].to_set<<copy_cond, pre_join.cluster_tree, [].to_set)
        # condition of "copy = pos_join_entity"
        global_cond << "#{copy.name}:#{copy.model_name} .id = .id #{pos_join.entity.name}:#{pos_join.entity.model_name}"
      end
    end
    
    def cluster_hedge_to_sql(cluster_hedge, global_cond)
      top = cluster_hedge.detect{|t| t && t.parent.nil?} or fail( "no scope found in #{cluster_hedge.inspect}" )
      top_cluster  = top.cluster.to_a
      self_entity  = top_cluster.detect{|e| e.name == self.table_name}
      from_entity  = top_cluster.delete(self_entity) or fail ArgumentError, "cluster_hedge '#{cluster_hedge}' has no from entity."
      join_chain   = top_cluster.inject(""){|sum, e| sum += " JOIN " + variable_to_sql(e)}
      join_chain  += add_left_join(top.children.to_a)
      global_cond += top.conditions
      {:from => variable_to_sql(from_entity), :joins => join_chain, :conditions => global_cond.to_a.join(" AND ")}
    end
    
    def add_left_join(cluster_trees)
      cluster_trees.inject("") do |sum, tree| 
        sum += " LEFT JOIN ( " + tree.cluster.to_a.map{|e|variable_to_sql(e)}.join(", ") + 
                                 add_left_join(tree.children.to_a) +
                          ") ON (#{tree.conditions.to_a.join(' AND ')}) "
      end
    end
        
    def replace_entity_in_cond(entity1, entity2, cond)
      cond.gsub!(/#{entity1.name}:#{entity1.model_name}/, "#{entity2.name}:#{entity2.model_name}")
    end
    
    def detect_or_add_variable_to_cluster_hedge(entity, cluster_hedge)
#      return if entity.blank?
#      return entity.map{|e| detect_or_add_variable_to_cluster_hedge(e, cluster_hedge)} if entity.is_a?Array
      entity.blank? and return 
      entity.is_a?(Array) and return entity.map{|e| detect_or_add_variable_to_cluster_hedge(e, cluster_hedge)}
      
      joiner = nil
      
      # exclude literal
      entity.elem_type == :literal and return
      
      cluster_hedge.each do |cluster_tree|
        joiner = detect_entity_in_cluster_tree(entity, cluster_tree)
#        break if joiner
        joiner and break
      end
      unless joiner
        cluster_tree = ClusterTree.new( [].to_set<<entity, [].to_set<<"(#{eigen_cond(entity)})", nil, [].to_set)
        cluster_hedge << cluster_tree
        joiner = JoinEntity.new(entity, cluster_tree)
      end
      joiner
    end
    
    def detect_entity_in_cluster_tree(entity, cluster_tree)
      return unless cluster_tree && cluster_tree.cluster
      
      joiner = nil
      if cluster_tree.cluster.detect do |e| 
          if e.name == entity.name 
            entity.model_name ||= e.model_name   # compensate model name for omitted case.
            e.model_name == entity.model_name or fail "name of entity '#{entity.inspect}' is already used for different model in entity '#{e.inspect}''."
          end
        end
        return JoinEntity.new(entity, cluster_tree)
      else 
        cluster_tree.children.each do |tree|
          joiner = detect_entity_in_cluster_tree(entity, tree)
#          break if joiner
           joiner and break
        end
      end
      joiner
    end
    
    # merge pos_cluster_tree to pre_cluster_tree in cluster_hedge
    def merge_clusters(pre_cluster_tree, pos_cluster_tree, cluster_hedge)
#      return unless pre_cluster_tree && pos_cluster_tree
      !(pre_cluster_tree && pos_cluster_tree) and return
      cluster_hedge.subtract [pre_cluster_tree, pos_cluster_tree]
      pre_cluster_tree.cluster    += pos_cluster_tree.cluster
      pre_cluster_tree.conditions += pos_cluster_tree.conditions
      pos_cluster_tree.children.each{|tree| tree.parent = pre_cluster_tree}
      pre_cluster_tree.children   += pos_cluster_tree.children
      cluster_hedge << pre_cluster_tree
      true
    end

    def cond_to_sql(op, pre_value_ref, pos_value_ref)
      (pre_value_ref.entity && pos_value_ref.entity) or return   # no effect
      pos_sql = value_ref_to_sql(pos_value_ref)
      "#{value_ref_to_sql(pre_value_ref)} #{op.upcase} #{pos_sql}" 
    end
    
    def variable_to_sql(variable)
      fail "#{variable.inspect} should be variable." unless variable && variable.elem_type == :var
      table_sql  = get_table_name(variable.model_name)
      alias_name = variable.name
      table_sql + " AS " + alias_name 
    end

    def value_ref_to_sql(value_ref)
      #return value_ref.sql if value_ref.sql
      #   already set in "contains","contained_by", "in" and "includes" case
      value_ref.sql and return value_ref.sql 
      # literal case
      is_literal?(value_ref) and return value_ref.entity.name
      
      "#{value_ref.entity.name}.#{value_ref.attr}"
    end
    
    # segment out arrows from list of elements
    # return array of arrows and the rest of list to process
    def segment_arrows(list)
      first, *rest = list
      first.nil? and return []

      if is_entity?(first)
        pre_value_ref = ValueRef.new(first)
        rest.blank? and return [Arrow.new(pre_value_ref)], nil  # arrow consists of single entity
      elsif first.is_a?(Array)
        # right side branches (no connection to left hand side)
        second, *rest = *rest
        return routes_to_arrows(nil, first, second), second, *rest
      else
        fail "'#{first.inspect}' should be entity or left_end_branches."
      end

      second, third, *rest = *rest
      # second may be expected to be collection of routes; if so, transform them to arrows.
      second.is_a?(Array) and return routes_to_arrows(first, second, third), third, *rest  

      if is_elem_type?(second, :polymorphic)   
        # polymorphic given
        pre_value_ref.polymorphic = second.name
        second, third, *rest = third, *rest
      end
      
      unless is_elem_type?(second, :attr)   
        # compensate omitted attr
        third, *rest = second, third, *rest
        second = Elem.new(:attr) 
      end      
      pre_value_ref.attr = second.name
      
      op, fourth, *rest = third, *rest
      is_elem_type?(op, :op) or fail "#{list.inspect} is not a segment of an arrow in A_Net."

      fourth.is_a?(Elem) or fail "'#{pre_value_ref.inspect}' has no effective counterpart in #{list.inspect} as a segment of an arrow in A_Net."
      pos_value_ref = ValueRef.new

      unless is_elem_type?(fourth, :attr)
        # compensate default attr
        *rest = fourth, *rest
        fourth = Elem.new(:attr) 
      end
      pos_value_ref.attr = fourth.name

      fifth, *rest = *rest
      if is_elem_type?(fifth, :polymorphic)
        pos_value_ref.polymorphic = fifth.name
        fifth, *rest = *rest
        # in case that arrow is branch with right_end of polymorphic(no var entity assigned).
#        return [Arrow.new(*normalize_arrow(pre_value_ref, op, pos_value_ref))], nil if fifth.nil?
        fifth.nil? and return [Arrow.new(*normalize_arrow(pre_value_ref, op, pos_value_ref))], nil
      end

      if is_entity?(fifth) 
        pos_value_ref.entity = fifth
        return [Arrow.new(*normalize_arrow(pre_value_ref, op, pos_value_ref))] , fifth, *rest
      else
         fail "#{fifth.inspect} is not adequate as the last for arrow."
      end
    end
    
    # normalize arrow depending on op and set conditions associated with the arrow
    def normalize_arrow(pre_value_ref, op, pos_value_ref)
      case pure_op(op.name)
        when "=="  # injection
          pre_value_ref.attr ||= "id"
          pos_value_ref.attr ||= "id"

          cond = cond_to_sql("=", pre_value_ref, pos_value_ref)          
          if cond && (polymorphic = pos_value_ref.polymorphic)
            cond += " AND #{pre_value_ref.entity.name}.#{polymorphic}_type = '#{pos_value_ref.entity.model_name}'"
          end

        when ">>", "<<", "->", "<-"     # reference type op, roughly corrresponds to "belongs_to","has_many", "has_one".
          if /\</ =~ op.name
            # reverse the arrow to normalize
            op.name.gsub!(/\</, ">").reverse! 
            pre_value_ref, pos_value_ref = pos_value_ref, pre_value_ref
          end
          pre_value_ref.attr ||= default_foreign_key(pos_value_ref) 
          pos_value_ref.attr ||= Run_id

          cond = cond_to_sql("=", pre_value_ref, pos_value_ref)          
          if cond && (polymorphic = pos_value_ref.polymorphic)
            cond += " AND #{pre_value_ref.entity.name}.#{polymorphic}_type = '#{pos_value_ref.entity.model_name}'"
          end
          
        when "contained_by", "contains"
          if (m1 = pre_value_ref.entity.model_name) && (m2 = pos_value_ref.entity.model_name) 
               m1 == m2 or fail " entities for #{op.name} are variables then should share the same model"   
          end
          
          if /contains/ =~ op.name
            # reverse the arrow to normalize
            op.name.reverse!          #  only the position of "~" is significant for partial mapping
            pre_value_ref, pos_value_ref = pos_value_ref, pre_value_ref 
          end  
          
          is_literal?(pre_value_ref) and fail "pre_value_ref of 'contained_by' is expected as variable."
          pre_value_ref.attr ||= Fullseq    # convention -- name with all ancestors
          
          if is_literal?(pos_value_ref)
           pos_value_ref.sql = "CONCAT(#{pos_value_ref.entity.name}, '%')"
          else
            if pos_value_ref.attr.nil?
              if column? pos_value_ref.entity.model_name, Fullseq_sub
                pos_value_ref.attr = Fullseq_sub
              else
                pos_value_ref.sql = "CONCAT(#{pos_value_ref.entity.name}.#{Fullseq}, '%')"
              end
            end 
          end
          cond = cond_to_sql("LIKE", pre_value_ref, pos_value_ref)
          
        when "in", "includes"  # different from SQL operator "IN"
          if /in/ =~ op.name
            # reverse the arrow to normalize
            op.name.reverse!
            pre_value_ref, pos_value_ref = pos_value_ref, pre_value_ref 
          end
          pos_value_ref.sql = "CONCAT('%', #{pos_value_ref.entity.name}.#{pos_value_ref.attr}, '%')"
          cond = cond_to_sql("LIKE", pre_value_ref, pos_value_ref)
          
        else  # usual comparison operator
          cond = cond_to_sql(pure_op(op.name).upcase, pre_value_ref, pos_value_ref)
      end
      return pre_value_ref, op, pos_value_ref, cond
    end
    
    def routes_to_arrows(pre_entity, routes, pos_entity)
      arrows = 
      routes.inject([]) do |sum, route|
        if is_branch? "left", pre_entity, route
          # left hand side is terminal of branch connecting to pos_entity.
          sum + parse_elem_list_to_arrows(route + [pos_entity])
        elsif is_branch? "right", pos_entity, route
          # right hand side is terminal of branch connecting to pre_entity
          sum + parse_elem_list_to_arrows([pre_entity] + route)
        else
          # route associates pre_entity to pos_entity
          sum + parse_elem_list_to_arrows([pre_entity] + route + [pos_entity])
       end
      end    
      arrows.compact
    end
    
    def is_branch?(left_or_right, entity, route)
      route.is_a?(Array) or return false  # route may be single op.
      terminal = (left_or_right == "left" ? route.first : route.last)
      is_entity?(terminal) ||(is_elem_type?(terminal, :polymorphic) && entity.nil?)
    end
    
    def is_entity?(elem)
      elem.is_a?(Elem) && (elem.elem_type == :var || elem.elem_type == :literal)
    end
    
    def is_elem_type?(elem, elem_type)
      elem && elem.is_a?(Elem) && elem.elem_type == elem_type
    end
           
    # parse list of elements of graph to set of arrows. Association operators are supposed to be binary. ....2008/1/25
    def parse_elem_list_to_arrows(list)
      arrows, *list = segment_arrows(list)
      head, *rest = *list
      return arrows if head.blank? || rest.blank?  # end of branch
      arrows + parse_elem_list_to_arrows(list)
    end
    
    # parse element string
    def parse_elem(elem)
      parse_literal(elem) || parse_var(elem) || parse_polymorphic(elem) || parse_attr(elem) || parse_op(elem) || fail(ArgumentError, "'#{elem}' can not be an element of a_net.")
    end
    
    def parse_literal(elem)
      literal = *elem.strip.scan(Literal_rxp).flatten
      return unless literal
      Elem.new(:literal, literal)
    end
    
    def parse_var(elem)
      expr, name, model_name = *elem.strip.scan(Var_rxp).flatten 
      return unless expr
      if model_name
        model_name = model_name[1..-1]
#        model_name = self.name if model_name == "self"
        model_name == "self" and model_name = self.name
        table = get_table_name(model_name)  
        name ||= table
      end 
      Elem.new(:var, name, model_name)
    end
    
    def parse_polymorphic(elem)
      poly = *elem.strip.scan(Polymorphic_rxp).flatten
      return unless poly
      Elem.new(:polymorphic, poly[1..-1])
    end
    
    def parse_attr(elem)
      attr = *elem.strip.scan(Attr_rxp).flatten
      return unless attr
      Elem.new(:attr, attr[1..-1])
    end
  
    def parse_op(elem)
      pure = pure_op(elem.strip)
      pure = Assoc_op_alias[pure] || pure   #resolve aliased op
      return unless Association_ops.include? pure 
      Elem.new(:op, elem)
    end
    
    def pure_op(op)
      op.downcase.gsub("~", "")
    end

    def get_table_name(model_name)
      model_name.to_model.table_name
    end

    # get default foreign key from value_ref
    def default_foreign_key(ref)
      polymorphic_foreign_key(ref.polymorphic) ||
      run_foreign_key(ref.entity.model_name)
    end
    
    def run_foreign_key(model_name)
      "#{get_table_name(model_name).singularize}_run_id"
    end
    
    def polymorphic_foreign_key(polymorphic)
      return unless polymorphic
      "#{polymorphic}_run_id"
    end
   
    # check if model of value_ref.entity.model has value_ref.attr as column
    def column?(model_name, attr)
      model_name.to_model.column_names.include? attr
    end
    
    # eigen conditions for entity variable
    #   timing conditions
    #   STI conditions
    #   simulation conditions for simulation mode
    def eigen_cond(entity)
      merge_conditions exist_and_valid_cond(entity.name),
                       sti_cond(entity),
                       simulation_cond(entity)
    end
     
    #.............. timing conditions ......................................#
  
    # condition for entity to be existing and valid for show and assert time settings
    def exist_and_valid_cond(entity_name=self.table_name)  
      show_time_db   = time_to_db(get_show_time(entity_name))
      assert_time_db = time_to_db(get_assert_time(entity_name))
      cond = [exist_cond(show_time_db, entity_name), valid_cond(assert_time_db, entity_name)].compact
      cond.blank? and return 
      cond.join(" AND ")
    end
    
    def local_assert_time(entity_name = nil)
      entity_name.nil? and return 
      value = @@local_assert_time_setting[entity_name.to_sym] or return
      value == :show_time and value = @@show_time
      value
    end
    
    def local_show_time(entity_name = nil) 
      entity_name.nil? and return 
      @@local_show_time_setting[entity_name.to_s]
    end
    
    # valid time span condition of facts
    def valid_cond(sql_t, entity_name=self.table_name)
      timing_condition(sql_t, Since, Till, entity_name)
    end
    
    # record existence condition
    def exist_cond(sql_t, entity_name=self.table_name)
      timing_condition(sql_t, Created_at, Deleted_at, entity_name)
    end
    
    # sql fragment of timing conditions
    # "sql_t" is sql expression of time; 
    #    if :anytime, return nil (means "neglect this condition!")
    # if sql_t is a range, the condition is generous to include the records which have intersection with the range  
    def timing_condition(sql_t, from, to, entity_name = table_name)
      sql_t == :anytime and return 
      cols = column_names
      from_sql, to_sql = [from, to].map{|t| cols.include?(t) ? "#{entity_name}.#{t}" : nil }
      # if table does not have "from" column or "to" column, condition is omitted.
      if sql_t.is_a? Range
        (from_sql && to_sql)  and return "#{intersect_in_db_ranges?(sql_t, from_sql..to_sql)}"
        from_sql              and return "(#{sql_t.first} <= #{from_sql})"
        to_sql                and return "(#{to_sql} <= #{sql_t.last})"
      else
        (from_sql && to_sql)  and return "(#{sql_t} BETWEEN #{from_sql} AND #{to_sql})"
        from_sql              and return "(#{sql_t} >= #{from_sql})"
        to_sql                and return "(#{sql_t} <= #{to_sql})"
      end
    end  
    
    # intersection condition between range_a and range_b in DB
    def intersect_in_db_ranges?(range_a, range_b)
      "(   (#{range_a.first} BETWEEN #{range_b.first} AND #{range_b.last})" + 
      " OR (#{range_b.first} BETWEEN #{range_a.first} AND #{range_a.last}) )"
    end
    
    # sql fragment for time. "time" is either symbol(:anytime), string(ex."table.column") or literal(DateTime)
    def time_to_db(time)
      verify_time_type(time)
      time.is_a?(Range) and return time_to_db(time.first)..time_to_db(time.last)
      # time type casting
      case time
      when Symbol          then time
      when String          then time.scan(/\:/).blank?  ? time : "'#{time}'" 
      when Time, DateTime  then "'#{time.to_s(:db)}'"  # time literal
      when NilClass        then nil
      else fail ArgumentError, "#{time.class.name} is not an expected class for time"
      end
    end
  
    def verify_time_type(time)
      time.is_a?(Range) and return (verify_time_type(time.begin) && verify_time_type(time.end))
      (time.is_a?(Time) || time.is_a?(DateTime) || time.is_a?(String) || 
       time == :anytime || time == :show_time) or fail "'#{time} should be a time.'"
    end
    
    def value_ref_name(value_ref)
      value_ref.entity ? value_ref.entity.name : value_ref.polymorphic
    end

  end  # end of class << self
  
  # --- simulation conditions for simulation mode

  def self.simulation_cond(entity)
    entity_name = entity.name
    normal_cond = "#{entity_name}.simulation_mode IS NULL" 
    @@simulation_mode ? "#{normal_cond} OR #{entity_name}.simulation_mode" : normal_cond
  end
  
  # should be public not protected
  
  def attrs_list_at_action(time_span, *args)
    states_at_action(time_span, *args).map(&:attributes)
  end
  
  # find  all states with specified "time "(could be span) at the time of action with args restriction
  # if args.blank? set as [:first]
  def states_at_action(time = nil, *args)
    # save @@show_time and @@assert_time temporalily
    show_time, assert_time = @@show_time, @@assert_time
    @@show_time   = @@action_time
    @@assert_time = time || @@action_time
    
    options = Run.get_options_from_args!(args).to_h
    
    # without :scope option,
    options.update(:scope => :self) unless options[:scope]
    
    given_conditions = options.delete(:conditions)
    options.update(:conditions => Run.merge_conditions("#{self.class.table_name}.run_id = #{self.run_id}", *given_conditions))
    
    result = self.class.find(:all, *( args << options))
    # recover @@show_time, @@assert_time
    @@show_time, @@assert_time = show_time, assert_time
    result
  end
  
  def delete_all_descendant_runs!(span, time = @@action_time)
    self.class.children_runs(span, self.run_id).each do |child|
      child.delete_run!(span)
      child.delete_all_descendant_runs!(span, time)
    end
  end

  # "method" is attribute name
  def existing_values_of_attribute(attr_name)
    self.class.find(:all, :scope => :self, :distinct => attr_name.to_s).map do |e| e.send(attr_name) end 
  end
  
  def self.admin_only
    @@current_account && @@current_account.role == "admin"
  end

  #---

 protected
 
  # if states have been changed while viewing, then fail
  def optimistic_lock!(view_time_states_in_string)
    new_record? || view_time_states_in_string.blank? and return # do nothing
    # states at rendering view page
    view_time_states = view_time_states_in_string.split(States_Separator).map(&:to_i).sort
    # lock all current states while comparing with view_time_states.
    current_states   = history(:assert_time => :anytime).map(&:lock!).map(&:id).sort
    if current_states != view_time_states 
      errors.add_to_base "閲覧中に他者によって削除ないし更新されています．そのため楽観的ロックによりこの実行を無効にします．"
      fail ActiveRecord::RecordInvalid.new(self)
    end
  end
  
  # validate uniqueness of attr as run current state
  # to be applied as after_save_validation to avoid racing between saving and this validation
  def validate_uniqueness_as_run(attr,  msg = "すでに使用されていますので，使えません．")
    !attribute_present?(:run_id) || attribute_present?(:deleted_by) and return self

    other = self.class.find :first, :scope => :self, 
               :conditions => Run.merge_conditions("run_id <> #{self.run_id}", ["#{attr} = :#{attr}", {attr.to_sym => self.send(attr)}])

    unless other.blank?
      errors.add attr, msg
      fail ActiveRecord::RecordInvalid.new(self)
    end
    return self
  end

  #..... validation.........,#
  
  # validate valid term and exist term parameters
  def valid_and_exist_terms_for_state?
    unless (since = self.send(Since).to_s(:db)) <= (till = self.send(Till).to_s(:db)) && (cr = self.send(Created_at).to_s(:db)) <= (del = self.send(Deleted_at).to_s(:db)) 
      errors.add_to_base("状態期間ないし記録期間が不適切です．since = #{since}; till = #{till}; created_at = #{cr}; deleted_at = #{del}")
    end
  end
  
  #........... Operations on Records.......................#
  
  # for args of creating and updating run
  # args are (time, hash) or (hash)
  # return time span and attr with valid time period given by time(if time is not given, default value is set).
  def self.get_attr_with_time_from_args(*args)
    span_option = args.first
    span = 
      case span_option
       when nil, Hash      then Past..Future  # span omitted
       when Date, DateTime then span_option..Future          # span.begin only given as time
       when Range          then span_option   # span range given
       else fail "'#{args.inspect}' is not adequate as arguments for creating or updating run."
     end
    (span.begin.is_a?(Date) ||span.begin.is_a?(DateTime)) && (span.end.is_a?(Date) ||span.end.is_a?(DateTime)) or
       fail "time must be given as either Date or DateTime."
    
    args.last ||= {}
    args.last.update(Since => span.begin.to_s(:db), 
                     Till  => span.end.to_s(:db))
  end
  

 
  #................Alter records operation ..............................#
  
  def admin_only
    self.class.admin_only
  end
  
  def update_run(update_span, updating_content)
    updating_content ||= {}
    
    if @@simulation_mode && self.send(Simulation_Mode).nil?
      errors.add_to_base "通常モードで作成された記録をシミュレーションモードで変更することは出来ません．"
      fail ActiveRecord::RecordInvalid.new(self)
    end
    
    # if "deleted_by" attribute is set to be current_user.run_id, then self is regarded to be destroyed.
    # if so, mark deleted true.
    updating_content[Deleted_by] && updating_content[Deleted_by].to_i == @@current_user.run_id and deleted = true
    # delete states involved between update_span, and record ids of those states
    delete_related_state_ids = delete_run!( update_span )
    
    unless deleted #  not Delete, so, add new state
      updating_content[Since], updating_content[Till] = update_span.begin, update_span.end
      updating_content[Created_at], updating_content[Deleted_at] = nil, nil
      # update original attributes with updating_content
      new_content = with_default_state_attrs self.attributes.merge(updating_content)
      result = add_state!(new_content)
      # mark id on "updated_to" columns of delete related states
      delete_related_state_ids.blank? or 
        self.class.update(delete_related_state_ids, [{Updated_to => result.id}] * delete_related_state_ids.size)
    else # Delete 
      # when deleted, result is the last of delete_related_states to show deleted run info.
      #  for instance, deleted(terminated) time is its till.
      #  delete_related_state_ids.blank? then return with error to show that the part is already deleted.
      if delete_related_state_ids.blank?
        errors.add_to_base "すでに削除されています．"
        fail ActiveRecord::RecordInvalid.new(self)
      end
      result = self.class.find(delete_related_state_ids.last)
    end
    result
  end
  
  # sort and check valid terms in attr_list as effective term sequence
  def self.verify_and_sort_attr_list(*attr_list)
     attr_list.sort{|a,b| a[Since] <=> b[Since]}
     overlapped?(*attr_list) and fail ArgumentError, "state attribute list overlapped."     
  end
  
  # check if valid terms overlapped in attr_list
  def self.overlapped?(*attr_list)
    !attr_list.inject(Past_db) do |pre_till, attr|
     (attr[Since] > attr[Till] || pre_till >= attr[Since]) ? break : attr[Till]
    end
  end

  # QTIME sec ago in db format of time
  def self.pred_time_db(time_db)
    time_db.to_datetime.ago(QTIME).to_s(:db)
  end
  
  # QTIME sec later in db format of time
  def self.succ_time_db(time_db)
    time_db.to_datetime.in(QTIME).to_s(:db)
  end
 
  # intersect two lists of attributes with time span(since..till)
  #  given block does something for each attrs in intersected time span
  #  returned result is  the array of intersected terms processed by the block.
  #  list should be ordered, not overlapped in it, gaps allowed 
  #  time of since and till should be in db format.use "time_to_db_format" method
  def self.intersect_terms(a_list, b_list, result, &block)
    a, b = a_list.shift, b_list.shift
    a and a_interval = (a[Since]..a[Till])
    
    case
    when a.nil?
#      return if b.nil?
      b.nil? and return result
      result += yield(nil, b, b[Since]..b[Till])
      intersect_terms([], b_list, result, &block)
    when b.nil?
#      return if a.nil?
      a.nil? and return result
      result += yield(a, nil, a[Since]..a[Till])
      intersect_terms(a_list, [], result, &block)
    when b[Since] < a[Since]
      case
      when b[Till] < a[Since]
        result += yield(nil, b, b[Since]..b[Till])
        intersect_terms(a_list.unshift(a), b_list, result, &block)
      when a_interval.include?(b[Till])
        result += yield(nil, b, b[Since]..pred_time_db(a[Since]))
        result += yield(a, b, a[Since]..b[Till])
        intersect_terms(a_list, b_list, result, &block)
      when b[Till] > a[Till]
        result += yield(a, b, a[Since]..a[Till])
        a[Till] == Future_db and return result
        intersect_terms(a_list, b.list.unshift(b.update(Since => succ_time_db(a[Till]))), result, &block)
      end
    when a_interval.include?(b[Since])
      case
      when a_interval.include?( b[Till] )
        result += yield(a, nil, a[Since]..pred_time_db(b[Since]))
        result += yield(a, b, b[Since]..b[Till])
        b[Till] == Future_db and return result
        intersect_terms(a_list.unshift(a.update(Since => succ_time_db(b[Till]))), b_list, result, &block)
      when b[Till] > a[Till]
        result += yield(a, nil, a[Since]..pred_time_db(b[Since]))
        result += yield(a, b, b[Since]..a[Till]) 
        a[Till] == Future_db and return result
        intersect_terms(a_list, b_list.unshift(b.update(Since => succ_time_db(a[Till]))), result, &block)
      end
    when b[Since] > a[Till]
      intersect_terms(a_list, b_list.unshift(b), result, &block)
    else
      fail "illegal case to intersect terms with #{a_list.inspect} and #{b_list.inspect}"
    end
  end   
  
  # build state attr list between target run and relative nearest run
  # option is in [:pred, :succ, :child]
  def self.state_attr_list_relative_to(option, target, state_attr_list)
    state_attr_list_in_db = time_to_db_format(state_attr_list)
    span = (state_attr_list_in_db.first[Since]..state_attr_list_in_db.last[Till])
    target_attr_list = target ? target.attrs_list_at_action(span, :all) : []
    target_attr_list_in_db = time_to_db_format(target_attr_list)
    new_attr_list = intersect_terms(target_attr_list_in_db, state_attr_list_in_db, [])  do |t, s, spn|
      attr_with_nearest_state(option, t, s, spn)
    end
    new_attr_list.compact
  end
  
  def self.time_to_db_format(state_attr_list)
    state_attr_list.dup.each do |attr|
      attr[Since] = attr[Since] ? attr[Since].to_s(:db) : Past_db
      attr[Till]  = attr[Till]  ? attr[Till].to_s(:db)  : Future_db
    end
  end
  
  # making self_attr have the position between target attr and nearest state attr in time span
  def self.attr_with_nearest_state(option, target_attr, self_attr, span)
    self_attr.nil? and return []

    target_parent_run_id = target_attr[Parent_run_id].blank? ? "NULL" : target_attr[Parent_run_id]
    # neighbor states in span
    neighbor_states_list =
      case option
      when :pred
        all_run_states_at_action span, :all, :conditions => "#{Parent_run_id} = #{target_parent_run_id} AND #{Seq} < '#{target_attr[Seq]}'",
        :order => Seq + " DESC"
      when :succ
        all_run_states_at_action span, :all, :conditions => "#{Parent_run_id} = #{target_parent_run_id} AND #{Seq} > '#{target_attr[Seq]}'",
        :order => Seq
      when :child
        all_run_states_at_action span, :all, :conditions => "#{Parent_run_id} = #{target_attr[Run_id]}",
        :order => Seq + " DESC"
      end
   
    # build layers of neighbor states attr with seq order within span
    neighbor_layers = neighbor_states_list.inject([]) do |sum, state|
      sum << state.attributes.update(Since => [span.begin, state.send(Since).to_s(:db)].max,
                                     Till  => [span.end, state.send(Till).to_s(:db)].min)
    end
 
    # build attr list of neighbors by intersect overwriting
    neighbor_attr_list = neighbor_layers.inject([]) do |base, layer|
      sum = base
      base = intersect_terms(base, [layer], sum) do |bp, lay, spn|
        if bp.nil?  # this part of base is still blank
          [lay.update(Since => spn.begin, Till => spn.end)]
        else
          []
        end
      end
      base.sort!{|a, b| a[Since] <=> b[Since]}
    end

    # summing up attrs between target and neighbor 
    neighbor_attr_list.blank? and neighbor_attr_list = [{Since => span.begin, Till => span.end, Parent_run_id => target_attr[Parent_run_id]}]
    result = neighbor_attr_list.inject([]) do |sum, neighbor_attr|
      sum << attr_between(option, target_attr, neighbor_attr, self_attr)
    end
    result.compact
  end
  
  # attr positioned between target_attr and neighbor_attr
  #  with original attr(state attr) affected by neighbor_attr's since and till
  def self.attr_between(option, target_attr, neighbor_attr, attr)
    new_seq = 
      case option
      when :pred
        seq_between(neighbor_attr, target_attr)
      when :succ
        seq_between(target_attr, neighbor_attr)
      end
    parent_run_id =
      target_attr.nil? ? "NULL" : target_attr[Parent_run_id]
    parent_fullseq =
      parent_run_id.nil? || parent_run_id == 0 ? "" : target_attr[Fullseq].split(Level_Separator)[0..-2].join(Level_Separator) + Level_Separator
    parent_fullname =
      parent_run_id.nil? || parent_run_id == 0 ? "" : target_attr[Fullname].split(Level_Separator)[0..-2].join(Level_Separator) + Level_Separator
    new_attr = attr.merge( Since => neighbor_attr[Since],
                           Till  => neighbor_attr[Till],
                           Seq => new_seq,
                           Parent_run_id => parent_run_id,
                           Fullseq  => make_fullseq(new_seq, parent_fullseq),
                           Fullname => make_fullname(attr[Name], parent_fullname)
    )
   return new_attr
  end
 
  def self.children_runs(span, parent_run_id)
    all_run_states_at_action span,
        :all, 
        :conditions => " #{Parent_run_id} = #{parent_run_id}",
        :group => Id
  end
  
  # update all children's states
  #  caused by change of parent_attr's position  
  def self.update_children_fullseq_fullname(parent_attr)
    return unless parent_attr[Run_id]
    span = (parent_attr[Since].to_s(:db)..parent_attr[Till].to_s(:db))
    children_runs(span, parent_attr[Run_id]).each do |child|
      c_attr_list = child.states_at_action(span.begin.to_datetime..span.end.to_datetime, :all).map(&:attributes)
      intersect_terms(time_to_db_format(c_attr_list), time_to_db_format([parent_attr]), []) do |c, p, spn|
        if p
          new_c = c.merge(Since => spn.begin, Till => spn.end,
                          Fullseq  => make_fullseq(c[Seq], p[Fullseq]),
                          Fullname => make_fullname(c[Name], p[Fullname]))
          child.update_run!(spn.begin.to_datetime, new_c)
          # do child's children recursively.
          update_children_fullseq_fullname(new_c) 
        end
        [] # dummy value adding to result of intersect_terms
      end  
    end
  end
  
  # all run's valid states in assert_time existing at @@action_time
  def self.all_run_states_at_action(assert_time, *args)
    options = get_options_from_args!(args).to_h
    options.merge! :scope => :self, :show_time => @@action_time, :assert_time => assert_time
    find *(args << options)
  end
  
  def self.make_fullseq(seq, parent_fullseq = nil)
#    return seq if parent_fullseq == nil
    parent_fullseq == nil and return seq 
    parent_fullseq + seq + Level_Separator
  end
  
  def set_fullseq()
    self.fullseq = self.class.make_fullseq(self.seq, self.parent.fullseq)
  end
  
  def self.make_fullname(name, parent_fullname = nil)
#    return name if parent_fullname == name
    parent_fullname == name and return name
    parent_fullname + name + Level_Separator
  end
  
  def set_fullname()
    self.fullname = self.class.make_fullname(self.name, self.parent.fullname)
  end
  
  #---
  #..........    seq coding  ..............................#
  #  seq code is a sequencial code for lists
  #  item insertion can be done with no changes of other items' seq codes.
   
  # seq between lower level attr and upper level attr
  # use this when inserting item between lower and upper
  def self.seq_between(lower, upper)
    lower_seq = lower ? lower[Seq] : nil
    upper_seq = upper ? upper[Seq] : nil
    middle_seq(lower_seq, upper_seq)
  end
 
  # get middle of lower and upper seq code
  # if lower is nil, set Zero(lower limit of seq); if upper is nil, return succ of lower
  # the last Zero is regarded as zero length string, so that "a" == "a0000" for example.
  def self.middle_seq(lower, upper)
    lower ||= Zero
#    return succ_seq(lower) if upper.nil?
    upper.nil? and return succ_seq(lower)
    lower, upper = [lower, upper].map &:to_s
#    fail "lower should be less than upper"  unless lower < upper
    !(lower < upper) and fail "lower should be less than upper"    
    middle = succ_seq(lower)
    until middle < upper do middle = middle_seq(lower + Zero, upper) end
    middle
  end
  
  # get successor of seq code
  def self.succ_seq(seq)
#    return seq + One if seq.squeeze(Omega) == Omega
    seq.squeeze(Omega) == Omega and return seq + One
    # pop seq
    last = seq.last; seq_body = seq.chop
    last == Omega ? succ_seq(seq_body) : seq_body + Chars[Chars.index(last) + 1]
  end
  
  # --
  
  # A_NET scope for association
  # ":self" in assoc_net is regarded to be model which is associated with
  # Self_Entity is reserved name attached to entity for ":self" above; so don't use this name in assoc_net
  #   this is necessary for the case of association to the same model as target.
  Self_Entity = "__self__"
  
  # useful for setting assert_time
  Self_Created_Time = "#{Self_Entity}.created_at"
  
  def assoc_scope(assoc_net)
    ":self" +  assoc_net.gsub( /\:self/, "#{Self_Entity}:#{self.class.name}" )
  end

end

  


