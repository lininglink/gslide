require "gslide/concerns/requests"

module Gslide
  module Models
    class Presentation
      include Concerns::Requests

      attr_reader :id

      PRESENTATION_PATTERN = %r[/presentation/d/([a-zA-Z0-9\-_]+)?]

      def initialize(id_or_url, auth: nil)
        @id = (url_id = id_or_url.match(PRESENTATION_PATTERN)) ? url_id[1] : id_or_url
        @auth = auth
      end

      # @return [Hash] data from a Google Slides presentation.
      # @see https://developers.google.com/slides/api/reference/rest/v1/presentations/get
      def get
        uri = URI(GOOGLE_SLIDES + "/#{@id}")

        res = get_request(uri, auth_token: @auth.token)
        JSON(res.body).convert_keys {|k| k.snake_case.to_sym }
      end

      def link_url
        "https://docs.google.com/presentation/d/#{@id}/edit"
      end

      # @param [Hash] options the request body.
      # @return True when update successful.
      # @see https://developers.google.com/slides/api/reference/rest/v1/presentations/batchUpdate#request-body
      def batch_update(options = {})
        retries ||= 0

        uri = URI(GOOGLE_SLIDES + "/#{@id}:batchUpdate")
        request_body = options.convert_keys { |k| k.to_s.lower_camel_case }.to_json

        res = post_request(uri, auth_token: @auth.token, body: request_body)
        response_body = JSON(res.body)

        if response_body["error"]
          raise Gslide::Error.new(response_body["error"]["message"])
        end
        response_body["presentationId"] == @id

      rescue Gslide::Error => e
        if e.message =~ /Quota exceeded/ && (retries += 1) < 3
          # "Quota exceeded for quota metric 'Write requests' and limit 'Write requests per minute per user' of service 'slides.googleapis.com' for consumer 'project_number:012345678901'."
          sleep 10 + retries * retries * 10

          retry
        end
        # all retries failed, re-raise exception
        raise e
      end

      def get_slide_ids
        parsed_body = get
        parsed_body[:slides].collect { |slide| slide[:object_id] }
      end
    end
  end
end
