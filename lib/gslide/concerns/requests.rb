require "json"
require "net/http"

module Gslide

  # @private
  module Concerns
    module Requests
      OPEN_TIMEOUT = 10
      READ_TIMEOUT = 60

      # Attempts for a GET request, including the first one.
      # GET is safe to repeat, so it retries on quota errors, 5xx and timeouts.
      GET_ATTEMPTS = 3

      def get_request(uri, auth_token: "")
        attempts = 0
        begin
          attempts += 1
          req = Net::HTTP::Get.new(uri.to_s)
          perform_request(uri, req, auth_token)
        rescue Gslide::QuotaExceededError, Gslide::ServerError, Gslide::TimeoutError
          raise unless attempts < GET_ATTEMPTS

          sleep retry_delay(attempts)
          retry
        end
      end

      # POST is not retried here: a request that failed on the server may
      # still have been applied. Callers retry where it is safe, as
      # Presentation#batch_update does for quota errors.
      def post_request(uri, auth_token: "", body: {})
        req = Net::HTTP::Post.new(uri.to_s)
        req.initialize_http_header 'Content-Type' => 'application/json'
        req.body = body

        perform_request(uri, req, auth_token)
      end

      private

      # Seconds to wait after failed attempt number +attempts+: 20, 50, 100...
      def retry_delay(attempts)
        10 + attempts * attempts * 10
      end

      def perform_request(uri, req, auth_token)
        req['Authorization'] = "Bearer #{auth_token}"

        res = Net::HTTP.start(uri.host, uri.port,
                              use_ssl: uri.scheme == 'https',
                              open_timeout: OPEN_TIMEOUT,
                              read_timeout: READ_TIMEOUT) do |http|
          http.request(req)
        end

        handle_response(res.code.to_i, res.body)
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise Gslide::TimeoutError, "#{e.class} from #{uri.host}"
      end

      # @param [Integer] status the HTTP status code.
      # @param [String, nil] body the response body.
      # @return [Hash] the parsed body of a successful response.
      def handle_response(status, body)
        response_body = parse_body(body)

        if (200..299).cover?(status)
          return response_body if response_body

          raise Gslide::HTTPError, "Invalid JSON response"
        end

        msg = error_message(response_body)

        case status
        when 401
          raise Gslide::UnauthorizedError, msg || "Unauthorized"
        when 403
          if rate_limited?(response_body)
            raise Gslide::QuotaExceededError, msg || "RateLimitExceeded"
          end

          raise Gslide::ForbiddenError, msg || "Forbidden"
        when 404
          raise Gslide::NotFoundError, msg || "NotFound"
        when 429
          # "Quota exceeded for quota metric 'Write requests' and limit 'Write requests per minute per user' of service 'slides.googleapis.com' for consumer 'project_number:012345678901'."
          if msg =~ /Quota exceeded/
            raise Gslide::QuotaExceededError, msg
          else
            raise Gslide::HTTPError, msg || "TooManyRequests"
          end
        when 500..599
          raise Gslide::ServerError, msg || "ServerError"
        else
          raise Gslide::HTTPError, msg || "HTTPError"
        end
      end

      # @return [Hash, nil] the parsed body, {} for an empty body,
      #   or nil when the body is not a JSON object (e.g. an HTML error page).
      def parse_body(body)
        return {} if body.nil? || body.strip.empty?

        parsed = JSON(body)
        parsed.is_a?(Hash) ? parsed : nil
      rescue JSON::ParserError
        nil
      end

      def error_message(response_body)
        error = response_body && response_body["error"]
        error.is_a?(Hash) ? error["message"] : nil
      end

      # Drive reports rate limits as 403 with one of these reasons.
      def rate_limited?(response_body)
        error = response_body && response_body["error"]
        return false unless error.is_a?(Hash) && error["errors"].is_a?(Array)

        error["errors"].any? { |e| %w[rateLimitExceeded userRateLimitExceeded].include?(e["reason"]) }
      end
    end
  end
end
