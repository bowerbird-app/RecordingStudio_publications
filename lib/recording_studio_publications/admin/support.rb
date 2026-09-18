# frozen_string_literal: true

module RecordingStudioPublications
  module Admin
    module Support
      def apply_publication_search(relation, value)
        return relation if value.blank?

        pattern = safe_like(value)
        relation.where(
          "name ILIKE :q OR key ILIKE :q OR kind ILIKE :q OR COALESCE(website, '') ILIKE :q",
          q: pattern
        )
      end

      def publication_filter_values
        RecordingStudioPublications.publications.map(&:key)
      end

      def apply_article_publication_filter(relation, value)
        return relation if value.blank?

        publication = publication_for_filter(value)
        return relation.none unless publication

        RecordingStudioPublications.articles_for(publication)
      end

      def publication_name_cell(publication, context)
        linked_cell(publication.name, publication_show_path(publication, context), context)
      end

      def article_count_cell(publication, context)
        count = RecordingStudioPublications.articles_for(publication).count
        linked_cell(
          count.to_s,
          with_originating_anchor(articles_screen_path(context, publication: publication), context),
          context
        )
      end

      def publication_type_count_cell(row, context)
        linked_cell(
          row.publications_count.to_s,
          with_originating_anchor("#{publications_screen_path(context)}?publication_type=#{row.token}", context),
          context
        )
      end

      def publication_type_rows
        counts = RecordingStudioPublications.publications.reorder(nil).group(:kind).count

        PublicationType::TOKENS.map do |token|
          PublicationTypeRow.new(
            token: token,
            label: PublicationType.parse(token).label,
            publications_count: counts[token].to_i
          )
        end
      end

      def article_title_cell(article, context)
        linked_cell(article.title, article_show_path(article, context), context)
      end

      def article_publication_cell(article, context)
        publication = RecordingStudioPublications.publication_for(article)
        return "—" if publication.blank?

        linked_cell(publication.name, publication_show_path(publication, context), context)
      end

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

      def safe_like(value)
        "%#{ActiveRecord::Base.sanitize_sql_like(value.to_s)}%"
      end

      private

      def publication_for_filter(value)
        RecordingStudioPublications.publications.find_by(key: value) ||
          RecordingStudioPublications.publications.find_by(name: value)
      end

      def linked_cell(text, url, context)
        view = context&.view_context
        return text if view.blank? || url.blank?

        view.link_to(text, url)
      end

      def publication_show_path(publication, context)
        recording = RecordingStudioPublications.recording_for(publication)
        publication_url(context, recording) if recording
      end

      def article_show_path(article, context)
        article_recording = RecordingStudioPublications.article_recording_for(article)
        parent = article_recording&.parent_recording
        return if article_recording.blank? || parent.blank?

        with_originating_anchor(
          publication_routes(context).admin_publication_article_path(parent, article_recording),
          context
        )
      end
    end

    PublicationTypeRow = Struct.new(:token, :label, :publications_count, keyword_init: true)
  end
end
