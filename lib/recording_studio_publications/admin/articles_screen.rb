# frozen_string_literal: true

module RecordingStudioPublications
  module Admin
    class ArticlesScreen < RecordingStudioAdmin::Screen
      key ARTICLES_SCREEN_KEY
      icon :newspaper
      title I18n.t("recording_studio_publications.admin.articles_screen_title", default: "Articles")
      subtitle "Articles published by titles in the directory"
      blast_radius :site
      query { |_context| RecordingStudioPublications.articles }
      filter :publication,
             values: -> { RecordingStudioPublications::Admin.publication_filter_values },
             apply: lambda { |relation, value, _context|
               RecordingStudioPublications::Admin.apply_article_publication_filter(relation, value)
             }

      table do
        column :title,
               title: "Title",
               value: lambda { |article, context|
                 RecordingStudioPublications::Admin.article_title_cell(article, context)
               }
        column :publication,
               title: "Publication",
               sortable: false,
               value: lambda { |article, context|
                 RecordingStudioPublications::Admin.article_publication_cell(article, context)
               }
        column :published_on, title: "Published"
        column :byline, title: "Author"
        paginate per_page: 25
        default_sort :published_on, direction: :desc
      end
    end
  end
end
