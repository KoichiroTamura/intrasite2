=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# メニューの項目を記録するモジュール
# 
# 並松追加 2009.07.22 メニュー時変動対応 新規作成
#
# intrasite2-tからintrasite2-nbへ移動 2009.07.28
# 
# 親クラス : Run
# 呼び出しコントローラ : CornersController
# 
#== Schema Information
# 
#  create_table "corners", :force => true do |t|
#    t.integer  "run_id",                              :default => 0,                       :null => false
#    t.integer  "parent_run_id",                       :default => 0,                       :null => false
#    t.string   "role",                                :default => "guest,user,test,admin", :null => false
#    t.boolean  "logined"                              :default => false, :null => false
#                                                     # 2009.07.29 追加 
#                                                     # ログインするまで表示してはいけないメニュー(コーナー)が出現したため
#    t.string   "url"
#    t.string   "parameters"
#    t.string   "controller"                          # 非常用  通常使用しないこと
#    t.string   "action"                              # 非常用  通常使用しないこと
#    t.string   "name"
#    t.integer  "created_by"
#    t.integer  "deleted_by"
#    t.datetime "created_at",                          :default => '2001-04-01 00:00:00',   :null => false
#    t.datetime "since",                               :default => '2001-04-01 00:00:00',   :null => false
#    t.datetime "deleted_at",                          :default => '9999-12-31 23:59:59',   :null => false
#    t.datetime "till",                                :default => '9999-12-31 23:59:59',   :null => false
#    t.string   "seq"
#    t.text     "fullseq",       :limit => 2147483647
#    t.text     "fullseq_sub",   :limit => 2147483647
#    t.string   "fullname"
#    t.integer  "merged_to"
#    t.integer  "split_from"
#  end
#
#  add_index "corners", ["created_by"], :name => "index_corners_on_created_by"
#  add_index "corners", ["deleted_by"], :name => "index_corners_on_deleted_by"
#  add_index "corners", ["parent_run_id"], :name => "index_corners_on_parent_run_id"
#  add_index "corners", ["run_id"], :name => "index_corners_on_run_id"
# 
#=urlカラムについて
#urlには、urlを生成するヘルパーメソッドを入れる。 
# 
#parametersにはurlのヘルパーメソッド用の引数をRubyのハッシュ形式で書き込む
# 
#ヘルパーメソッドがない場合は、controller・actionで指定内容を記入することで対応できる。ただしこの場合は、urlがnilであること 
# 
# 例
# :name=>"バス時刻表", :url=>"bus_diagram_path", :parameters=>":name=>'浄水'"
# 
# :name=>"バス時刻表", :url=>nil, :controller=>"bus_diagrams" :parameters=>":name=>'浄水'"
# 
class Corner < Run
  set_table_name  "corners"
  
  define_association :menus, :dependant, 
                     "Menu", " .parent_run_id >> :self", 
                     :order => "corners.fullseq"
  
end

