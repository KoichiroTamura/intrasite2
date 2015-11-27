ActionController::Routing::Routes.draw do |map|
  # On moving to rails 2  2008/06/19 Koichiro

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  map.root      :controller => "home"    # "home" is the home page not resources

  map.connect   "/k", :action=>"index", :controller=>"mobiles"
  map.connect   "/k/schedule", :action=>"schedule_index", :controller=>"mobiles"
  map.connect   "/k/bus", :action=>"bus_index", :controller=>"mobiles"
  map.connect   "/k/course", :action=>"course_index", :controller=>"mobiles"
  
  map.connect   "/seminar_introduction/:id.swf", :action=>"swf_download", :controller=>"seminar_introductions"
  map.connect   "/seminar_introduction/:id.html", :action=>"html_download", :controller=>"seminar_introductions"
  map.connect   "/seminar_introduction/pdf/:id.pdf", :action=>"pdf_download", :controller=>"seminar_introductions"
  map.connect   "/seminar_introduction/header/:id.jpg", :action=>"header_download", :controller=>"seminar_introductions"
  map.connect   "/seminar_introduction/pics/:id.jpg", :action=>"pics_download", :controller=>"seminar_introductions"

  
  map.resource  :session
  map.resources :accounts, 
                :collection => {:search  => :get},
                :member     => {:changing_password => :get, :change_password => :put}
  map.resources :articles
  map.resources :article_threads
  map.resources :questionnaires
  map.resources :answers
  map.resources :schedules
  map.resources :shared_space_schedules
  map.resources :courses
  map.resources :course_classes
  map.resources :syllabuses
  map.resources :syllabus_books
  map.resources :lectures
  map.resources :exercises
  map.resources :reports
  map.resources :bus_diagrams
  map.resources :bus_schedules
  map.resources :theses
  map.resources :thesis_introductions
  map.resources :bachelor_theses
  map.resources :master_theses
  map.resources :doctor_theses
  map.resources :thesis_presentation_schedules
  map.resources :bachelor_thesis_schedules
  map.resources :master_thesis_schedules
  map.resources :doctor_thesis_schedules
  map.resources :seminars,
                :collection => {:search => :get, :summing_up => :get}
  map.resources :seminar_member_students
  map.resources :seminar_enrollment_schedules
  map.resources :user_infos,
                :collection => {:search  => :get},
                :member     => {:correcting => :get, :correct => :put}
  map.resources :groups
  map.resources :group_members
  map.resources :help_infos
  map.resource  :seminar_introduction,
                :collection => {:swf_download => :get, :html_download=>:get, :pdf_download=>:get, :pics_download=>:get, :header_download=>:get, :show=>:get}
  map.resources :seminar_introductions
  map.resources :seminar_regist_introductions
  map.resources :lecture_time_to_real_times
  map.resources :maintenance_infos,
                :collection => {:search => :get}
  map.resources :corners,
                :collection => {:search => :get}
  map.resources :menus
  map.resources :exercises,
                :collection => {:search => :get}
  map.resources :positions
  map.resources :affiliation
  map.resources :seminar_reigst_introdutcions
  map.resources :thesis_introducitons
  map.resources :unions,
                :member => {:action => :get}              
  map.resource  :reminder,
                :member => {:create => :post, :update=> :post}
  map.resource  :user_regist,
                :member => {:new=>:get, :create=>:post, :scan_name=>:get}
  map.resources :documents
  map.resources :organizations
  map.resources :members
  map.resources :lecture_times
  map.resources :article_people
  map.resources :article_groups
  map.resources :attached_files,
                :collection=>{:test=>:get,:af=>:get,:progress=>:post, :cleaner=>:get, :clean=>:post}
  map.resources :teachers  # as lecture_member
  map.resources :tas       # as lecture_member
  map.resources :students  # as lecture_member
  map.resources :authors   # as thesis author
  map.resources :report_comments
  map.resources :seminar_member__teachers
  map.resources :seminar_member__students,
                :collection => {:search => :get}

  
  map.resources :mails
  map.resources :mail_tos
  map.resources :mail_accounts

  # 旧サーバとの互換性を保つため（並松コメント）
 # map.connect '/uploads/:sender/:dir/*file', :controller=>"old", :action=>"download"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
