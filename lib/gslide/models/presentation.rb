require "securerandom"
require "gslide/concerns/requests"

module Gslide
  module Models
    class Presentation
      include Concerns::Requests

      attr_reader :id

      PRESENTATION_ID_PATTERN = /[a-zA-Z0-9\-_]+/
      PRESENTATION_PATTERN = %r[/presentation/d/(#{PRESENTATION_ID_PATTERN})?]

      # An object ID (for a page, shape or table) starts with a word character,
      # followed by word characters, dashes or colons; 5 to 50 characters long.
      # @see https://developers.google.com/slides/api/reference/rest/v1/presentations.pages#Page.FIELDS.object_id
      OBJECT_ID_PATTERN = /[a-zA-Z0-9_][a-zA-Z0-9_\-:]*/
      OBJECT_ID_LENGTHS = 5..50

      # @param [Integer] length from 5 to 50.
      # @return [String] a random object ID for a new page element, e.g. "aZ3kq09XbP1t".
      def self.generate_object_id(length = 12)
        unless OBJECT_ID_LENGTHS.cover?(length)
          raise ArgumentError, "object ID length must be within #{OBJECT_ID_LENGTHS}, not #{length}"
        end

        SecureRandom.alphanumeric(length)
      end

      # @param [String] id_or_url a presentation id, or a sharing url holding one.
      # @return [String] the presentation id, or the argument when it is not a url.
      def self.file_id_in(id_or_url)
        (url_id = id_or_url.match(PRESENTATION_PATTERN)) ? url_id[1] : id_or_url
      end

      def initialize(id_or_url, auth: nil)
        @id = self.class.file_id_in(id_or_url)
        @auth = auth
      end

      # @return [Hash] data from a Google Slides presentation.
      # @see https://developers.google.com/slides/api/reference/rest/v1/presentations/get
      def get
        uri = URI(GOOGLE_SLIDES + "/#{@id}")

        response_body = get_request(uri, auth_token: @auth.token)
        response_body.convert_keys {|k| k.snake_case.to_sym }
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

        response_body = post_request(uri, auth_token: @auth.token, body: request_body)
        response_body["presentationId"] == @id
      rescue Gslide::QuotaExceededError
        if (retries += 1) < 3
          sleep 10 + retries * retries * 10

          retry
        end
        # all retries failed, raise exception
        raise
      end

      def get_slide_ids
        parsed_body = get
        parsed_body[:slides].collect { |slide| slide[:object_id] }
      end
    end
  end
end
