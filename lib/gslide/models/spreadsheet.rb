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

        response_body = get_request(uri, auth_token: @auth.token)
        response_body.convert_keys {|k| k.snake_case.to_sym }
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

        response_body = post_request(uri, auth_token: @auth.token, body: request_body)
        response_body["spreadsheetId"] == @id
      end

      def get_sheets
        parsed_body = get
        parsed_body[:sheets].collect { |h| Sheet.new(h) }
      end

      # @param [Hash] options the request body.
      # @see https://developers.google.com/workspace/sheets/api/reference/rest/v4/spreadsheets.values/append
      def values_append(notation, options = {})
        uri = url_escape_uri(GOOGLE_SHEETS + "/#{@id}/values/'#{notation}':append?valueInputOption=USER_ENTERED")
        request_body = options.convert_keys { |k| k.to_s.lower_camel_case }.to_json

        response_body = post_request(uri, auth_token: @auth.token, body: request_body)
        response_body
      end

      private

      def url_escape_uri(uri_string)
        parser = URI::Parser.new
        URI parser.escape(uri_string)
      end
    end

    class SpreadsheetDraft
      include Concerns::Requests

      def initialize(auth: nil)
        @auth = auth
      end

      def create(options = {})
        request_body = options.convert_keys { |k| k.to_s.lower_camel_case }.to_json

        uri = URI(GOOGLE_SHEETS)
        response_body = post_request(uri, auth_token: @auth.token, body: request_body)

        spreadsheet_id = response_body["spreadsheetId"]
        Spreadsheet.new(spreadsheet_id, auth: @auth)
      end
    end

    class Sheet
      attr_reader :id, :title, :charts

      def initialize(options = {})
        @id = options[:properties][:sheet_id]
        @title = options[:properties][:title]
        @charts = options[:charts].collect { |h| Chart.new(h) } if options[:charts]
      end
    end

    class Chart
      attr_reader :id

      def initialize(options = {})
        @id = options[:chart_id]
      end
    end
  end
end
