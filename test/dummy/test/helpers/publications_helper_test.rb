# frozen_string_literal: true

require "test_helper"

class PublicationsHelperTest < ActionView::TestCase
  include RecordingStudioPublications::PublicationsHelper

  test "public page button says Publish until the title is live or scheduled" do
    assert_equal "Publish", publication_public_page_button_text(nil)
    assert_equal "Publish", publication_public_page_button_text(fake_publishable(scheduled: false, published: false))
    assert_equal "Change schedule", publication_public_page_button_text(fake_publishable(scheduled: true, published: true))
    assert_equal "Public page", publication_public_page_button_text(fake_publishable(scheduled: false, published: true))
  end

  private

  def fake_publishable(scheduled:, published:)
    Object.new.tap do |publishable|
      publishable.define_singleton_method(:scheduled_for_future?) { scheduled }
      publishable.define_singleton_method(:published_state?) { published }
    end
  end
end
