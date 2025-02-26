require "gslide/concerns/requests"

module Gslide
  module Models
    GOOGLE_SLIDES = "https://slides.googleapis.com/v1/presentations"

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
    end
  end
end
