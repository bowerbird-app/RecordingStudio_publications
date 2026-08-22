# frozen_string_literal: true

module RecordingStudioPublications
  # Public write and lookup helpers for the shared Publications catalogue.
  module Catalogue
    PUBLICATION_ATTRIBUTE_KEYS = %i[name key kind website].freeze

    module_function

    def catalogue_recordable
      PublicationCatalogue.first || PublicationCatalogue.create!
    end

    def catalogue_root
      RecordingStudio.root_recording_for(catalogue_recordable)
    end

    def publications
      Publication.where(id: current_publication_recordings.select(:recordable_id)).order(:name)
    end

    def current_publication_recordings
      RecordingStudio::Recording.where(
        recordable_type: Publication.name,
        parent_recording: catalogue_root,
        trashed_at: nil
      )
    end

    def recording_for(publication)
      return if publication.blank?
      return publication if publication.is_a?(RecordingStudio::Recording) &&
                            publication.recordable_type == Publication.name

      RecordingStudio::Recording.find_by(
        recordable_type: Publication.name,
        recordable_id: publication.id,
        trashed_at: nil
      )
    end

    def logo_recording_for(publication)
      recording = recording_for(publication)
      return unless recording&.respond_to?(:images)

      recording.images.first
    end

    def key_in_use?(key, except_recording: nil)
      return false if key.blank?

      current_publication_recordings.any? do |recording|
        next if except_recording && recording.id == except_recording.id

        recording.recordable&.key == key
      end
    end

    def record_publication!(attrs = {}, actor: nil)
      attributes = publication_attributes(attrs)
      attributes[:key] = attributes[:key].presence || Publication.unique_key_for(attributes[:name])
      publication = Publication.new(attributes)
      if key_in_use?(publication.key)
        publication.errors.add(:key, "has already been taken")
        raise ActiveRecord::RecordInvalid, publication
      end

      catalogue_root.record(Publication, actor: actor) do |recordable|
        assign_publication_attributes(recordable, attributes)
      end
    end

    def revise_publication!(publication, attrs = {}, actor: nil)
      recording = recording_for(publication)
      raise ArgumentError, "Publication recording is missing" if recording.blank?

      attributes = publication_attributes(attrs, publication)
      draft = Publication.new(attributes)
      if key_in_use?(draft.key, except_recording: recording)
        draft.errors.add(:key, "has already been taken")
        raise ActiveRecord::RecordInvalid, draft
      end

      catalogue_root.revise(recording, actor: actor) do |recordable|
        assign_publication_attributes(recordable, attributes)
      end
    end

    def attach_or_replace_logo!(publication, io:, filename:, content_type:, actor: nil)
      recording = recording_for(publication)
      raise ArgumentError, "Publication recording is missing" if recording.blank?

      existing = logo_recording_for(recording)
      if existing
        blob = ActiveStorage::Blob.create_and_upload!(
          io: io,
          filename: filename,
          content_type: content_type
        )
        existing.replace_attachment_file(
          signed_blob_id: blob.signed_id,
          name: "Logo",
          actor: actor
        )
      else
        recording.import_attachment(
          io: io,
          filename: filename,
          content_type: content_type,
          name: "Logo",
          actor: actor
        )
      end
    end

    def publication_attributes(attrs, publication = nil)
      values = attrs.to_h.symbolize_keys.slice(*PUBLICATION_ATTRIBUTE_KEYS)
      values[:name] = values[:name].presence || publication&.name
      values[:kind] = values[:kind].presence || publication&.kind
      values[:website] = values.key?(:website) ? values[:website].presence : publication&.website
      values[:key] = values[:key].presence || publication&.key
      values
    end

    def assign_publication_attributes(publication, attributes)
      publication.name = attributes[:name]
      publication.kind = attributes[:kind]
      publication.website = attributes[:website]
      publication.key = attributes[:key] if attributes[:key].present?
    end
  end
end
