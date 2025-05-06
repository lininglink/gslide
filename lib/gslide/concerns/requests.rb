require "net/http"

module Gslide
  module Concerns
    module Requests
      def get_request(uri, auth_token: "")
        req = Net::HTTP::Get.new(uri.to_s)
        req['Authorization'] = "Bearer #{auth_token}"

        res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          http.request(req)
        end
        response_body = JSON(res.body)

        case res
        when Net::HTTPSuccess
          response_body
        when Net::HTTPUnauthorized
          msg = response_body["error"] ? response_body["error"]["message"] : "Unauthorized"
          raise Gslide::UnauthorizedError, msg
        else
          msg = response_body["error"] ? response_body["error"]["message"] : "HTTPError"
          raise Gslide::HTTPError, msg
        end
      end

      def post_request(uri, auth_token: "", body: {})
        req = Net::HTTP::Post.new(uri.to_s)
        req.initialize_http_header 'Content-Type' => 'application/json'
        req['Authorization'] = "Bearer #{auth_token}"

        req.body = body

        res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          http.request(req)
        end

        response_body = JSON(res.body)

        case res
        when Net::HTTPSuccess
          response_body
        when Net::HTTPUnauthorized
          msg = response_body["error"] ? response_body["error"]["message"] : "Unauthorized"
          raise Gslide::UnauthorizedError, msg
        when Net::HTTPTooManyRequests
          # "Quota exceeded for quota metric 'Write requests' and limit 'Write requests per minute per user' of service 'slides.googleapis.com' for consumer 'project_number:012345678901'."
          if response_body["error"] && response_body["error"]["message"] =~ /Quota exceeded/
            raise Gslide::QuotaExceededError, msg
          else
            raise Gslide::HTTPError, msg || "TooManyRequests"
          end
        else
          msg = response_body["error"] ? response_body["error"]["message"] : "HTTPError"
          raise Gslide::HTTPError, msg
        end
      end
    end
  end
end
