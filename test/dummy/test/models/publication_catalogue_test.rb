# frozen_string_literal: true

require "test_helper"

class PublicationCatalogueTest < ActiveSupport::TestCase
  test "PublicationCatalogue is a shared root labelled Publications" do
    declaration = RecordingStudio.recordable_declaration_for("RecordingStudioPublications::PublicationCatalogue")

    assert RecordingStudio.validate_recordable_declarations!
    assert declaration.root?
    assert declaration.shared?
    assert_equal "Publications", declaration.label
    assert RecordingStudio.shared_root_type?("RecordingStudioPublications::PublicationCatalogue")
    assert_includes RecordingStudio.shared_root_types, "RecordingStudioPublications::PublicationCatalogue"
  end

  test "Accessible and Attachable are not enabled on the shared catalogue root" do
    refute RecordingStudio.capability_enabled?(:accessible, for: RecordingStudioPublications::PublicationCatalogue)
    refute RecordingStudio.capability_enabled?(:attachable, for: RecordingStudioPublications::PublicationCatalogue)
    catalogue_source = File.read(
      RecordingStudioPublications::Engine.root.join("app/models/recording_studio_publications/publication_catalogue.rb")
    )
    refute_includes catalogue_source, "enable_capability(:accessible"
    refute_includes catalogue_source, "Capabilities::Attachable"
  end

  test "Publication only allows the shared catalogue as a parent" do
    declaration = RecordingStudio.recordable_declaration_for("RecordingStudioPublications::Publication")

    assert_equal ["RecordingStudioPublications::PublicationCatalogue"], declaration.allowed_parent_types
    refute declaration.root?
    assert RecordingStudio.capability_enabled?(:accessible, for: RecordingStudioPublications::Publication)
    assert RecordingStudio.capability_enabled?(:attachable, for: RecordingStudioPublications::Publication)
  end
end
