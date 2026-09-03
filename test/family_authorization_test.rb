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
end
