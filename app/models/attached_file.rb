=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

# CAUTION:  ファイル名"filer"から変更．

# == Schema Information
# Schema version: 70
#
#  id               :integer(11)   not null, primary key
#  filename         :text          # CAUTION 値を"name"に移す．
#  read_from        :text          # CAUTION "original_name"に変更すること．
#  directory        :text 
# 以下，拡張性を持たせるためにpolymorphismを利用する．
#* file_attachable_run_id      :integer(11)   # CAUTION 　追加する. 13~18まで(article_run_idなど)のnilでないものの値をここに入れる
#* file_attachable_type        :string(255)   # CAUTION 　追加する　 13~18までのnilでない値を持つもののモデル名をここに入れる．たとえば，"Article"　(変更したものに注意）
#  article_run_id   :integer(11)   # CAUTION: 使用しない.　モデル名　"Article"
#  syllabus_run_id  :integer(11)   # CAUTION: 使用しない.　モデル名　"Syallabus"　（変更に注意）2009/10/29変更
#  exercise_run_id  :integer(11)   # CAUTION: 使用しない.　モデル名　"Exercise"
#  report_run_id    :integer(11)   # CAUTION: 使用しない.　モデル名　"Report"
#  user_info_run_id :integer(11)   # CAUTION: 使用しない.　モデル名　"UserInfo"
#  theory_run_id    :integer(11)   # CAUTION: 使用しない.　モデル名 "Thesis" （変更に注意）
#  run_id           :integer(11)   
#  create_at        :datetime      
#  created_by       :integer(11)   
#  create_comment   :text          
#  delete_at        :datetime      
#  deleted_by       :integer(11)   
#  delete_comment   :text          
#  version          :integer(11)   
#  count            :integer(11)   
#  since            :datetime      
#  till             :datetime      
#  parent_run_id    :integer(11)   
#  root_run_id      :integer(11)   
#  seq              :string(255)   
#  full_seq         :text          
#  marged_from      :string(255)   
#  splitted_from    :string(255)   
#  data_type        :string(255)   
#  name             :string(255)   
#  fullname         :string(255)   
#
# 2013.8.1 追記
# [必須項目] 通常はattached_files_controller.rbのcreate_or_updateで設定される
#  filename         :TEXT           必須 サーバー内部に保存される時のファイル名
#  original_name    :longtext       必須 本当のファィル名 ( filename =original_name は 旧システムの互換性維持のため )
#  directory        :text           必須 ( 通常は学生番号。学生番号より下の階層があるものは旧システムの互換性維持のため )
#  checksum         :string         UUID (必須)

require 'uuidtools' 

class AttachedFile < Run            # CAUTION: "Filer"から変更すること．
  set_table_name "attached_files"   # CAUTION: "filers"から変更すること．
  
  def self.create_file(temp_file)
    original_name = base_part_of(temp_file.original_filename)
    name          = UUID.timestamp_create.to_s + "_" + current_account.run_id
    checksum      = UUIDTools::UUID.random_create.to_s
    File.new("#{RAILS_ROOT}/data/#{name}","w").binmode.write(temp_file.binmode.read).close
    with_scope(:create => {:filename => name, :original_name => original_name, :checksum => checksum}) do super() end
  end

  private
  
  def base_part_of(fn)
    File.basename(fn).gsub(/[^\w\.\-]/,'_')
  end
  

end
