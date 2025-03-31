require "gslide/concerns/requests"

module Gslide
  module Models
    class Spreadsheet
      include Concerns::Requests

      attr_reader :id

      def initialize(id, auth: nil)
        @id = id
        @auth = auth
      end

      # @return [Hash] data from a Google Sheets spreadsheet.
      # @see https://developers.google.com/workspace/sheets/api/reference/rest/v4/spreadsheets/get
      def get
        uri = URI(GOOGLE_SHEETS + "/#{@id}")

        res = get_request(uri, auth_token: @auth.token)
        JSON(res.body)
      end

      def link_url
        "https://docs.google.com/spreadsheets/d/#{@id}/edit"
      end

      # @param [Hash] options the request body.
      # @return True when update successful.
      # @see https://developers.google.com/workspace/sheets/api/reference/rest/v4/spreadsheets/batchUpdate
      def batch_update(options = {})
        uri = URI(GOOGLE_SHEETS + "/#{@id}:batchUpdate")
        request_body = options.convert_keys { |k| k.to_s.lower_camel_case }.to_json

        res = post_request(uri, auth_token: @auth.token, body: request_body)
        response_body = JSON(res.body)

        if response_body["error"]
          raise Gslide::Error.new(response_body["error"]["message"])
        end
        response_body["spreadsheetId"] == @id
      end
    end
  end
end
