# frozen_string_literal: true

module RecordingStudioPublications
  module PublishedArticles
    class IndexQuery
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
        screenshots_by_article_recording_id = screenshot_recordings.index_by(&:parent_recording_id)

        articles.map do |article|
          recording = recordings_by_recordable_id[article.id]
          Entry.new(
            article: article,
            recording: recording,
            screenshot_recording: recording && screenshots_by_article_recording_id[recording.id]
          )
        end
      end

      def articles
        scope = RecordingStudioPublications.articles_for(@publication)
        scope = apply_search(scope)
        scope = apply_year(scope)
        scope = apply_byline(scope)
        scope = apply_has_url(scope)
        scope = apply_has_screenshot(scope)
        scope.order(Arel.sql(sort_order))
      end

      def year_options
        years = RecordingStudioPublications.articles_for(@publication)
                                           .where.not(published_on: nil)
                                           .distinct
                                           .pluck(Arel.sql("EXTRACT(YEAR FROM published_on)::int"))
                                           .compact
                                           .sort
                                           .reverse
        years.map { |year| [year.to_s, year.to_s] }
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

      def has_url_value
        @params[:has_url].to_s
      end

      def has_screenshot_value
        @params[:has_screenshot].to_s
      end

      private

      def recordings
        RecordingStudioPublications.article_recordings_for(@publication)
      end

      def sort_order
        SORTS.fetch(sort_key)
      end

      def apply_search(scope)
        return scope if search_value.blank?

        pattern = RecordingStudioPublications::Admin.safe_like(search_value)
        scope.where(
          "title ILIKE :q OR COALESCE(byline, '') ILIKE :q OR COALESCE(url, '') ILIKE :q OR COALESCE(excerpt, '') ILIKE :q",
          q: pattern
        )
      end

      def apply_year(scope)
        year = Integer(year_value, exception: false)
        return scope if year.blank?

        scope.where("EXTRACT(YEAR FROM published_on) = ?", year)
      end

      def apply_byline(scope)
        return scope if byline_value.blank?

        pattern = RecordingStudioPublications::Admin.safe_like(byline_value)
        scope.where("COALESCE(byline, '') ILIKE :q", q: pattern)
      end

      def apply_has_url(scope)
        case has_url_value
        when "yes"
          scope.where.not(url: [nil, ""])
        when "no"
          scope.where(url: [nil, ""])
        else
          scope
        end
      end

      def apply_has_screenshot(scope)
        ids = screenshot_article_recordable_ids
        case has_screenshot_value
        when "yes"
          scope.where(id: ids)
        when "no"
          scope.where.not(id: ids)
        else
          scope
        end
      end

      def screenshot_recordings
        article_recording_ids = recordings.select(:id)
        image_ids = RecordingStudioAttachable::Attachment.images.select(:id)

        RecordingStudio::Recording.where(
          recordable_type: "RecordingStudioAttachable::Attachment",
          recordable_id: image_ids,
          parent_recording_id: article_recording_ids,
          trashed_at: nil
        )
      end

      def screenshot_article_recordable_ids
        parent_ids = screenshot_recordings.select(:parent_recording_id)
        recordings.where(id: parent_ids).select(:recordable_id)
      end
    end
  end
end
