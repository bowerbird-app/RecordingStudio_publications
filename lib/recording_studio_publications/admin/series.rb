# frozen_string_literal: true

module RecordingStudioPublications
  module Admin
    module Series
      def titles_by_kind_series
        counts = RecordingStudioPublications.publications.reorder(nil).group(:kind).count

        [{
          name: "Titles",
          data: PublicationType::TOKENS.map { |kind| { x: PublicationType.parse(kind).label, y: counts[kind].to_i } }
        }]
      end

      def titles_over_time_series
        [{ name: "Publications", data: cumulative_weekly_counts(weekly_title_counts) }]
      end

      def articles_over_time_series
        [{ name: "Articles", data: cumulative_weekly_counts(weekly_article_counts) }]
      end

      def cumulative_weekly_counts(points)
        running = 0

        points.map do |point|
          running += point[:y].to_i
          { x: point[:x], y: running }
        end
      end

      def weekly_title_counts
        RecordingStudioAdmin::AdminActivityLogsSupport.date_series(
          RecordingStudioPublications.publications.reorder(nil),
          field: :created_at,
          bucket: :week
        )
      end

      def weekly_article_counts
        RecordingStudioAdmin::AdminActivityLogsSupport.date_series(
          RecordingStudioPublications.articles.reorder(nil),
          field: :created_at,
          bucket: :week
        )
      end
    end
  end
end
