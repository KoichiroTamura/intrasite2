=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

require 'test_helper'
require 'performance_test_help'

# Profiling results for each test method are written to tmp/performance.
class BrowsingTest < ActionController::PerformanceTest
  def test_homepage
    get '/'
  end
end
