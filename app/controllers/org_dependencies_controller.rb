=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

#=機能
# 与えられたPosition(Affiliation or Status)のfullnameから
# 対になるPosition(Status or Affiliation)を検索する
# 
# 結果した結果はjsonで返却する
# 
#=Author
# Toshy Namimatsu (toshy@minfo-rela.net)
#
#=Copyright
# Web comm, Schoool of Information Sceience and Technology, Chukyo University, 2010
#
#=依存関係
#
# DB: org_dependencies
#
# Model: OrgDependency

#
class OrgDependenciesController < RunsController
  
  skip_before_filter :login_required
  skip_before_filter :find_entity

  def search_json
    res = inside_search

    result = Hash.new
#    if res 
#      res.each {|i|
#       result[i.fullname.tr("|","")]=i.run_id
#     }
#    end

    res = res.each {|i| result[i.fullname.tr("|","")]=i.run_id }
    
    render :json=>{:simple=>result.keys,:hash=>result}
  end

private
  # その範囲のみに絞った検索をする場合、値に罫線が紛れ込む為、それを削除する
  # 
  # 戻り値 (Array) [修正済みfullname, children_follow
  def fullname_fix(val)
   fullname = val.clone
   children_follow = true
   result = fullname.split(//)
   while result.pop.to_s != "|"
     children_follow = false
   end
   fullname = result.join("").to_s + "|"
   return [fullname,children_follow]
  end
 


  # 検索する本体
  # 
  # 検索に失敗すると、falseを返却する。
  # 
  # 成功すると、対象になるPositionを返してくれる。
  def inside_search
#   return false if params[:fullname].blank? && params[:id].blank?
    (params[:fullname].blank? && params[:id].blank?) and return false
    
    if params[:fullname].blank? && !params[:id].blank?
      (id,model) = params[:id].to_id_and_model_name
      val = eval "#{model}.find(:first,:scope=>\":self\",:conditions=>\"run_id=#{id}\")"
      logger.debug val.fullname
      params[:fullname]=val.fullname
    end

   (fullname,children_follow) = fullname_fix(params[:fullname])

   query = String.new()
   output_model = String.new()
   (query,output_model) = OrgDependency.set_query_and_output_model(fullname,children_follow)

   query += " and ( #{OrgDependency.children_flow_control(output_model)} )"

   result_tmp = OrgDependency.find :all,
           :distinct   => "#{output_model}.*",
           :scope      => ":self [(.affiliation_run_id >> aff:Affiliation contains affiliation:Affiliation) (.status_run_id>> sta:Status contains status:Status)]" ,
           :order      => "#{output_model}.fullseq",
           :conditions => query

   query=Array.new();
   result_tmp.uniq.each { |r|
     query.push "'#{r.fullseq}' like fullseq_sub"
   }

#  return false if query.length == 0
  (query.length == 0) and return false

   case output_model
     when "affiliation"
      return Affiliation.find(:all,:group=>"fullseq,run_id",:scope=>":self",:conditions=>query.join(" or "))
     when "status"
      return Status.find(:all,:group=>"fullseq,run_id",:scope=>":self",:conditions=>query.join(" or "))
     else
   end
 end

end

