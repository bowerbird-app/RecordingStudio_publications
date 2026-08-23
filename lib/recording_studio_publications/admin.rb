# frozen_string_literal: true

require "recording_studio_admin"

module RecordingStudioPublications
  module Admin
    SCREEN_KEY = "publications"
    SECTION_KEY = "publications"
    RESOURCE_KEY = "publications"
    WIDGET_TOTAL = "widgets.publications.total"
    WIDGET_BY_KIND = "widgets.publications.by_kind"
    WIDGET_OVER_TIME = "widgets.publications.over_time"

    class PublicationsSection < RecordingStudioAdmin::Section
      key SECTION_KEY
      icon :newspaper
      title "Publications"
      subtitle "Titles in the publication directory"
      blast_radius :site

      link :new_publication,
           text: "New",
           url: ->(context) { RecordingStudioPublications::Admin.new_publication_url(context) },
           style: :primary
      link :inventory,
           text: "All publications",
           url: ->(context) { context.admin_screen_path(SCREEN_KEY) },
           style: :secondary
      widget WIDGET_TOTAL, view_variant: :compact
      widget WIDGET_BY_KIND
    end

    class PublicationsScreen < RecordingStudioAdmin::Screen
      key SCREEN_KEY
      icon :newspaper
      title "Publications"
      subtitle "Titles in the publication directory"
      blast_radius :site
      query { |_context| RecordingStudioPublications.publications }
      filter :search, apply: lambda { |relation, value, _context|
        RecordingStudioPublications::Admin.apply_publication_search(relation, value)
      }
      button :new_publication,
             text: "New",
             url: ->(context) { RecordingStudioPublications::Admin.new_publication_url(context) },
             style: :primary

      table do
        column :name, title: "Name"
        column :kind,
               title: "Kind",
               value: ->(publication, _context) { publication.kind_label }
        column :website, title: "Website"
        admin_action "#{RESOURCE_KEY}.show", as: :show_publication
        admin_action "#{RESOURCE_KEY}.edit", as: :edit_publication
        paginate per_page: 25
      end
      widget WIDGET_OVER_TIME
      chart do
        title "Titles over time"
        type :area
        series { |_context| RecordingStudioPublications::Admin.titles_over_time_series }
      end
    end

    class PublicationsResource < RecordingStudioAdmin::Resource
      key RESOURCE_KEY
      section SECTION_KEY
      icon :newspaper
      title "Manage publications"
      subtitle "Add and edit titles in the directory"
      blast_radius :site

      action :show,
             text: "Show",
             icon: "eye",
             url: lambda { |row, context|
               recording = RecordingStudioPublications.recording_for(row)
               RecordingStudioPublications::Admin.publication_url(context, recording) if recording
             },
             visible_if: ->(row, _context) { RecordingStudioPublications.recording_for(row).present? }

      action :new,
             text: "New",
             icon: "plus",
             url: ->(_row, context) { RecordingStudioPublications::Admin.new_publication_url(context) },
             required_role: :admin

      action :edit,
             text: "Edit",
             icon: "pencil-square",
             url: lambda { |row, context|
               recording = RecordingStudioPublications.recording_for(row)
               RecordingStudioPublications::Admin.edit_publication_url(context, recording) if recording
             },
             required_role: :admin,
             visible_if: ->(row, _context) { RecordingStudioPublications.recording_for(row).present? }
    end

    TotalPublicationsWidget = RecordingStudioAdmin::Widget.new(WIDGET_TOTAL, blast_radius: :site) do
      type :number
      title "Publications"
      value { |_context| RecordingStudioPublications.publications.count }
      link_to { |context| context.admin_screen_path(SCREEN_KEY) }
      hide_change
      hide_period
    end

    TitlesByKindWidget = RecordingStudioAdmin::Widget.new(WIDGET_BY_KIND, blast_radius: :site) do
      type :chart
      title "Titles by kind"
      chart_type :bar
      hide_change
      hide_period
      hide_metric
      series { |_context| RecordingStudioPublications::Admin.titles_by_kind_series }
      chart_options { { height: 220 } }
    end

    TitlesOverTimeWidget = RecordingStudioAdmin::Widget.new(WIDGET_OVER_TIME, blast_radius: :site) do
      type :chart
      title "Titles over time"
      chart_type :area
      hide_change
      hide_period
      hide_metric
      series { |_context| RecordingStudioPublications::Admin.titles_over_time_series }
      chart_options { { height: 220 } }
    end

    class << self
      def register!
        return unless defined?(::RecordingStudioAdmin)

        RecordingStudioAdmin.register_section(PublicationsSection)
        RecordingStudioAdmin.register_screen(PublicationsScreen)
        RecordingStudioAdmin.register_resource(PublicationsResource)
        RecordingStudioAdmin.register_widget(TotalPublicationsWidget)
        RecordingStudioAdmin.register_widget(TitlesByKindWidget)
        RecordingStudioAdmin.register_widget(TitlesOverTimeWidget)
      end

      def apply_publication_search(relation, value)
        return relation if value.blank?

        pattern = safe_like(value)
        relation.where(
          "name ILIKE :q OR key ILIKE :q OR kind ILIKE :q OR COALESCE(website, '') ILIKE :q",
          q: pattern
        )
      end

      def titles_by_kind_series
        counts = RecordingStudioPublications.publications.reorder(nil).group(:kind).count

        [{
          name: "Titles",
          data: Publication::KINDS.map { |kind| { x: kind.titleize, y: counts[kind].to_i } }
        }]
      end

      def titles_over_time_series
        [{ name: "Titles", data: cumulative_weekly_title_counts }]
      end

      def cumulative_weekly_title_counts
        running = 0

        weekly_title_counts.map do |point|
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

      def safe_like(value)
        "%#{ActiveRecord::Base.sanitize_sql_like(value.to_s)}%"
      end

      def new_publication_url(context = nil)
        publication_routes(context).new_admin_publication_path
      end

      def publication_url(context, recording)
        publication_routes(context).admin_publication_path(recording)
      end

      def edit_publication_url(context, recording)
        publication_routes(context).edit_admin_publication_path(recording)
      end

      def publication_routes(context)
        routes = context&.controller.respond_to?(:recording_studio_publications) ? context.controller : nil
        return routes.recording_studio_publications if routes

        main_app = context&.controller.respond_to?(:main_app) ? context.controller.main_app : nil
        return main_app.recording_studio_publications if main_app.respond_to?(:recording_studio_publications)

        RecordingStudioPublications::Engine.routes.url_helpers
      end
    end
  end
end
