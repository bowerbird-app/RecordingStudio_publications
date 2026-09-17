# frozen_string_literal: true

module RecordingStudioPublications
  module PublishedArticlesHelper
    def article_screenshot_preview_path(attachment_recording, variant: :square_med)
      publication_logo_preview_path(attachment_recording, variant: variant)
    end

    def article_screenshot_upload_path(article_recording, return_to:)
      publication_logo_upload_path(article_recording, return_to: return_to)
    end

    def article_screenshot_replace_path(attachment_recording, return_to:)
      publication_logo_replace_path(attachment_recording, return_to: return_to)
    end

    def article_presence_options
      [
        ["Any", ""],
        ["Yes", "yes"],
        ["No", "no"]
      ]
    end

    def article_sort_options
      [
        ["Newest first", "published_on_desc"],
        ["Oldest first", "published_on_asc"],
        ["Title A–Z", "title_asc"]
      ]
    end
  end
end
