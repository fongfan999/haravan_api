require 'test_helper'

class LimitsTest < Test::Unit::TestCase
  def setup
    HaravanAPI::Base.site = "test.myharavan.com"
    @header_hash = {'http_x_haravan_shop_api_call_limit' => '100/300'}
    HaravanAPI::Base.connection.expects(:response).at_least(0).returns(@header_hash)
  end

  context "Limits" do
    should "fetch limit total" do
      assert_equal(299, HaravanAPI.credit_limit(:shop))
    end

    should "fetch used calls" do
      assert_equal(100, HaravanAPI.credit_used(:shop))
    end

    should "calculate remaining calls" do
      assert_equal(199, HaravanAPI.credit_left)
    end

    should "flag maxed out credits" do
      assert !HaravanAPI.maxed?
      @header_hash = {'http_x_haravan_shop_api_call_limit' => '299/300'}
      HaravanAPI::Base.connection.expects(:response).at_least(1).returns(@header_hash)
      assert HaravanAPI.maxed?
    end

    should "raise error when header doesn't exist" do
      @header_hash = {}
      HaravanAPI::Base.connection.expects(:response).at_least(1).returns(@header_hash)
      assert_raise HaravanAPI::Limits::LimitUnavailable do
        HaravanAPI.credit_left
      end
    end
  end
end
