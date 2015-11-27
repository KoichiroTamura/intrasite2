=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

#  create_table "mail_accounts", :force => true do |t|
#    t.string   "description"
#    t.string   "address"
#    t.string   "fullname"
#    t.string   "pop_server"
#    t.integer  "pop_port"
#    t.string   "pop_auth"
#    t.string   "pop_username"
#    t.string   "pop_password"
#    t.string   "smtp_server"
#    t.integer  "smtp_port"
#    t.string   "smtp_auth"
#    t.string   "smtp_username"
#    t.string   "smtp_password"
#    t.string   "include_account"
#    t.boolean  "default",                                  :default => false
#    t.string   "username"
#    t.boolean  "delete_messages",                          :default => false
#    t.string   "reply_to"
#    t.string   "requires_smtp_auth"
#    t.string   "signature"
#    t.integer  "run_id",                                   :default => 0,                     :null => false
#    t.integer  "user_info_run_id",                         :default => 0,                     :null => false
#    t.string   "name"
#    t.integer  "created_by"
#    t.integer  "deleted_by"
#    t.datetime "created_at",                               :default => '2001-04-01 00:00:00', :null => false
#    t.datetime "since",                                    :default => '2001-04-01 00:00:00', :null => false
#    t.datetime "deleted_at",                               :default => '9999-12-31 23:59:59', :null => false
#    t.datetime "till",                                     :default => '9999-12-31 23:59:59', :null => false
#    t.string   "seq"
#    t.text     "fullseq",            :limit => 2147483647
#    t.text     "fullseq_sub",        :limit => 2147483647
#    t.integer  "merged_to"
#    t.integer  "split_from"
#    t.boolean  "pop_ssl_enable",                           :default => false,                 :null => false
#    t.boolean  "smtp_ssl_enable",                          :default => false,                 :null => false
#  end
#
#  add_index "mail_accounts", ["created_by"], :name => "index_mail_accounts_on_created_by"
#  add_index "mail_accounts", ["deleted_by"], :name => "index_mail_accounts_on_deleted_by"
#  add_index "mail_accounts", ["run_id"], :name => "index_mail_accounts_on_run_id"
#
class MailAccount < Run
  set_table_name "mail_accounts"
end
