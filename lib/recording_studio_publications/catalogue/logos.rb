# frozen_string_literal: true

module RecordingStudioPublications
  module Catalogue
    # Lookup for the single Attachable image on a Publication. Persist stays
    # on Attachable (`import_attachment` / `replace_attachment_file`).
    module Logos
      def logo_recording_for(publication)
        recording = recording_for(publication)
        return if recording.blank? || !recording.respond_to?(:images)

        recording.images(per_page: 1).first
      end
    end
  end
end
