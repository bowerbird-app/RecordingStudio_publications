# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class FamilyManagementTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.find_or_create_by!(email: "family-admin-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    @member = User.find_or_create_by!(email: "family-member-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    @admin_recording = admin_root_recording_for_test
    Current.actor = @admin
    @publication_recording = RecordingStudioPublications.record_publication!(
      { name: "Family Mag", kind: "magazine" },
      actor: @admin
    )
  end

  teardown do
    Current.actor = nil
  end

  test "install is idempotent and does not restack wrappers" do
    config = RecordingStudioPublishable.configuration
    first = RecordingStudioPublications::FamilyManagement.install!(config)
    second = RecordingStudioPublications::FamilyManagement.install!(config)

    assert_nil first
    assert_nil second
    assert RecordingStudioPublications::FamilyManagement.installed?(config)
  end

  test "other-type authorizer still runs after install" do
    config = RecordingStudioPublishable::Configuration.new
    seen = []
    config.management_authorizer = lambda { |recording:, actor:, **|
      seen << [recording.recordable_type, actor&.id]
      recording.recordable_type == "Page"
    }
    assert_same config, RecordingStudioPublications::FamilyManagement.install!(config)
    assert_nil RecordingStudioPublications::FamilyManagement.install!(config)

    workspace = Workspace.create!(name: "Family Fallback #{SecureRandom.hex(4)}")
    root = RecordingStudio.root_recording_for(workspace)
    page_recording = root.record(Page.new(title: "Fallback Page"), actor: @admin, parent_recording: root)

    assert config.authorize_management?(recording: page_recording, actor: @admin)
    assert_equal [["Page", @admin.id]], seen
    refute config.authorize_management?(recording: @publication_recording, actor: @member)
  end

  test "AdminRoot staff can open publish edit" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin

    get recording_studio_publishable.edit_recording_publishable_path(recording_id: @publication_recording.id)
    assert_response :success
  end

  test "signed-in member without AdminRoot cannot open publish edit" do
    sign_in @member

    get recording_studio_publishable.edit_recording_publishable_path(recording_id: @publication_recording.id)
    assert_response :forbidden
  end

  test "per-title edit grant is enough without AdminRoot" do
    grant_admin_access_for_test!(recording: @publication_recording, actor: @member, role: :edit)
    sign_in @member

    get recording_studio_publishable.edit_recording_publishable_path(recording_id: @publication_recording.id)
    assert_response :success
  end

  test "show offers a secondary Publish button when edit is allowed" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin

    get recording_studio_publications.admin_publication_path(@publication_recording)
    assert_response :success
    assert_includes response.body, "Publish"
    refute_includes response.body, "Public page"
    assert_includes response.body, "/recordings/#{@publication_recording.id}/publishable/edit"
    assert_includes response.body, "Edit"
  end

  test "published show and edit offer Public page instead of Publish" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: @publication_recording,
      actor: @admin,
      attributes: { status: "published", slug: "family-mag" }
    )
    raise result.error if result.failure?

    get recording_studio_publications.admin_publication_path(@publication_recording)
    assert_response :success
    assert_includes response.body, "Published"
    assert_includes response.body, "Public page"
    refute_match(/>Publish</, response.body)
    assert_includes response.body, "/recordings/#{@publication_recording.id}/publishable/edit"

    get recording_studio_publications.edit_admin_publication_path(@publication_recording)
    assert_response :success
    assert_includes response.body, "Published"
    assert_includes response.body, "Public page"
    refute_match(/>Publish</, response.body)
  end
end
