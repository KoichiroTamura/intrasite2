=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

require File.dirname(__FILE__) + '/../test_helper'
require 'aptana_bug_test_file_controller'

# Re-raise errors caught by the controller.
class AptanaBugTestFileController; def rescue_action(e) raise e end; end

class AptanaBugTestFileControllerTest < Test::Unit::TestCase
  def setup
    @controller = AptanaBugTestFileController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
