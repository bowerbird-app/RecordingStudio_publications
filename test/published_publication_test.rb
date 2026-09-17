# frozen_string_literal: true

require "test_helper"

class PublishedPublicationTest < Minitest::Test
  FakeType = Struct.new(:label)
  FakePublication = Struct.new(:name, :publication_type, :website)

  def test_build_requires_publication
    error = assert_raises(ArgumentError) do
      RecordingStudioPublications::PublishedPublication.build(publication: nil)
    end

    assert_equal "publication is required", error.message
  end

  def test_build_projects_name_type_website_and_titles
    publication = FakePublication.new(
      "The Atlantic",
      FakeType.new("Magazine"),
      "https://www.theatlantic.com"
    )
    page = RecordingStudioPublications::PublishedPublication.build(publication: publication)

    assert_equal "The Atlantic", page.name
    assert_equal "Magazine", page.publication_type_label
    assert_equal "https://www.theatlantic.com", page.website
    assert_equal "The Atlantic", page.document_title
    assert_equal "The Atlantic", page.social_title
    assert_nil page.logo_url
    assert_nil page.logo_alt
  end

  def test_new_is_private
    assert_raises(NoMethodError) do
      RecordingStudioPublications::PublishedPublication.new(
        name: "X",
        publication_type_label: "Magazine",
        website: nil,
        logo_url: nil,
        logo_alt: nil
      )
    end
  end
end
