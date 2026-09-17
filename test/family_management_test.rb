# frozen_string_literal: true

require "test_helper"

class FamilyManagementTest < Minitest::Test
  FakeRecording = Struct.new(:recordable_type, :parent_recording)

  def test_publication_parent_walks_publishable_child_up
    publication = FakeRecording.new("RecordingStudioPublications::Publication", nil)
    child = FakeRecording.new("RecordingStudioPublishable::Publishable", publication)

    assert_equal publication, RecordingStudioPublications::FamilyManagement.publication_parent(child)
    assert_equal publication, RecordingStudioPublications::FamilyManagement.publication_parent(publication)
    assert_nil RecordingStudioPublications::FamilyManagement.publication_parent(
      FakeRecording.new("Page", nil)
    )
  end

  def test_preview_wrap_is_part_of_family_management
    assert RecordingStudioPublications::FamilyManagement.const_defined?(:Preview)
    assert RecordingStudioPublications::FamilyManagement::Preview.const_defined?(:Authorization)
    assert RecordingStudioPublications::FamilyManagement::Preview.const_defined?(:EnsureChild)
  end
end
