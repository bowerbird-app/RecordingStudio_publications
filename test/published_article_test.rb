# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "dummy/test/test_helper"

class PublishedArticleTest < ActiveSupport::TestCase
  ONE_PIXEL_PNG = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  ).freeze

  test "PublishedArticle is a domain child of Publication only" do
    assert RecordingStudio.validate_recordable_declarations!

    article = RecordingStudio.recordable_declaration_for("RecordingStudioPublications::PublishedArticle")

    assert_equal ["RecordingStudioPublications::Publication"],
                 RecordingStudioPublications::PublishedArticle::ALLOWED_PARENT_TYPES
    assert_equal ["RecordingStudioPublications::Publication"], article.allowed_parent_types
    refute article.root?
    assert_equal "Article", article.label
    refute RecordingStudio.capability_enabled?(:accessible, for: RecordingStudioPublications::PublishedArticle)
    refute RecordingStudio.capability_enabled?(:publishable, for: RecordingStudioPublications::PublishedArticle)
    assert RecordingStudio.capability_enabled?(:attachable, for: RecordingStudioPublications::PublishedArticle)
  end

  test "record_article! nests under the publication recording" do
    publication_recording = record_title!
    article_recording = RecordingStudioPublications.record_article!(
      publication_recording.recordable,
      {
        title: "House in the Rainforest",
        url: "https://example.com/house",
        canonical_url: "https://example.com/house-canonical",
        published_on: Date.new(2024, 3, 12),
        byline: "Jane Architect",
        excerpt: "A house among trees."
      },
      actor: catalogue_admin_actor
    )

    assert_equal publication_recording, article_recording.parent_recording
    assert_equal "House in the Rainforest", article_recording.recordable.title
    assert_equal "https://example.com/house", article_recording.recordable.url
    assert_includes RecordingStudioPublications.articles_for(publication_recording.recordable).map(&:title),
                    "House in the Rainforest"
    assert_equal article_recording, RecordingStudioPublications.article_recording_for(article_recording.recordable)
  end

  test "PublishedArticle is rejected under Workspace and the catalogue root" do
    workspace_root = RecordingStudio.root_recording_for(Workspace.create!(name: "Not Publication #{SecureRandom.hex(4)}"))

    workspace_error = assert_raises(RecordingStudio::InvalidParent) do
      workspace_root.record(RecordingStudioPublications::PublishedArticle, parent_recording: workspace_root) do |article|
        article.title = "Wrong Parent"
      end
    end
    assert_match(/PublishedArticle cannot be recorded under Workspace/, workspace_error.message)

    catalogue_error = assert_raises(RecordingStudio::InvalidParent) do
      RecordingStudioPublications.catalogue_root.record(RecordingStudioPublications::PublishedArticle) do |article|
        article.title = "Catalogue Child"
      end
    end
    assert_match(/PublishedArticle cannot be recorded under RecordingStudioPublications::PublicationCatalogue/,
                 catalogue_error.message)
  end

  test "title is required and URLs must be http" do
    article = RecordingStudioPublications::PublishedArticle.new
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"

    article.title = "Titled"
    article.url = "not-a-url"
    assert_not article.valid?
    assert_includes article.errors[:url], "must be an http or https URL"

    article.url = "https://example.com/story"
    article.canonical_url = "ftp://example.com/story"
    assert_not article.valid?
    assert_includes article.errors[:canonical_url], "must be an http or https URL"
  end

  test "live URL is unique among siblings of the same publication" do
    actor = catalogue_admin_actor
    first_title = record_title!(name: "First Mag", actor: actor)
    second_title = record_title!(name: "Second Mag", actor: actor)

    RecordingStudioPublications.record_article!(
      first_title.recordable,
      { title: "One", url: "https://example.com/shared" },
      actor: actor
    )

    error = assert_raises(ActiveRecord::RecordInvalid) do
      RecordingStudioPublications.record_article!(
        first_title.recordable,
        { title: "Two", url: "https://example.com/shared" },
        actor: actor
      )
    end
    assert_includes error.record.errors[:url], "has already been taken"

    other = RecordingStudioPublications.record_article!(
      second_title.recordable,
      { title: "Other title article", url: "https://example.com/shared" },
      actor: actor
    )
    assert_equal "https://example.com/shared", other.recordable.url
  end

  test "article stores a screenshot through Attachable replace" do
    actor = catalogue_admin_actor
    publication_recording = record_title!(actor: actor)
    article_recording = RecordingStudioPublications.record_article!(
      publication_recording.recordable,
      { title: "With Screenshot", url: "https://example.com/shot" },
      actor: actor
    )
    screenshot = article_recording.import_attachment(
      io: StringIO.new(ONE_PIXEL_PNG),
      filename: "screenshot.png",
      content_type: "image/png",
      name: "Screenshot",
      actor: actor
    )

    assert_equal "RecordingStudioAttachable::Attachment", screenshot.recordable_type
    assert_equal "image", screenshot.recordable.attachment_kind
    assert_equal article_recording, screenshot.parent_recording
    assert_equal screenshot, RecordingStudioPublications.screenshot_recording_for(article_recording.recordable)

    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(ONE_PIXEL_PNG),
      filename: "replacement.png",
      content_type: "image/png"
    )
    replaced = screenshot.replace_attachment_file(signed_blob_id: blob.signed_id, name: "Screenshot", actor: actor)
    assert_equal screenshot.id, replaced.id
  end

  test "index query filters and sorts articles for one publication" do
    actor = catalogue_admin_actor
    publication_recording = record_title!(actor: actor)
    other_recording = record_title!(name: "Other Mag", actor: actor)

    rainforest = RecordingStudioPublications.record_article!(
      publication_recording.recordable,
      {
        title: "House in the Rainforest",
        url: "https://example.com/rainforest",
        published_on: Date.new(2024, 3, 12),
        byline: "Jane Architect"
      },
      actor: actor
    )
    RecordingStudioPublications.record_article!(
      publication_recording.recordable,
      {
        title: "Ten Australian Houses",
        published_on: Date.new(2023, 11, 2),
        byline: "Sam Editor"
      },
      actor: actor
    )
    RecordingStudioPublications.record_article!(
      other_recording.recordable,
      { title: "House in the Rainforest", url: "https://other.example/rainforest" },
      actor: actor
    )
    rainforest.import_attachment(
      io: StringIO.new(ONE_PIXEL_PNG),
      filename: "rainforest.png",
      content_type: "image/png",
      name: "Screenshot",
      actor: actor
    )

    titles = lambda { |params|
      RecordingStudioPublications::PublishedArticles::IndexQuery.new(
        publication: publication_recording.recordable,
        params: params
      ).articles.map(&:title)
    }

    assert_equal ["House in the Rainforest", "Ten Australian Houses"], titles.call({})
    assert_equal ["House in the Rainforest"], titles.call(q: "rainforest")
    assert_equal ["House in the Rainforest"], titles.call(year: "2024")
    assert_equal ["Ten Australian Houses"], titles.call(byline: "Sam")
    assert_equal ["House in the Rainforest"], titles.call(has_url: "yes")
    assert_equal ["Ten Australian Houses"], titles.call(has_url: "no")
    assert_equal ["House in the Rainforest"], titles.call(has_screenshot: "yes")
    assert_equal ["Ten Australian Houses"], titles.call(has_screenshot: "no")
    assert_equal ["Ten Australian Houses", "House in the Rainforest"], titles.call(sort: "published_on_asc")
  end

  private

  def record_title!(name: "Article Host #{SecureRandom.hex(4)}", actor: catalogue_admin_actor)
    RecordingStudioPublications.record_publication!({ name: name, kind: "magazine" }, actor: actor)
  end

  def catalogue_admin_actor
    actor = User.create!(
      email: "article-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    bootstrap_owner_access!(actor, admin_root_recording_for_test)
    actor
  end
end
