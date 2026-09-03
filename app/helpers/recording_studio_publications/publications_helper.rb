# frozen_string_literal: true

module RecordingStudioPublications
  module PublicationsHelper
    def publication_logo_preview_path(attachment_recording, variant: :square_med)
      return if attachment_recording.blank?

      attachment = attachment_recording.recordable
      if attachment.respond_to?(:preview_target_named) && attachment.preview_target_named(variant).present?
        attachable_routes.attachment_preview_file_path(attachment_recording, variant_name: variant)
      elsif attachment.respond_to?(:file) && attachment.file&.attached?
        attachable_routes.attachment_file_path(attachment_recording)
      end
    end

    def publication_logo_upload_path(publication_recording, return_to:)
      attachable_routes.recording_attachment_upload_path(
        publication_recording,
        redirect_mode: "return_to",
        return_to: return_to
      )
    end

    def publication_logo_replace_path(attachment_recording, return_to:)
      attachable_routes.attachment_path(
        attachment_recording,
        redirect_mode: "return_to",
        return_to: return_to
      )
    end

    def publication_publishable_edit_path(recording)
      publishable_routes.edit_recording_publishable_path(recording_id: recording.id)
    end

    def publication_public_page_button_text(publishable)
      return "Publish" if publishable.blank?
      return "Change schedule" if publishable.try(:scheduled_for_future?)
      return "Public page" if publishable.try(:published_state?)

      "Publish"
    end

    private

    def attachable_routes
      return recording_studio_attachable if respond_to?(:recording_studio_attachable)

      main_app.recording_studio_attachable
    end

    def publishable_routes
      return recording_studio_publishable if respond_to?(:recording_studio_publishable)

      main_app.recording_studio_publishable
    end
  end
end
