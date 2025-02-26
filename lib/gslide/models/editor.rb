require "gslide/concerns/requests"

module Gslide
  module Models

    class Editor
      include Concerns::Requests

      attr_reader :token

      def initialize(token)
        if token.to_s.empty?
          raise ArgumentError.new("Auth Token must be present")
        end

        @token = token
      end

      # @param [Hash] options the body for the POST request.
      # @return [String] presentation id
      # @see https://developers.google.com/slides/api/reference/rest/v1/presentations/create#request-body
      def insert_presentation(options = {})
        uri = URI(GOOGLE_SLIDES + "")

        res = post_request(uri, auth_token: @token, body: options.to_json)
        response_body = JSON(res.body)

        if response_body["error"]
          raise Gslide::Error.new(response_body["error"]["message"])
        end
        response_body["presentationId"]
      end
    end
  end
end
