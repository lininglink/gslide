require "gslide/concerns/requests"

module Gslide
  module Models
    class Presentation
      include Concerns::Requests

      attr_reader :id

      def initialize(id, auth: nil)
        @id = id
        @auth = auth
      end

      # @return [Hash] data from a Google Slides presentation.
      # @see https://developers.google.com/slides/api/reference/rest/v1/presentations/get
      def get
        uri = URI(GOOGLE_SLIDES + "/#{@id}")

        res = get_request(uri, auth_token: @auth.token)
        JSON(res.body)
      end

      def link_url
        "https://docs.google.com/presentation/d/#{@id}/edit"
      end

      # @param [Hash] options the request body.
      # @return True when update successful.
      # @see https://developers.google.com/slides/api/reference/rest/v1/presentations/batchUpdate#request-body
      def batch_update(options = {})
        uri = URI(GOOGLE_SLIDES + "/#{@id}:batchUpdate")
        request_body = options.convert_keys { |k| k.to_s.lower_camel_case }.to_json

        res = post_request(uri, auth_token: @auth.token, body: request_body)
        response_body = JSON(res.body)

        if response_body["error"]
          raise Gslide::Error.new(response_body["error"]["message"])
        end
        response_body["presentationId"] == @id
      end

      def get_slide_ids
        parsed_body = get
        parsed_body["slides"].collect { |slide| slide["objectId"] }
      end
    end
  end
end
