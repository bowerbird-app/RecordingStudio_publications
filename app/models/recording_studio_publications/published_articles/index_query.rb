# frozen_string_literal: true

module RecordingStudioPublications
  module PublishedArticles
    class IndexQuery
      include IndexFilters

      FILTER_KEYS = %i[q year byline sort has_url has_screenshot].freeze
      SORTS = {
        "published_on_desc" => "published_on DESC NULLS LAST, title ASC",
        "published_on_asc" => "published_on ASC NULLS LAST, title ASC",
        "title_asc" => "title ASC"
      }.freeze

      Entry = Data.define(:article, :recording, :screenshot_recording)

      def initialize(publication:, params: {})
        @publication = publication
        raw = if params.respond_to?(:permit)
                params.permit(*FILTER_KEYS).to_h
              else
                params.to_h
              end
        @params = raw.with_indifferent_access
      end

      def entries
        recordings_by_recordable_id = recordings.index_by(&:recordable_id)
        screenshots_by_id = screenshot_recordings.index_by(&:parent_recording_id)

        articles.map do |article|
          recording = recordings_by_recordable_id[article.id]
          Entry.new(
            article: article,
            recording: recording,
            screenshot_recording: recording && screenshots_by_id[recording.id]
          )
        end
      end

      def articles
        scope = RecordingStudioPublications.articles_for(@publication)
        scope = apply_search(scope)
        scope = apply_year(scope)
        scope = apply_byline(scope)
        scope = apply_url_filter(scope)
        scope = apply_screenshot_filter(scope)
        scope.order(Arel.sql(sort_order))
      end

      def year_options
        article_years.map { |year| [year.to_s, year.to_s] }
      end

      def sort_key
        SORTS.key?(@params[:sort].to_s) ? @params[:sort].to_s : "published_on_desc"
      end

      def search_value
        @params[:q].to_s
      end

      def year_value
        @params[:year].to_s
      end

      def byline_value
        @params[:byline].to_s
      end

      def url_filter
        @params[:has_url].to_s
      end

      def screenshot_filter
        @params[:has_screenshot].to_s
      end

      private

      def recordings
        RecordingStudioPublications.article_recordings_for(@publication)
      end

      def sort_order
        SORTS.fetch(sort_key)
      end

      def article_years
        RecordingStudioPublications.articles_for(@publication)
                                   .where.not(published_on: nil)
                                   .distinct
                                   .pluck(Arel.sql("EXTRACT(YEAR FROM published_on)::int"))
                                   .compact
                                   .sort
                                   .reverse
      end

      def screenshot_recordings
        RecordingStudio::Recording.where(
          recordable_type: "RecordingStudioAttachable::Attachment",
          recordable_id: RecordingStudioAttachable::Attachment.images.select(:id),
          parent_recording_id: recordings.select(:id),
          trashed_at: nil
        )
      end

      def screenshot_article_recordable_ids
        recordings.where(id: screenshot_recordings.select(:parent_recording_id)).select(:recordable_id)
      end
    end
  end
end
