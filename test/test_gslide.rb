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

  def test_file_id_in_url
    url = "https://docs.google.com/presentation/d/1W11pzmSEH7EoZXiMITa-cOM1y9Ym6Yby9pj_2l5NPm8/edit?usp=sharing"

    assert_equal "1W11pzmSEH7EoZXiMITa-cOM1y9Ym6Yby9pj_2l5NPm8", Gslide::Presentation.file_id_in(url)
  end

  def test_file_id_in_id
    presentation_id = "1W11pzmSEH7EoZXiMITa-cOM1y9Ym6Yby9pj_2l5NPm8"

    assert_equal presentation_id, Gslide::Presentation.file_id_in(presentation_id)
  end

  def test_generate_object_id
    id = Gslide::Presentation.generate_object_id

    assert_equal 12, id.length
    assert_match(/\A#{Gslide::Presentation::OBJECT_ID_PATTERN}\z/, id)
    refute_equal id, Gslide::Presentation.generate_object_id
  end

  def test_generate_object_id_of_any_allowed_length
    assert_equal 5, Gslide::Presentation.generate_object_id(5).length
    assert_equal 50, Gslide::Presentation.generate_object_id(50).length
    assert_raises(ArgumentError) { Gslide::Presentation.generate_object_id(4) }
    assert_raises(ArgumentError) { Gslide::Presentation.generate_object_id(51) }
  end

  def test_object_id_pattern
    assert_match(/\A#{Gslide::Presentation::OBJECT_ID_PATTERN}\z/, "_aZ09-:x")
    refute_match(/\A#{Gslide::Presentation::OBJECT_ID_PATTERN}\z/, "-NxhA9ykPiQ1")
  end

  def test_presentation_id_pattern_matches_a_file_id
    assert_match(/\A#{Gslide::Presentation::PRESENTATION_ID_PATTERN}\z/, "1W11pzmSEH7EoZ-XiMITa_cOM")
    refute_match(/\A#{Gslide::Presentation::PRESENTATION_ID_PATTERN}\z/, "javascript:alert(1)")
  end
end
