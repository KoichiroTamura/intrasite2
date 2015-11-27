=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module ValidityErrorHelper
  
  def validity_error_holder(attr)
    content_tag( :div,  "", :class =>  "validity-error-message #{attr}")
  end
  
  # javascript to clear content of validity_error_holder
  def clear_error_holder(attr)
    "this.adjacent('div.validity-error-message.#{attr}').all(function(d){d.update('')});"
  end
end