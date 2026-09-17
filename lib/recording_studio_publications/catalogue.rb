# frozen_string_literal: true

require_relative "catalogue/writes"
require_relative "catalogue/logos"
require_relative "catalogue/articles"

module RecordingStudioPublications
  # Public write and lookup helpers for the shared Publications catalogue.
  module Catalogue
    PUBLICATION_ATTRIBUTE_KEYS = %i[name key kind website].freeze

    extend Writes
    extend Logos
    extend Articles

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

    def articles
      ids = RecordingStudio::Recording.where(
        recordable_type: PublishedArticle.name,
        parent_recording_id: current_publication_recordings.select(:id),
        trashed_at: nil
      ).select(:recordable_id)
      PublishedArticle.where(id: ids).order(:title)
    end

    def publication_for(article)
      article_recording_for(article)&.parent_recording&.recordable
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

    def key_in_use?(key, except_recording: nil)
      return false if key.blank?

      current_publication_recordings.any? do |recording|
        next if except_recording && recording.id == except_recording.id

        recording.recordable&.key == key
      end
    end
  end
end
