=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module ArticlesHelper
  # helpers for rendering article view
  
  # render article's destinations
  def render_destinations(destinations)
    render :partial => "articles/destinations", :locals =>{:destinations => destinations}
  end
  
  def render_time_place_settings(time_place_settings)
    time_place_settings.start_date or return # no time_place_settings given
    render :partial => "articles/time_place_settings", :locals =>{:time_place_settings => time_place_settings}
  end
  
  def render_shared_place(shared_place)
    shared_place.blank? and return ""
    (shared_place.fullname.split('|') - ["スペース"]).join('　')
  end
  
  def render_input_article(article_assocs)
    @article = article_assocs.first
    render :partial => "articles/new", :locals => {:def_form_items => @def_article_form_items, :form_items => @article_form_items}
  end
  
  def render_input_destinations(form, method = nil, options = {})
    render :partial => "articles/input/destinations", :locals => {:form => form, :options => options}
  end
  
  def render_input_time_place_settings(form, method = nil, options = {})
    render :partial => "articles/input/time_place_settings", :locals => {:form => form, :options => options}
  end
  
  def render_select_shared_place(form, method = "place_run_id", options = {})
    place_run_id = form.object.place_run_id
    shared_place = Space.find :first, :scope => :self, :conditions => {:run_id => place_run_id}
    render_tree_select_cluster(Space.tree_root, shared_place, :form => form, :method => "place_run_id")
  end
  
    
  # remote link to responding to entity(article)
  # entity is original article
  # options[:responding_to] => "ALL"(original receiver + sender) or nil(only to sender)
  def link_to_responding(entity, div_id, options = {})
    link_to_remote_with_params( (options[:responding_to] == "ALL" ? "全員に" : "") + "返信", 
                    :url => {:controller => "/article_threads", :action => :adding_responder}, 
                    :params => {:background_params => @background_params,
                                :display_mode      => @display_mode,
                                :id => entity.to_param,
                                :base_div_id => div_id,
                                :responding_to => options[:responding_to]} ) 
  end

end