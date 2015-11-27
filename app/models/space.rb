=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class Space < Position

  # STI subclass

  ROOT = "スペース|"
  Default = "スペース|Aキャンパス|会議室|"

  def self.entity_by_name(fullname)
    result = find :first, :scope => ":self",
         :conditions => {:fullname => fullname}
    result.blank? and fail "the root does not exist."
    result
  end

end
