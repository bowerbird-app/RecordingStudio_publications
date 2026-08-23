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

  test "registers the publications section, screen, resource, and widgets" do
    assert_equal RecordingStudioPublications::Admin::PublicationsSection,
                 RecordingStudioAdmin.section_for("publications")
    assert_equal RecordingStudioPublications::Admin::PublicationsScreen,
                 RecordingStudioAdmin.screen_for("publications")
    assert_equal RecordingStudioPublications::Admin::PublicationsResource,
                 RecordingStudioAdmin.resource_for("publications")
    total = RecordingStudioAdmin.widget_for("widgets.publications.total")
    by_kind = RecordingStudioAdmin.widget_for("widgets.publications.by_kind")
    assert_equal :number, total.type
    assert_equal :chart, by_kind.type
    assert_equal :bar, by_kind.chart_type
    assert_nil RecordingStudioAdmin.widget_for("widgets.publications.over_time")
    section_widget_keys = RecordingStudioPublications::Admin::PublicationsSection.widget_keys
    screen_widget_keys = RecordingStudioPublications::Admin::PublicationsScreen.widget_keys
    assert_includes section_widget_keys, "widgets.publications.total"
    refute_includes screen_widget_keys, "widgets.publications.total"
    refute_includes screen_widget_keys, "widgets.publications.over_time"
    assert_empty screen_widget_keys
    assert RecordingStudioPublications::Admin::PublicationsScreen.chart_value
    assert_equal :area, RecordingStudioPublications::Admin::PublicationsScreen.chart_value.type_value
    assert_equal :site, RecordingStudioPublications::Admin::PublicationsSection.blast_radius
    assert_equal :site, RecordingStudioPublications::Admin::PublicationsScreen.blast_radius
    assert_equal :site, RecordingStudioPublications::Admin::PublicationsResource.blast_radius
    assert_equal :admin, RecordingStudioPublications::Admin::PublicationsResource.action_for(:edit).required_access_role
    assert_equal :admin, RecordingStudioPublications::Admin::PublicationsResource.action_for(:new).required_access_role
    search_filter = RecordingStudioPublications::Admin::PublicationsScreen.filters.find { |filter| filter.key == :search }
    assert search_filter
    new_button = RecordingStudioPublications::Admin::PublicationsScreen.buttons_value.find do |button|
      button.name == :new_publication
    end
    assert new_button
    assert_equal "New", new_button.text
    refute File.exist?(RecordingStudioPublications::Engine.root.join("app/overrides/recording_studio_admin/screens/show.html.erb"))
    refute_includes File.read(RecordingStudioPublications::Engine.root.join("lib/recording_studio_publications/admin.rb")),
                    "instance_variable_set"
    assert_equal RecordingStudioPublications::Publication::KINDS.map(&:titleize),
                 RecordingStudioPublications::Admin.titles_by_kind_series.first[:data].map { |point| point[:x] }
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
    assert_includes response.body, "Titles by kind"
    assert_includes response.body, "/admin/access/recordings/#{@admin_recording.id}/accesses"
    assert(
      response.body.include?("Manage access") || response.body.include?("+ Access"),
      "expected family Access UI on the AdminRoot publications section"
    )
    assert_includes response.body, 'href="/recording_studio_publications/admin/publications/new"'

    get "/admin/screens/publications"
    assert_response :success
    assert_includes response.body, "New"
    assert_includes response.body, 'name="search"'
    assert_includes response.body, 'href="/recording_studio_publications/admin/publications/new"'
    assert_includes response.body, "screen-chart"
    refute_includes response.body, "widgets.publications.over_time"
    refute_includes response.body, ">Publications</h3>"

    get "/admin/screens/publications/chart"
    assert_response :success
    assert_includes response.body, "Titles over time"
    assert_includes response.body, "screen-chart"

    get "/admin/screens/publications/table"
    assert_response :success
    assert_includes response.body, "Table data"
    assert_includes response.body, "Name"
    assert_includes response.body, "Kind"
    assert_includes response.body, "Website"
    refute_match(/<th[^>]*>Key<\/th>/i, response.body)
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
    assert_includes response.body, "Cancel"
    assert_includes response.body, "Save"
    refute_includes response.body, "ButtonGroup"
    refute_includes response.body, "publication[logo]"
    refute_includes response.body, "FileInput"
    refute_includes response.body, "Add logo"
    refute_includes response.body, "Change logo"
    refute_includes response.body, "multipart/form-data"

    post recording_studio_publications.admin_publications_path, params: {
      publication: {
        name: "Admin Created Journal",
        key: "admin-created-journal",
        kind: "journal",
        website: "https://journal.example"
      }
    }

    publication = RecordingStudioPublications.publications.find_by!(key: "admin-created-journal")
    recording = RecordingStudioPublications.recording_for(publication)
    assert_redirected_to recording_studio_publications.admin_publication_path(recording)
    assert_nil RecordingStudioPublications.logo_recording_for(publication)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Admin Created Journal"
    assert_includes response.body, "Journal"
    assert_includes response.body, "Add logo"
    refute_includes response.body, "Change logo"
    refute_includes response.body, "publication[logo]"
    refute_includes response.body, "FileInput"
    assert_includes response.body, recording_studio_attachable.recording_attachment_upload_path(recording)

    get recording_studio_publications.edit_admin_publication_path(recording)
    assert_response :success
    assert_includes response.body, "Edit publication"
    assert_includes response.body, "Add logo"
    refute_includes response.body, "publication[logo]"
    refute_includes response.body, "FileInput"
    refute_includes response.body, "multipart/form-data"

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

  test "show and edit link to Attachable add and replace screens" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
    recording = RecordingStudioPublications.record_publication!(
      { name: "Masthead Daily", kind: "newspaper" },
      actor: @admin
    )
    logo = attach_png_logo!(recording)

    get recording_studio_publications.admin_publication_path(recording)
    assert_response :success
    assert_includes response.body, "Change logo"
    refute_includes response.body, "Add logo"
    refute_includes response.body, "publication[logo]"
    refute_includes response.body, "FileInput"
    assert_includes response.body, recording_studio_attachable.attachment_path(logo)
    refute_includes response.body, recording_studio_attachable.recording_attachments_path(recording)

    get recording_studio_publications.edit_admin_publication_path(recording)
    assert_response :success
    assert_includes response.body, "Change logo"
    refute_includes response.body, "publication[logo]"
    refute_includes response.body, "FileInput"
    assert_includes response.body, recording_studio_attachable.attachment_path(logo)

    get recording_studio_attachable.recording_attachment_upload_path(
      recording,
      redirect_mode: "return_to",
      return_to: recording_studio_publications.admin_publication_path(recording)
    )
    assert_response :success
    assert_includes response.body, "Upload"
    assert_includes response.body, "Choose files"
    assert_equal 1, response.body.scan("flat-pack-page-nav").size
    refute_includes response.body, 'data-recording-studio-default-layout="true"'

    get recording_studio_attachable.attachment_path(
      logo,
      redirect_mode: "return_to",
      return_to: recording_studio_publications.admin_publication_path(recording)
    )
    assert_response :success
    assert_includes response.body, "Save"
    assert_includes response.body, logo.recordable.original_filename
    assert_equal 1, response.body.scan("flat-pack-page-nav").size
    refute_includes response.body, 'data-recording-studio-default-layout="true"'
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

  test "inventory search uses the family Admin filter" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
    RecordingStudioPublications.record_publication!(
      { name: "Searchable Atlantic", key: "searchable-atlantic", kind: "magazine" },
      actor: @admin
    )
    RecordingStudioPublications.record_publication!(
      { name: "Other Gazette", key: "other-gazette", kind: "newspaper" },
      actor: @admin
    )

    get "/admin/screens/publications/table", params: { search: "Atlantic" }
    assert_response :success
    assert_includes response.body, "Searchable Atlantic"
    refute_includes response.body, "Other Gazette"
  end

  test "publication CRUD pages do not ship a per-title Manage-access UI" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
    recording = RecordingStudioPublications.record_publication!(
      { name: "No Access UI", kind: "magazine" },
      actor: @admin
    )

    [
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

  test "publications persist helpers do not wrap Attachable uploads" do
    catalogue = File.read(RecordingStudioPublications::Engine.root.join("lib/recording_studio_publications/catalogue/logos.rb"))
    controller = File.read(RecordingStudioPublications::Engine.root.join("app/controllers/recording_studio_publications/publications_controller.rb"))
    gem_api = File.read(RecordingStudioPublications::Engine.root.join("lib/recording_studio_publications.rb"))

    refute_includes catalogue, "attach_or_replace_logo!"
    refute_includes catalogue, "import_logo!"
    refute_includes catalogue, "replace_logo!"
    refute_includes controller, "attach_uploaded_logo!"
    refute_includes controller, "publication[:logo]"
    refute_includes gem_api, "attach_or_replace_logo!"
  end

  private

  def attach_png_logo!(recording)
    recording.import_attachment(
      io: StringIO.new(ONE_PIXEL_PNG),
      filename: "masthead.png",
      content_type: "image/png",
      name: "Logo",
      actor: @admin
    )
  end
end
