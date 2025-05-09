# frozen_string_literal: true

require_relative "gslide/version"
require_relative "string"

require "gslide/models/models"

module Gslide
  class Error < StandardError; end
  class HTTPError < Error; end
  class UnauthorizedError < HTTPError; end
  class QuotaExceededError < HTTPError; end
end
