=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

class Destination < Run
  
  # root of STI for article destination
  # subclasses are
  #   ToIndividual
  #   ToGroup
  #   ToOrganization
end