require 'test_helper'


class BaseTest < Test::Unit::TestCase

  def setup
    @session1 = HaravanAPI::Session.new('shop1.myharavan.com', 'token1')
    @session2 = HaravanAPI::Session.new('shop2.myharavan.com', 'token2')
  end

  def teardown
    clear_header('X-Custom')
  end

  test '#activate_session should set site and headers for given session' do
    HaravanAPI::Base.activate_session @session1

    assert_nil ActiveResource::Base.site
    assert_equal 'https://shop1.myharavan.com/admin', HaravanAPI::Base.site.to_s
    assert_equal 'https://shop1.myharavan.com/admin', HaravanAPI::Shop.site.to_s

    assert_nil ActiveResource::Base.headers['X-Haravan-Access-Token']
    assert_equal 'token1', HaravanAPI::Base.headers['X-Haravan-Access-Token']
    assert_equal 'token1', HaravanAPI::Shop.headers['X-Haravan-Access-Token']
  end

  test '#clear_session should clear site and headers from Base' do
    HaravanAPI::Base.activate_session @session1
    HaravanAPI::Base.clear_session

    assert_nil ActiveResource::Base.site
    assert_nil HaravanAPI::Base.site
    assert_nil HaravanAPI::Shop.site

    assert_nil ActiveResource::Base.headers['X-Haravan-Access-Token']
    assert_nil HaravanAPI::Base.headers['X-Haravan-Access-Token']
    assert_nil HaravanAPI::Shop.headers['X-Haravan-Access-Token']
  end

  test '#activate_session with one session, then clearing and activating with another session should send request to correct shop' do
    HaravanAPI::Base.activate_session @session1
    HaravanAPI::Base.clear_session
    HaravanAPI::Base.activate_session @session2

    assert_nil ActiveResource::Base.site
    assert_equal 'https://shop2.myharavan.com/admin', HaravanAPI::Base.site.to_s
    assert_equal 'https://shop2.myharavan.com/admin', HaravanAPI::Shop.site.to_s

    assert_nil ActiveResource::Base.headers['X-Haravan-Access-Token']
    assert_equal 'token2', HaravanAPI::Base.headers['X-Haravan-Access-Token']
    assert_equal 'token2', HaravanAPI::Shop.headers['X-Haravan-Access-Token']
  end

  test '#activate_session with nil raises an InvalidSessionError' do
    assert_raises HaravanAPI::Base::InvalidSessionError do
      HaravanAPI::Base.activate_session nil
    end
  end

  test "#delete should send custom headers with request" do
    HaravanAPI::Base.activate_session @session1
    HaravanAPI::Base.headers['X-Custom'] = 'abc'
    HaravanAPI::Base.connection.expects(:delete).with('/admin/bases/1.json', has_entry('X-Custom', 'abc'))
    HaravanAPI::Base.delete "1"
  end

  test "#headers includes the User-Agent" do
    assert_not_includes ActiveResource::Base.headers.keys, 'User-Agent'
    assert_includes HaravanAPI::Base.headers.keys, 'User-Agent'
    thread = Thread.new do
      assert_includes HaravanAPI::Base.headers.keys, 'User-Agent'
    end
    thread.join
  end

  if ActiveResource::VERSION::MAJOR >= 4
    test "#headers propagates changes to subclasses" do
      HaravanAPI::Base.headers['X-Custom'] = "the value"
      assert_equal "the value", HaravanAPI::Base.headers['X-Custom']
      assert_equal "the value", HaravanAPI::Product.headers['X-Custom']
    end

    test "#headers clears changes to subclasses" do
      HaravanAPI::Base.headers['X-Custom'] = "the value"
      assert_equal "the value", HaravanAPI::Product.headers['X-Custom']
      HaravanAPI::Base.headers['X-Custom'] = nil
      assert_nil HaravanAPI::Product.headers['X-Custom']
    end
  end

  if ActiveResource::VERSION::MAJOR >= 4 && ActiveResource::VERSION::PRE == "threadsafe"
    test "#headers set in the main thread affect spawned threads" do
      HaravanAPI::Base.headers['X-Custom'] = "the value"
      Thread.new do
        assert_equal "the value", HaravanAPI::Base.headers['X-Custom']
      end.join
    end

    test "#headers set in spawned threads do not affect the main thread" do
      Thread.new do
        HaravanAPI::Base.headers['X-Custom'] = "the value"
      end.join
      assert_nil HaravanAPI::Base.headers['X-Custom']
    end
  end

  def clear_header(header)
    [ActiveResource::Base, HaravanAPI::Base, HaravanAPI::Product].each do |klass|
      klass.headers.delete(header)
    end
  end
end
