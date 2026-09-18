# frozen_string_literal: true

module RecordingStudioPublications
  module Catalogue
    module Articles
      ARTICLE_ATTRIBUTE_KEYS = %i[title url canonical_url published_on byline excerpt].freeze

      def record_article!(publication, attrs = {}, actor: nil)
        publication_recording = required_publication_recording(publication)
        attributes = article_attributes(attrs)
        reject_duplicate_article_url!(PublishedArticle.new(attributes), parent_recording: publication_recording)
        catalogue_root.record(
          PublishedArticle,
          actor: actor,
          parent_recording: publication_recording
        ) do |recordable|
          assign_article_attributes(recordable, attributes)
        end
      end

      def revise_article!(article, attrs = {}, actor: nil)
        recording = required_article_recording(article)
        attributes = article_attributes(attrs, article)
        reject_duplicate_article_url!(
          PublishedArticle.new(attributes),
          parent_recording: recording.parent_recording,
          except_recording: recording
        )
        catalogue_root.revise(recording, actor: actor) do |recordable|
          assign_article_attributes(recordable, attributes)
        end
      end

      def articles_for(publication)
        PublishedArticle.where(id: article_recordings_for(publication).select(:recordable_id))
      end

      def article_recordings_for(publication)
        publication_recording = recording_for(publication)
        return RecordingStudio::Recording.none if publication_recording.blank?

        RecordingStudio::Recording.where(
          recordable_type: PublishedArticle.name,
          parent_recording: publication_recording,
          trashed_at: nil
        )
      end

      def article_recording_for(article)
        return if article.blank?
        return article if article.is_a?(RecordingStudio::Recording) &&
                          article.recordable_type == PublishedArticle.name

        RecordingStudio::Recording.find_by(
          recordable_type: PublishedArticle.name,
          recordable_id: article.id,
          trashed_at: nil
        )
      end

      def screenshot_recording_for(article)
        recording = article_recording_for(article)
        return if recording.blank? || !recording.respond_to?(:images)

        recording.images(per_page: 1).first
      end

      def url_in_use?(url, parent_recording:, except_recording: nil)
        return false if url.blank? || parent_recording.blank?

        article_recordings_for(parent_recording).any? do |recording|
          next if except_recording && recording.id == except_recording.id

          recording.recordable&.url == url
        end
      end

      private

      def article_attributes(attrs, article = nil)
        values = attrs.to_h.symbolize_keys.slice(*ARTICLE_ATTRIBUTE_KEYS)
        merge_article_attributes(values, article)
      end

      def assign_article_attributes(article, attributes)
        article.title = attributes[:title]
        article.url = attributes[:url]
        article.canonical_url = attributes[:canonical_url]
        article.published_on = attributes[:published_on]
        article.byline = attributes[:byline]
        article.excerpt = attributes[:excerpt]
      end

      def merge_article_attributes(values, article)
        values[:title] = values[:title].presence || article&.title
        %i[url canonical_url published_on byline excerpt].each do |field|
          values[field] = values.key?(field) ? values[field].presence : article&.public_send(field)
        end
        values
      end

      def reject_duplicate_article_url!(article, parent_recording:, except_recording: nil)
        return unless url_in_use?(
          article.url,
          parent_recording: parent_recording,
          except_recording: except_recording
        )

        article.errors.add(:url, "has already been taken")
        raise ActiveRecord::RecordInvalid, article
      end

      def required_article_recording(article)
        recording = article_recording_for(article)
        raise ArgumentError, "Article recording is missing" if recording.blank?

        recording
      end
    end
  end
end
