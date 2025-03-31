require "gslide/models/editor"
require "gslide/models/presentation"
require "gslide/models/spreadsheet"

module Gslide
  module Models
    GOOGLE_SLIDES = "https://slides.googleapis.com/v1/presentations"
    GOOGLE_SHEETS = "https://sheets.googleapis.com/v4/spreadsheets"
  end

  include Models
end
