# frozen_string_literal: true

module RecordingStudioPublications
  module Catalogue
    # One Attachable image logo per publication. Replace stays on Attachable.
    module Logos
      def logo_recording_for(publication)
        recording = recording_for(publication)
        return if recording.blank? || !recording.respond_to?(:images)

        recording.images.first
      end

      def attach_or_replace_logo!(publication, io:, filename:, content_type:, actor: nil)
        recording = required_publication_recording(publication)
        existing = logo_recording_for(recording)
        return import_logo!(recording, io:, filename:, content_type:, actor:) unless existing

        replace_logo!(existing, io:, filename:, content_type:, actor:)
      end

      def import_logo!(recording, io:, filename:, content_type:, actor:)
        recording.import_attachment(io:, filename:, content_type:, name: "Logo", actor:)
      end

      def replace_logo!(existing, io:, filename:, content_type:, actor:)
        blob = ActiveStorage::Blob.create_and_upload!(io:, filename:, content_type:)
        existing.replace_attachment_file(signed_blob_id: blob.signed_id, name: "Logo", actor:)
      end
    end
  end
end
