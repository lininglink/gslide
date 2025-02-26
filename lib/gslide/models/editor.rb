module Gslide
  module Models

    class Editor
      attr_reader :token

      def initialize(token)
        if token.to_s.empty?
          raise ArgumentError.new("Auth Token must be present")
        end

        @token = token
      end
    end
  end
end
