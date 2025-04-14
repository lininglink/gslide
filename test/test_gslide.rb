# frozen_string_literal: true

require "test_helper"

class TestGslide < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Gslide::VERSION
  end

  def test_initialized_presentation_with_url
    url = "https://docs.google.com/presentation/d/1W11pzmSEH7EoZXiMITa-cOM1y9Ym6Yby9pj_2l5NPm8/edit?usp=sharing"

    presentation = Gslide::Presentation.new(url, auth: nil)
    assert_equal "1W11pzmSEH7EoZXiMITa-cOM1y9Ym6Yby9pj_2l5NPm8", presentation.id
  end

  def test_initialized_with_presentation_id
    presentation_id = "1W11pzmSEH7EoZXiMITa-cOM1y9Ym6Yby9pj_2l5NPm8"

    presentation = Gslide::Presentation.new(presentation_id, auth: nil)
    assert_equal "1W11pzmSEH7EoZXiMITa-cOM1y9Ym6Yby9pj_2l5NPm8", presentation.id
  end
end
