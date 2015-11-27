=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end


# bases for handling articles ("メッセージ"　in old intrasite)
class ArticlesController < ArticleThreadsController
  
 protected

  def prepare_for_destroying
     @controller_name_to_delete = @background_params[:controller]
  end

end
