=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module ExercisesHelper
    
  def publicity_level(is_open)
    is_open ? "公開する" : "提出者と出題者のみ閲覧可とする"
  end
  
end