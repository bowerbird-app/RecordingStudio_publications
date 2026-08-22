# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PublicationsAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  ONE_PIXEL_PNG = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  ).freeze

  setup do
    @admin = User.find_or_create_by!(email: "admin-publications-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    @admin_recording = admin_root_recording_for_test
    Current.actor = @admin
  end

  teardown do
    Current.actor = nil
  end

  test "registers the publications section, screen, resource, and count widget" do
    assert_equal RecordingStudioPublications::Admin::PublicationsSection,
                 RecordingStudioAdmin.section_for("publications")
    assert_equal RecordingStudioPublications::Admin::PublicationsScreen,
                 RecordingStudioAdmin.screen_for("publications")
    assert_equal RecordingStudioPublications::Admin::PublicationsResource,
                 RecordingStudioAdmin.resource_for("publications")
    assert RecordingStudioAdmin.widget_for("widgets.publications.total")
    assert_equal :site, RecordingStudioPublications::Admin::PublicationsSection.blast_radius
    assert_equal :site, RecordingStudioPublications::Admin::PublicationsScreen.blast_radius
    assert_equal :site, RecordingStudioPublications::Admin::PublicationsResource.blast_radius
    assert_equal :admin, RecordingStudioPublications::Admin::PublicationsResource.action_for(:edit).required_access_role
    assert_equal :admin, RecordingStudioPublications::Admin::PublicationsResource.action_for(:new).required_access_role
  end

  test "rejects an actor without AdminRoot access and permits the site admin" do
    sign_in @admin

    get recording_studio_publications.admin_publications_path
    assert_response :forbidden

    get "/admin/sections/publications"
    assert_response :forbidden

    bootstrap_owner_access!(@admin, @admin_recording)

    get recording_studio_publications.admin_publications_path
    assert_redirected_to "/admin/screens/publications"

    get "/admin/sections/publications"
    assert_response :success
    assert_includes response.body, "Publications"
    assert_includes response.body, "New"
    refute_includes response.body, "Manage access"
    refute_includes response.body, "Manage-access"
    refute_includes response.body, "+ Access"
    assert_includes response.body, 'href="/recording_studio_publications/admin/publications/new"'

    get "/admin/screens/publications"
    assert_response :success
    assert_includes response.body, "New"
    refute_includes response.body, "flat-pack-button-group"
  end

  test "admin can CRUD a publication through Resource required_role admin" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin

    get recording_studio_publications.new_admin_publication_path
    assert_response :success
    assert_includes response.body, "Name"
    assert_includes response.body, "Key"
    assert_includes response.body, "Kind"
    assert_includes response.body, "Website"
    assert_includes response.body, "Logo"
    assert_includes response.body, "Cancel"
    assert_includes response.body, "Save"
    refute_includes response.body, "ButtonGroup"

    post recording_studio_publications.admin_publications_path, params: {
      publication: {
        name: "Admin Created Journal",
        key: "admin-created-journal",
        kind: "journal",
        website: "https://journal.example",
        logo: Rack::Test::UploadedFile.new(logo_tempfile.path, "image/png")
      }
    }

    publication = RecordingStudioPublications.publications.find_by!(key: "admin-created-journal")
    recording = RecordingStudioPublications.recording_for(publication)
    assert_redirected_to recording_studio_publications.admin_publication_path(recording)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Admin Created Journal"
    assert_includes response.body, "Journal"
    assert RecordingStudioPublications.logo_recording_for(publication).present?

    get recording_studio_publications.edit_admin_publication_path(recording)
    assert_response :success
    assert_includes response.body, "Edit publication"

    patch recording_studio_publications.admin_publication_path(recording), params: {
      publication: {
        name: "Admin Revised Journal",
        key: "admin-created-journal",
        kind: "journal",
        website: "https://journal.example/revised"
      }
    }

    recording.reload
    assert_equal "Admin Revised Journal", recording.recordable.name
    assert_redirected_to recording_studio_publications.admin_publication_path(recording)
  end

  test "view-only users cannot open new or edit" do
    view_only = User.find_or_create_by!(email: "view-only-publications-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    bootstrap_owner_access!(@admin, @admin_recording)
    grant_admin_access_for_test!(recording: @admin_recording, actor: view_only, role: :view)
    sign_in view_only

    recording = RecordingStudioPublications.record_publication!(
      { name: "View Only Title", kind: "site" },
      actor: @admin
    )

    get recording_studio_publications.new_admin_publication_path
    assert_response :forbidden

    get recording_studio_publications.edit_admin_publication_path(recording)
    assert_response :forbidden

    post recording_studio_publications.admin_publications_path, params: {
      publication: { name: "Blocked", kind: "site" }
    }
    assert_response :forbidden
  end

  test "admin screens and forms do not ship a Manage-access UI" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
    recording = RecordingStudioPublications.record_publication!(
      { name: "No Access UI", kind: "magazine" },
      actor: @admin
    )

    [
      "/admin/sections/publications",
      "/admin/screens/publications",
      recording_studio_publications.admin_publication_path(recording),
      recording_studio_publications.edit_admin_publication_path(recording),
      recording_studio_publications.new_admin_publication_path
    ].each do |path|
      get path
      assert_response :success, path
      refute_includes response.body, "Manage access", path
      refute_includes response.body, "Manage-access", path
    end

    admin_source = File.read(RecordingStudioPublications::Engine.root.join("lib/recording_studio_publications/admin.rb"))
    refute_includes admin_source, "user.admin?"
    refute_includes admin_source, "Pundit"
    refute_includes admin_source, "Manage access"
  end

  private

  def logo_tempfile
    @logo_tempfile ||= begin
      file = Tempfile.new(["logo", ".png"])
      file.binmode
      file.write(ONE_PIXEL_PNG)
      file.rewind
      file
    end
  end
end
