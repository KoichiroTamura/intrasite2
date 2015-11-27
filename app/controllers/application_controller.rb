=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.


class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  # session :session_key => 'intrasite2_SIST_Chukyo_U'  ; this setting depricated already since session is lazily loaded(comment by Tamura).
  
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'e94acf78d9ac95a6ff46bac63384f3e2'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  # mask password in log only for production mode 
  filter_parameter_logging /password/i if RAILS_ENV == "production"

end
