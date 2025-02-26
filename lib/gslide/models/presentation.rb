require "gslide/concerns/requests"

module Gslide
  module Models
    class Presentation
      include Concerns::Requests

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

        res = post_request(uri, auth_token: @auth.token, body: options.to_json)
        response_body = JSON(res.body)

        if response_body["error"]
          raise Gslide::Error.new(response_body["error"]["message"])
        end
        response_body["presentationId"] == @id
      end
    end
  end
end
