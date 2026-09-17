# frozen_string_literal: true

module RecordingStudioPublications
  module PublishedArticles
    module IndexFilters
      private

      def apply_search(scope)
        return scope if search_value.blank?

        pattern = RecordingStudioPublications::Admin.safe_like(search_value)
        scope.where(search_sql, q: pattern)
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

      def apply_url_filter(scope)
        case url_filter
        when "yes"
          scope.where.not(url: [nil, ""])
        when "no"
          scope.where(url: [nil, ""])
        else
          scope
        end
      end

      def apply_screenshot_filter(scope)
        ids = screenshot_article_recordable_ids
        case screenshot_filter
        when "yes"
          scope.where(id: ids)
        when "no"
          scope.where.not(id: ids)
        else
          scope
        end
      end

      def search_sql
        "title ILIKE :q OR COALESCE(byline, '') ILIKE :q OR " \
          "COALESCE(url, '') ILIKE :q OR COALESCE(excerpt, '') ILIKE :q"
      end
    end
  end
end
