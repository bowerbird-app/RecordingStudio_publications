# frozen_string_literal: true

require "test_helper"

class PublicationTypeTest < Minitest::Test
  def test_parse_returns_closed_tokens
    type = RecordingStudioPublications::PublicationType.parse("magazine")

    assert_equal "magazine", type.token
    assert_equal "Magazine", type.label
    assert_equal "magazine", type.to_s
  end

  def test_parse_rejects_unknown_tokens
    error = assert_raises(ArgumentError) do
      RecordingStudioPublications::PublicationType.parse("zine")
    end

    assert_equal "unknown publication type", error.message
  end

  def test_try_parse_returns_nil_for_unknown
    assert_nil RecordingStudioPublications::PublicationType.try_parse("zine")
    assert_nil RecordingStudioPublications::PublicationType.try_parse(nil)
  end

  def test_select_options_are_label_token_pairs
    assert_equal(
      [
        %w[Magazine magazine],
        %w[Newspaper newspaper],
        %w[Journal journal],
        %w[Site site],
        %w[Broadcast broadcast]
      ],
      RecordingStudioPublications::PublicationType.select_options
    )
  end

  def test_new_is_private
    assert_raises(NoMethodError) do
      RecordingStudioPublications::PublicationType.new("magazine")
    end
  end

  def test_logo_authorization_constant_is_gone
    refute RecordingStudioPublications.const_defined?(:LogoAuthorization)
    refute File.exist?(File.expand_path("../lib/recording_studio_publications/logo_authorization.rb", __dir__))
    assert RecordingStudioPublications.const_defined?(:FamilyAuthorization)
  end
end
