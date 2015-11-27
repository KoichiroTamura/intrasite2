=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# session resource handler

class SessionsController < RunsController
  
  skip_before_filter :login_required, :registered_only, :find_entity, :owner_only
  
  skip_before_filter :set_system_situation, :only => :new
  
  # present login format
  def new
    attrs = params[:account] || {}
    @logged_in = session[:account]
    @logged_in or set_system_situation
    @login = Account.new attrs
    if request.xhr?
      render :update do |page|
        page[:head_banner_login].replace_html "ログイン"
        page[:login_part].replace_html :partial => "new"
        page[:login_part].show.visual_effect('move', :x => 0, :y => 300)
      end
    else
      render :partial => "new", :layout => "application"
    end
  end

  # logging in with account_name and password and starting session if authenticated
  def create
    if @logged_in = session[:account]  # alreacy logged in by other page.
      render :partial => "new", :layout => "application"
      return false
    end
    @login = Account.new(params[:account])
    account = @login.authenticate   
    session[:account] = account.id
    # restore the last login-required request: if no last request, redirect to article_threads
    last_request, session[:last_request] = session[:last_request], nil
    last_request ? redirect_to(last_request) : redirect_to(:controller => "/article_threads")    
 	rescue => e      # not authenticated
    session[:account] = nil
    flash[:error] = "ログインに失敗しました．"  + e
    redirect_to( new_session_url( params.merge(:action => :new) ))
  end

  # logging out. :method => "delete"
  def destroy
    session[:account] = session[:last_request] = nil
    redirect_to :controller => "/home"
  end

end
