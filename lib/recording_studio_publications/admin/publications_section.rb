# frozen_string_literal: true

module RecordingStudioPublications
  module Admin
    class PublicationsSection < RecordingStudioAdmin::Section
      key SECTION_KEY
      icon :newspaper
      title I18n.t("recording_studio_publications.admin.section_title", default: "Publications")
      blast_radius :site

      link :inventory,
           text: I18n.t("recording_studio_publications.admin.inventory_link", default: "Publications"),
           url: ->(context) { RecordingStudioPublications::Admin.publications_screen_path(context) },
           style: :primary
      link :articles,
           text: I18n.t("recording_studio_publications.admin.articles_inventory_link", default: "Articles"),
           url: ->(context) { RecordingStudioPublications::Admin.articles_screen_path(context) },
           style: :secondary
      link :publication_types,
           text: I18n.t("recording_studio_publications.admin.types_inventory_link", default: "Publication types"),
           url: ->(context) { RecordingStudioPublications::Admin.publication_types_screen_path(context) },
           style: :secondary
      # Family Admin only enables Screens whose URLs match admin_screen_path.
      # Pretty /admin/publications does not match, so keep these family paths.
      link :enable_publications_screen,
           text: "Publications inventory",
           url: ->(context) { context.admin_screen_path(SCREEN_KEY) }
      link :enable_articles_screen,
           text: "Articles inventory",
           url: ->(context) { context.admin_screen_path(ARTICLES_SCREEN_KEY) }
      link :enable_publication_types_screen,
           text: "Publication types inventory",
           url: ->(context) { context.admin_screen_path(TYPES_SCREEN_KEY) }

      widget WIDGET_OVER_TIME
      widget WIDGET_ARTICLES_OVER_TIME
    end
  end
end
