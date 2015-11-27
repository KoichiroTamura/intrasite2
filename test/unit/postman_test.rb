=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

require File.dirname(__FILE__) + '/../test_helper'

class PostmanTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    @expected.mime_version = '1.0'
  end

  def test_remainder
    @expected.subject = 'Postman#remainder'
    @expected.body    = read_fixture('remainder')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Postman.create_remainder(@expected.date).encoded
  end

  def test_news
    @expected.subject = 'Postman#news'
    @expected.body    = read_fixture('news')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Postman.create_news(@expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/postman/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
