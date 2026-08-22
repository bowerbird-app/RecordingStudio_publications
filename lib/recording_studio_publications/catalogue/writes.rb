# frozen_string_literal: true

module RecordingStudioPublications
  module Catalogue
    # Write helpers for titles nested under the shared catalogue root.
    module Writes
      def record_publication!(attrs = {}, actor: nil)
        attributes = publication_attributes(attrs)
        attributes[:key] = attributes[:key].presence || Publication.unique_key_for(attributes[:name])
        reject_duplicate_key!(Publication.new(attributes))
        catalogue_root.record(Publication, actor: actor) do |recordable|
          assign_publication_attributes(recordable, attributes)
        end
      end

      def revise_publication!(publication, attrs = {}, actor: nil)
        recording = required_publication_recording(publication)
        attributes = publication_attributes(attrs, publication)
        reject_duplicate_key!(Publication.new(attributes), except_recording: recording)
        catalogue_root.revise(recording, actor: actor) do |recordable|
          assign_publication_attributes(recordable, attributes)
        end
      end

      def publication_attributes(attrs, publication = nil)
        values = attrs.to_h.symbolize_keys.slice(*PUBLICATION_ATTRIBUTE_KEYS)
        merge_publication_attributes(values, publication)
      end

      def assign_publication_attributes(publication, attributes)
        publication.name = attributes[:name]
        publication.kind = attributes[:kind]
        publication.website = attributes[:website]
        publication.key = attributes[:key] if attributes[:key].present?
      end

      def merge_publication_attributes(values, publication)
        %i[name kind key].each do |field|
          values[field] = values[field].presence || publication&.public_send(field)
        end
        values[:website] = values.key?(:website) ? values[:website].presence : publication&.website
        values
      end

      def reject_duplicate_key!(publication, except_recording: nil)
        return unless key_in_use?(publication.key, except_recording: except_recording)

        publication.errors.add(:key, "has already been taken")
        raise ActiveRecord::RecordInvalid, publication
      end

      def required_publication_recording(publication)
        recording = recording_for(publication)
        raise ArgumentError, "Publication recording is missing" if recording.blank?

        recording
      end
    end
  end
end
