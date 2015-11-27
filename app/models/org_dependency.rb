=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

#  create_table "org_dependencies", :force => true do |t|
#    t.integer  "affiliation_run_id",                                :default => 0,                     :null => false
#    t.integer  "status_run_id",                                     :default => 0,                     :null => false
#    t.boolean  "affiliation_children_follow",                       :default => true,                  :null => false
#    t.boolean  "status_children_follow",                            :default => true,                  :null => false
#    t.integer  "run_id",                                            :default => 0,                     :null => false
#    t.integer  "created_by"
#    t.integer  "deleted_by"
#    t.datetime "created_at",                                        :default => '2001-04-01 00:00:00', :null => false
#    t.datetime "deleted_at",                                        :default => '9999-12-31 23:59:59', :null => false
#    t.datetime "since",                                             :default => '2001-04-01 00:00:00', :null => false
#    t.datetime "till",                                              :default => '9999-12-31 23:59:59', :null => false
#    t.string   "seq"
#    t.text     "fullseq",                     :limit => 2147483647
#    t.text     "fullseq_sub",                 :limit => 2147483647
#    t.string   "name"
#    t.string   "fullname"
#    t.integer  "merged_to"
#    t.integer  "split_from"
#  end
#
#  add_index "org_dependencies", ["affiliation_children_follow"], :name => "index_org_dependencies_on_affiliation_children_follow"
#  add_index "org_dependencies", ["affiliation_run_id", "status_run_id"], :name => "index_org_dependencies_on_affiliation_run_id_and_status_run_id"
#  add_index "org_dependencies", ["affiliation_run_id"], :name => "index_org_dependencies_on_affiliation_run_id"
#  add_index "org_dependencies", ["created_by"], :name => "index_org_dependencies_on_created_by"
#  add_index "org_dependencies", ["deleted_by"], :name => "index_org_dependencies_on_deleted_by"
#  add_index "org_dependencies", ["run_id"], :name => "index_org_dependencies_on_run_id"
#  add_index "org_dependencies", ["status_children_follow"], :name => "index_org_dependencies_on_status_children_follow"
#  add_index "org_dependencies", ["status_run_id"], :name => "index_org_dependencies_on_status_run_id"
#
#=解説
# affiliation_run_id        Affiliationのrun_id
# status_run_id           Statusのrun_id
# affiliation_children_follow   指定したAffiliationのrun_idに子要素がある場合、それも含めるか。
#                 falseにすれば、指定したrun_idのみとして扱う
# status_children_follow      指定したStatusのrun_idに子要素がある場合、それも含めるか。
#                 falseにすれば、指定したrun_idのみとして扱う
# 
class OrgDependency < Run
  set_table_name "org_dependencies"


  # クエリーやモデルなどを設定する。
  # 
  # fullname_fixの戻り値をそのまま使用する
  # 
  # children_follow … 子要素も含めるか。指定した組織に限定する場合は、children_followはfalse
  def self.set_query_and_output_model(fullname,children_follow)
   af = Affiliation.find(:first,:conditions=>["fullname=?",fullname],:scope=>":self")
   st = Status.find(:first,:conditions=>["fullname=?",fullname],:scope=>":self")

   query = String.new()
   output_model = String.new()

#   return false if st.blank? && af.blank?
    (st.blank? && af.blank?) and return false

   unless st.blank?
    if children_follow
      query = "status.fullseq like '#{st.fullseq_sub}' and (#{self.children_flow_control('status')})"
    else
      query = "status.fullseq='#{st.fullseq}' and status_children_follow=0"
    end
    output_model = "affiliation"
   end

   unless af.blank?
    if children_follow
     query = "affiliation.fullseq like '#{af.fullseq_sub}' and (#{self.children_flow_control('affiliation')})"
    else
     query = "affiliation.fullseq='#{af.fullseq}' and affiliation_children_follow=0"
    end
     output_model = "status"
   end
   return [query,output_model]
  end 

  # 子要素の検索。これをしないと、子要素はフォローしなくてもよいところで、フォローされて
  # 対応付けがぐちゃぐちゃになってしまう。
  def self.children_flow_control(model_name)
  "#{model_name}_children_follow=1 or (#{model_name}_children_follow=0 and #{model_name[0..2]}.run_id=#{model_name}.run_id)"
  end

end