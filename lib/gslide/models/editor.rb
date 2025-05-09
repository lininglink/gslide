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
      # @return [Gslide::Models::Presentation] presentation id.
      # @see https://developers.google.com/slides/api/reference/rest/v1/presentations/create#request-body
      def insert_presentation(options = {})
        uri = URI(GOOGLE_SLIDES + "")

        # "title" is the only allowed field in the request body
        response_body = post_request(uri, auth_token: @token, body: options.to_json)
        Presentation.new response_body["presentationId"], auth: self
      end
    end
  end
end
