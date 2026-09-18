# frozen_string_literal: true

require "recording_studio_admin"

module RecordingStudioPublications
  module Admin
    SCREEN_KEY = "publications"
    ARTICLES_SCREEN_KEY = "articles"
    SECTION_KEY = "publications"
    RESOURCE_KEY = "publications"
    WIDGET_TOTAL = "widgets.publications.total"
    WIDGET_ARTICLES_TOTAL = "widgets.articles.total"
    WIDGET_OVER_TIME = "widgets.publications.over_time"
    WIDGET_ARTICLES_OVER_TIME = "widgets.articles.over_time"
    WIDGET_BY_KIND = "widgets.publications.by_kind"
  end
end

require_relative "admin/paths"
require_relative "admin/support"
require_relative "admin/publications_section"
require_relative "admin/publications_screen"
require_relative "admin/articles_screen"
require_relative "admin/publications_resource"

module RecordingStudioPublications
  module Admin
    extend Paths
    extend Support

    TotalPublicationsWidget = RecordingStudioAdmin::Widget.new(WIDGET_TOTAL, blast_radius: :site) do
      type :number
      title I18n.t("recording_studio_publications.admin.total_widget_title", default: "Publications")
      value { |_context| RecordingStudioPublications.publications.count }
      link_to { |context| RecordingStudioPublications::Admin.publications_screen_path(context) }
      hide_change
      hide_period
    end

    TotalArticlesWidget = RecordingStudioAdmin::Widget.new(WIDGET_ARTICLES_TOTAL, blast_radius: :site) do
      type :number
      title I18n.t("recording_studio_publications.admin.articles_total_widget_title", default: "Articles")
      value { |_context| RecordingStudioPublications.articles.count }
      link_to { |context| RecordingStudioPublications::Admin.articles_screen_path(context) }
      hide_change
      hide_period
    end

    TitlesOverTimeWidget = RecordingStudioAdmin::Widget.new(WIDGET_OVER_TIME, blast_radius: :site) do
      type :chart
      title I18n.t("recording_studio_publications.admin.over_time_widget_title", default: "Publications over time")
      chart_type :line
      hide_change
      hide_period
      hide_metric
      series { |_context| RecordingStudioPublications::Admin.titles_over_time_series }
      chart_options { { height: 220 } }
      link_to { |context| RecordingStudioPublications::Admin.publications_screen_path(context) }
    end

    ArticlesOverTimeWidget = RecordingStudioAdmin::Widget.new(WIDGET_ARTICLES_OVER_TIME, blast_radius: :site) do
      type :chart
      title I18n.t("recording_studio_publications.admin.articles_over_time_widget_title", default: "Articles over time")
      chart_type :line
      hide_change
      hide_period
      hide_metric
      series { |_context| RecordingStudioPublications::Admin.articles_over_time_series }
      chart_options { { height: 220 } }
      link_to { |context| RecordingStudioPublications::Admin.articles_screen_path(context) }
    end

    TitlesByKindWidget = RecordingStudioAdmin::Widget.new(WIDGET_BY_KIND, blast_radius: :site) do
      type :chart
      title I18n.t("recording_studio_publications.admin.by_type_widget_title", default: "Publication types")
      chart_type :bar
      hide_change
      hide_period
      hide_metric
      series { |_context| RecordingStudioPublications::Admin.titles_by_kind_series }
      chart_options { { height: 220 } }
    end

    def self.register!
      return unless defined?(::RecordingStudioAdmin)

      RecordingStudioAdmin.register_section(PublicationsSection)
      RecordingStudioAdmin.register_screen(PublicationsScreen)
      RecordingStudioAdmin.register_screen(ArticlesScreen)
      RecordingStudioAdmin.register_resource(PublicationsResource)
      RecordingStudioAdmin.register_widget(TotalPublicationsWidget)
      RecordingStudioAdmin.register_widget(TotalArticlesWidget)
      RecordingStudioAdmin.register_widget(TitlesOverTimeWidget)
      RecordingStudioAdmin.register_widget(ArticlesOverTimeWidget)
      RecordingStudioAdmin.register_widget(TitlesByKindWidget)
    end
  end
end
