# frozen_string_literal: true

require "test_helper"

# Responses Google can't be made to send on demand (5xx, HTML error pages,
# rate limits) and the retry logic. No HTTP is faked: these call the
# response handling directly with a status code and body.
class TestResponseHandling < Minitest::Test
  QUOTA_MESSAGE = "Quota exceeded for quota metric 'Write requests' and limit 'Write requests per minute per user'"

  # Includes the request code, but its requests return or raise preset
  # outcomes instead of going over the network.
  class Client
    include Gslide::Concerns::Requests

    attr_reader :sleeps, :calls

    def initialize(outcomes = [])
      @outcomes = outcomes
      @sleeps = []
      @calls = 0
    end

    def sleep(seconds)
      @sleeps << seconds
    end

    def respond(status, body)
      handle_response(status, body)
    end

    private

    def perform_request(_uri, _req, _auth_token)
      @calls += 1
      outcome = @outcomes.shift
      outcome.is_a?(Exception) ? raise(outcome) : outcome
    end
  end

  def error_body(message, reason: nil)
    error = { "message" => message }
    error["errors"] = [{ "reason" => reason }] if reason
    { "error" => error }.to_json
  end

  def test_success_returns_parsed_body
    assert_equal({ "presentationId" => "abc" }, Client.new.respond(200, '{"presentationId":"abc"}'))
  end

  def test_success_with_empty_body
    assert_equal({}, Client.new.respond(204, ""))
  end

  def test_success_with_non_json_body
    error = assert_raises(Gslide::HTTPError) { Client.new.respond(200, "<html></html>") }
    assert_equal "Invalid JSON response", error.message
  end

  def test_html_error_page_is_a_server_error
    error = assert_raises(Gslide::ServerError) { Client.new.respond(502, "<html><body>Bad Gateway</body></html>") }
    assert_equal "ServerError", error.message
  end

  def test_server_error_keeps_google_message
    error = assert_raises(Gslide::ServerError) { Client.new.respond(503, error_body("The service is currently unavailable.")) }
    assert_equal "The service is currently unavailable.", error.message
  end

  def test_forbidden
    error = assert_raises(Gslide::ForbiddenError) { Client.new.respond(403, error_body("The caller does not have permission")) }
  end

  def test_forbidden_rate_limit_is_a_quota_error
    assert_raises(Gslide::QuotaExceededError) do
      Client.new.respond(403, error_body("Rate Limit Exceeded", reason: "userRateLimitExceeded"))
    end
  end

  def test_quota_error_carries_google_message
    error = assert_raises(Gslide::QuotaExceededError) { Client.new.respond(429, error_body(QUOTA_MESSAGE)) }
    assert_equal QUOTA_MESSAGE, error.message
  end

  def test_too_many_requests_without_quota_message
    error = assert_raises(Gslide::HTTPError) { Client.new.respond(429, "") }
    assert_equal "TooManyRequests", error.message
    refute_kind_of Gslide::QuotaExceededError, error
  end

  def test_get_retries_then_succeeds
    client = Client.new([Gslide::ServerError.new("down"), { "ok" => true }])

    assert_equal({ "ok" => true }, client.get_request(URI("https://example.com")))
    assert_equal 2, client.calls
    assert_equal [20], client.sleeps
  end

  def test_get_retries_timeouts_and_gives_up_after_three_attempts
    client = Client.new(Array.new(3) { Gslide::TimeoutError.new("timeout") })

    assert_raises(Gslide::TimeoutError) { client.get_request(URI("https://example.com")) }
    assert_equal 3, client.calls
    assert_equal [20, 50], client.sleeps
  end

  def test_get_does_not_retry_not_found
    client = Client.new([Gslide::NotFoundError.new("gone")])

    assert_raises(Gslide::NotFoundError) { client.get_request(URI("https://example.com")) }
    assert_equal 1, client.calls
  end

  def test_post_is_not_retried
    client = Client.new([Gslide::ServerError.new("down")])

    assert_raises(Gslide::ServerError) { client.post_request(URI("https://example.com"), body: "{}") }
    assert_equal 1, client.calls
  end

  def test_batch_update_retries_quota_errors
    presentation = Gslide::Presentation.new("abcde", auth: Gslide::Editor.new("t"))
    outcomes = [Gslide::QuotaExceededError.new(QUOTA_MESSAGE), { "presentationId" => "abcde" }]
    sleeps = []
    presentation.define_singleton_method(:sleep) { |seconds| sleeps << seconds }
    presentation.define_singleton_method(:perform_request) do |*|
      outcome = outcomes.shift
      outcome.is_a?(Exception) ? raise(outcome) : outcome
    end

    assert presentation.batch_update(requests: [])
    assert_equal [20], sleeps
  end

  def test_loads_without_rails
    script = 'require "gslide"; Gslide::Editor.new("t"); {a: 1}.to_json; JSON("{}")'
    lib = File.expand_path("../lib", __dir__)
    # A plain Ruby process, without Bundler or Rails loading json first
    env = { "RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil, "BUNDLE_BIN_PATH" => nil }

    assert system(env, RbConfig.ruby, "-I", lib, "-e", script), "gslide should load json itself"
  end
end
