require "gslide/concerns/requests"

module Gslide
  module Models
    # Drive calls for decks: copy a template (into a folder). Works with the narrow `drive.file`
    # scope for files the user picked or the app created, and with shared drives.
    #
    #   drive = Gslide::Models::Drive.new(auth: editor)
    #   deck_id = drive.copy(template_id, name: "Monthly Report", folder_id: folder_id)
    class Drive
      include Concerns::Requests

      FILE_ID_PATTERN = /\A[a-zA-Z0-9\-_]+\z/

      def initialize(auth: nil)
        @auth = auth
      end

      # @param [String] file_id the file to copy, e.g. a template presentation.
      # @param [String] name the copy's name.
      # @param [String, nil] folder_id the folder to put the copy in; nil for the original's folder.
      # @return [String] the copy's file id.
      # @see https://developers.google.com/workspace/drive/api/reference/rest/v3/files/copy
      def copy(file_id, name:, folder_id: nil)
        body = { name: name }
        body[:parents] = [checked(folder_id)] if folder_id
        uri = URI(GOOGLE_DRIVE + "/#{checked(file_id)}/copy?supportsAllDrives=true")

        post_request(uri, auth_token: @auth.token, body: body.to_json).fetch("id")
      end

      private

      def checked(file_id)
        unless file_id.to_s.match?(FILE_ID_PATTERN)
          raise ArgumentError, "invalid Drive file id: #{file_id.inspect}"
        end

        file_id
      end
    end
  end
end
