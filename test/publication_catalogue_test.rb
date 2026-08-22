# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "test_helper"
require_relative "dummy/config/environment"

require "rails/test_help"

class PublicationCatalogueEngineTest < ActiveSupport::TestCase
  ONE_PIXEL_PNG = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  ).freeze

  test "PublicationCatalogue is a shared root and Publication is its only declared child" do
    assert RecordingStudio.validate_recordable_declarations!

    catalogue = RecordingStudio.recordable_declaration_for("RecordingStudioPublications::PublicationCatalogue")
    publication = RecordingStudio.recordable_declaration_for("RecordingStudioPublications::Publication")

    assert catalogue.root?
    assert catalogue.shared?
    assert_equal "Publications", catalogue.label
    assert_equal ["RecordingStudioPublications::PublicationCatalogue"],
                 RecordingStudioPublications::Publication::ALLOWED_PARENT_TYPES
    assert_equal ["RecordingStudioPublications::PublicationCatalogue"], publication.allowed_parent_types
    refute publication.root?
  end

  test "Accessible and Attachable stay off the shared catalogue root" do
    refute RecordingStudio.capability_enabled?(:accessible, for: RecordingStudioPublications::PublicationCatalogue)
    refute RecordingStudio.capability_enabled?(:attachable, for: RecordingStudioPublications::PublicationCatalogue)
    assert RecordingStudio.capability_enabled?(:accessible, for: RecordingStudioPublications::Publication)
    assert RecordingStudio.capability_enabled?(:attachable, for: RecordingStudioPublications::Publication)
  end

  test "catalogue_root.record creates a Publication under the shared root" do
    recording = RecordingStudioPublications.catalogue_root.record(RecordingStudioPublications::Publication) do |publication|
      publication.name = "Engine Magazine"
      publication.kind = "magazine"
      publication.website = "https://engine.example"
    end

    assert_equal "Engine Magazine", recording.recordable.name
    assert_equal "magazine", recording.recordable.kind
    assert_equal "engine-magazine", recording.recordable.key
    assert_equal RecordingStudioPublications.catalogue_root, recording.parent_recording
    assert RecordingStudioPublications.catalogue_root.shared_root?
  end

  test "Publication is rejected under Workspace" do
    workspace_root = RecordingStudio.root_recording_for(Workspace.create!(name: "Not Catalogue #{SecureRandom.hex(4)}"))

    error = assert_raises(RecordingStudio::InvalidParent) do
      workspace_root.record(RecordingStudioPublications::Publication) do |publication|
        publication.name = "Wrong Parent"
        publication.kind = "site"
      end
    end

    assert_match(/RecordingStudioPublications::Publication cannot be recorded under Workspace/, error.message)
  end

  test "name and kind are required and kind is a short list" do
    publication = RecordingStudioPublications::Publication.new
    assert_not publication.valid?
    assert_includes publication.errors[:name], "can't be blank"
    assert_includes publication.errors[:kind], "can't be blank"

    publication.name = "Titled"
    publication.kind = "zine"
    assert_not publication.valid?
    assert_includes publication.errors[:kind], "is not included in the list"

    publication.kind = "journal"
    publication.website = "not-a-url"
    assert_not publication.valid?
    assert_includes publication.errors[:website], "must be an http or https URL"
  end

  test "Publication attaches one image logo through Attachable replace" do
    actor = User.create!(
      email: "logo-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    admin_recording = admin_root_recording_for_test
    bootstrap_owner_access!(actor, admin_recording)

    recording = RecordingStudioPublications.record_publication!(
      { name: "Logo Title", kind: "newspaper" },
      actor: actor
    )
    logo = RecordingStudioPublications.attach_or_replace_logo!(
      recording.recordable,
      io: StringIO.new(ONE_PIXEL_PNG),
      filename: "masthead.png",
      content_type: "image/png",
      actor: actor
    )

    assert_equal "RecordingStudioAttachable::Attachment", logo.recordable_type
    assert_equal "image", logo.recordable.attachment_kind
    assert_equal recording, logo.parent_recording
    assert logo.recordable.file.attached?

    replaced = RecordingStudioPublications.attach_or_replace_logo!(
      recording.recordable,
      io: StringIO.new(ONE_PIXEL_PNG),
      filename: "replacement.png",
      content_type: "image/png",
      actor: actor
    )

    assert_equal logo.id, replaced.id
  end

  test "Accessible grants are rejected on the shared catalogue root" do
    actor = User.create!(
      email: "grant-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    result = RecordingStudioAccessible.grant_access(
      recording: RecordingStudioPublications.catalogue_root,
      actor: actor,
      role: :admin,
      manager_actor: actor
    )

    assert result.failure?
    assert_match(/shared root/i, result.error.to_s)
  end
end
