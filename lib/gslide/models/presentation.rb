require "gslide/concerns/requests"

module Gslide
  module Models
    class Presentation
      include Concerns::Requests

      def initialize(id, auth: nil)
        @id = id
        @auth = auth
      end

      # @return [Hash] data from a Google Slides file
      # @see https://developers.google.com/slides/api/reference/rest/v1/presentations/get
      def get
        uri = URI(GOOGLE_SLIDES + "/#{@id}")

        res = get_request(uri, auth_token: @auth.token)
        JSON(res.body)
      end

      def link_url
        "https://docs.google.com/presentation/d/#{@id}/edit"
      end
    end
  end
end
