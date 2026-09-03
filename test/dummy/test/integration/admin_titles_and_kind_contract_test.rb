# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class AdminTitlesAndKindContractTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.find_or_create_by!(email: "admin-titles-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    @admin_recording = admin_root_recording_for_test
    Current.actor = @admin
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
  end

  teardown do
    Current.actor = nil
  end

  test "section title is independent of screen widget catalogue and app name" do
    assert_equal "publications", RecordingStudioPublications::Admin::SECTION_KEY
    assert_equal "publications", RecordingStudioPublications::Admin::SCREEN_KEY
    assert_equal "widgets.publications.by_kind", RecordingStudioPublications::Admin::WIDGET_BY_KIND
    assert_equal "Admin publications", RecordingStudioPublications::Admin::PublicationsSection.title
    assert_equal "Publications", RecordingStudioPublications::Admin::PublicationsScreen.title
    assert_equal "Publications",
                 RecordingStudioPublications::Admin::TotalPublicationsWidget.title
    assert_equal "Titles by publication type",
                 RecordingStudioPublications::Admin::TitlesByKindWidget.title
    assert_equal "Publications",
                 RecordingStudio.recordable_declaration_for("RecordingStudioPublications::PublicationCatalogue").label
    assert_equal "Publications", RecordingStudio.configuration.app_name
    assert_equal "Admin publications", I18n.t("recording_studio_publications.admin.section_title")
    assert_equal "Publications", I18n.t("recording_studio_publications.admin.screen_title")
    assert_equal "Publications", I18n.t("recording_studio_publications.admin.total_widget_title")
  end

  test "kind remains the param sort search and widget key" do
    publication = RecordingStudioPublications::Publication.new
    publication.valid?
    assert_includes publication.errors.full_messages, "Publication type can't be blank"

    post recording_studio_publications.admin_publications_path, params: {
      publication: {
        name: "Kind Contract Title",
        key: "kind-contract-title",
        kind: "journal",
        publication_type: "broadcast",
        website: "https://kind.example"
      }
    }

    created = RecordingStudioPublications.publications.find_by!(key: "kind-contract-title")
    assert_equal "journal", created.kind
    refute_equal "broadcast", created.kind

    get "/admin/screens/publications/table", params: { sort: "kind", columns: ["kind"] }
    assert_response :success
    assert_includes response.body, "Publication type"
    assert_includes request.original_fullpath, "sort=kind"
  end

  test "public hook controller has no auth callbacks" do
    controller = RecordingStudioPublications::PublicPublicationsController
    refute controller < ApplicationController
    callback_names = controller._process_action_callbacks.map(&:filter)
    refute_includes callback_names, :authenticate_user!
    refute_includes callback_names, :set_current_actor
  end
end
