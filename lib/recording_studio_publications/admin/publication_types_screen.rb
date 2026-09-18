# frozen_string_literal: true

module RecordingStudioPublications
  module Admin
    class PublicationTypesScreen < RecordingStudioAdmin::Screen
      key TYPES_SCREEN_KEY
      icon :tag
      title I18n.t("recording_studio_publications.admin.types_screen_title", default: "Publication types")
      subtitle "How many titles sit in each category"
      blast_radius :site
      query { |_context| RecordingStudioPublications::Admin.publication_type_rows }

      table do
        column :label,
               title: I18n.t("recording_studio_publications.admin.column_type_title", default: "Publication type"),
               sortable: false,
               value: ->(row, _context) { row.label }
        column :publications,
               title: I18n.t("recording_studio_publications.admin.types_count_column", default: "Publications"),
               sortable: false,
               value: lambda { |row, context|
                 RecordingStudioPublications::Admin.publication_type_count_cell(row, context)
               }
        paginate per_page: 25
      end
    end
  end
end
