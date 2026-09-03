# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PublicPublicationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  ONE_PIXEL_PNG = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  ).freeze

  setup do
    @admin = User.find_or_create_by!(email: "public-admin-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    Current.actor = @admin
    bootstrap_owner_access!(@admin, admin_root_recording_for_test)
  end

  teardown do
    Current.actor = nil
  end

  test "unauthenticated currently published title is 200 without staff chrome" do
    recording = record_publication("Public Atlantic")
    attach_logo!(recording)
    publish!(recording, slug: "public-atlantic")

    get "/publications/#{publishable_uuid(recording)}/public-atlantic"
    assert_response :success
    assert_includes response.body, "Public Atlantic"
    assert_includes response.body, "Magazine"
    assert_includes response.body, "Visit website"
    assert_includes response.body, "<title>Public Atlantic</title>"
    assert_includes response.body, 'property="og:type" content="article"'
    assert_equal 1, response.body.scan(/property="og:type"/).size
    assert_includes response.body, "rails/active_storage/blobs"
    refute_includes response.body, "attachment_preview_file"
    refute_includes response.body, "attachment_file_path"
    refute_includes response.body, "Go back"
    refute_includes response.body, "flat-pack-page-nav"
    assert_includes response.body, 'data-theme="rounded"'
    assert_includes response.body, "<body"
    assert_includes response.body, "flat_pack/variables"
    assert_includes response.body, "tailwind"
  end

  test "draft scheduled and expired titles are 404" do
    draft = record_publication("Draft Gazette")
    ensure_child!(draft, slug: "draft-gazette")
    get "/publications/#{publishable_uuid(draft)}/draft-gazette"
    assert_response :not_found

    scheduled = record_publication("Scheduled Journal")
    publish!(scheduled, slug: "scheduled-journal", publish_at: 1.day.from_now)
    get "/publications/#{publishable_uuid(scheduled)}/scheduled-journal"
    assert_response :not_found

    expired = record_publication("Expired Site")
    publish!(expired, slug: "expired-site")
    expire!(expired)
    get "/publications/#{publishable_uuid(expired)}/expired-site"
    assert_response :not_found
  end

  test "stale slug redirects to the current path" do
    recording = record_publication("Slug Magazine")
    publish!(recording, slug: "current-slug")

    get "/publications/#{publishable_uuid(recording)}/old-slug"
    assert_redirected_to "/publications/#{publishable_uuid(recording)}/current-slug"
  end

  test "published page model fails loudly without a publication" do
    assert_raises(ArgumentError) do
      RecordingStudioPublications::PublishedPublication.build(publication: nil)
    end
  end

  test "logo attachable limit stays 1 and publishable social limit is 10" do
    publication_options = RecordingStudio.capability_options(
      :attachable,
      for: RecordingStudioPublications::Publication
    )
    publishable_options = RecordingStudio.capability_options(
      :attachable,
      for: RecordingStudioPublishable::Publishable
    )

    assert_equal 10, publishable_options[:max_file_count]
    assert_not_equal 10, publication_options[:max_file_count]
    assert_equal 1, RecordingStudioAttachable.configuration.max_file_count
  end

  private

  def record_publication(name)
    RecordingStudioPublications.record_publication!(
      { name: name, kind: "magazine", website: "https://www.theatlantic.com" },
      actor: @admin
    )
  end

  def publish!(recording, slug:, publish_at: nil)
    attributes = { status: "published", slug: slug }
    attributes[:publish_at] = publish_at if publish_at
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: recording,
      actor: @admin,
      attributes: attributes
    )
    raise result.error if result.failure?
  end

  def ensure_child!(recording, slug:)
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: recording,
      actor: @admin,
      attributes: { status: "draft", slug: slug }
    )
    raise result.error if result.failure?
  end

  def expire!(recording)
    publishable = recording.reload.current_publishable
    publishable.class.unscoped.where(id: publishable.id).update_all(
      publish_at: 2.days.ago,
      unpublish_at: 1.day.ago
    )
  end

  def publishable_uuid(recording)
    recording.reload.publishable_child_recording.id
  end

  def attach_logo!(recording)
    recording.import_attachment(
      io: StringIO.new(ONE_PIXEL_PNG),
      filename: "logo.png",
      content_type: "image/png",
      name: "Logo",
      actor: @admin
    )
  end
end
