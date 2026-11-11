# frozen_string_literal: true

require_relative "gslide/version"
require_relative "string"

require "gslide/models/models"

module Gslide
  class Error < StandardError; end
  class HTTPError < Error; end
  class UnauthorizedError < HTTPError; end
  class ForbiddenError < HTTPError; end
  class NotFoundError < HTTPError; end
  class QuotaExceededError < HTTPError; end
  class ServerError < HTTPError; end

  # Raised when Google does not respond in time.
  class TimeoutError < Error; end
end
