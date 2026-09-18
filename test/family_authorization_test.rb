# frozen_string_literal: true

require "test_helper"

class FamilyAuthorizationTest < Minitest::Test
  def test_blank_actor_is_denied
    request = RecordingStudioPublications::FamilyAuthorization::Request.new(
      actor: nil,
      recording: Object.new,
      role: :edit
    )

    refute RecordingStudioPublications::FamilyAuthorization.allow?(request)
  end

  def test_call_matches_attachable_authorize_with_shape
    denied = RecordingStudioPublications::FamilyAuthorization.call(
      action: :upload,
      actor: nil,
      recording: Object.new,
      role: :edit
    )

    refute denied
  end

  FakeRecording = Struct.new(:recordable_type, :parent_recording)

  def test_policy_recording_walks_article_and_attachment_to_publication
    publication = FakeRecording.new("RecordingStudioPublications::Publication", nil)
    article = FakeRecording.new("RecordingStudioPublications::PublishedArticle", publication)
    screenshot = FakeRecording.new("RecordingStudioAttachable::Attachment", article)

    assert_equal publication, RecordingStudioPublications::FamilyAuthorization.policy_recording_for(article)
    assert_equal publication, RecordingStudioPublications::FamilyAuthorization.policy_recording_for(screenshot)
    assert_equal publication, RecordingStudioPublications::FamilyAuthorization.policy_recording_for(publication)
  end
end
