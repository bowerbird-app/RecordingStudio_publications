# frozen_string_literal: true

module RecordingStudioPublications
  module Admin
    class PublicationsScreen < RecordingStudioAdmin::Screen
      key SCREEN_KEY
      icon :newspaper
      title I18n.t("recording_studio_publications.admin.screen_title", default: "Publications")
      subtitle "Titles in the publication directory"
      blast_radius :site
      query { |_context| RecordingStudioPublications.publications }
      filter :search, apply: lambda { |relation, value, _context|
        RecordingStudioPublications::Admin.apply_publication_search(relation, value)
      }
      button :new_publication,
             text: I18n.t("recording_studio_publications.admin.new_link", default: "Publication"),
             url: ->(context) { RecordingStudioPublications::Admin.new_publication_url(context) },
             style: :primary

      table do
        column :name,
               title: "Name",
               value: lambda { |publication, context|
                 RecordingStudioPublications::Admin.publication_name_cell(publication, context)
               }
        column :kind,
               title: I18n.t("recording_studio_publications.admin.column_type_title", default: "Publication type"),
               value: ->(publication, _context) { publication.kind_label }
        column :website, title: "Website"
        column :articles,
               title: "Articles",
               sortable: false,
               value: lambda { |publication, context|
                 RecordingStudioPublications::Admin.article_count_cell(publication, context)
               }
        admin_action "#{RESOURCE_KEY}.show", as: :show_publication
        admin_action "#{RESOURCE_KEY}.edit", as: :edit_publication
        paginate per_page: 25
        default_sort :name, direction: :asc
      end
      chart do
        title "Titles over time"
        type :area
        series { |_context| RecordingStudioPublications::Admin.titles_over_time_series }
      end
    end
  end
end
