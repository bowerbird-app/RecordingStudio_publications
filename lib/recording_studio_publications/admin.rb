# frozen_string_literal: true

require "recording_studio_admin"

module RecordingStudioPublications
  module Admin
    SCREEN_KEY = "publications"
    SECTION_KEY = "publications"
    RESOURCE_KEY = "publications"
    WIDGET_TOTAL = "widgets.publications.total"

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
    end

    class PublicationsScreen < RecordingStudioAdmin::Screen
      key SCREEN_KEY
      icon :newspaper
      title "Publications"
      subtitle "Titles in the publication directory"
      blast_radius :site
      query { |_context| RecordingStudioPublications.publications }

      table do
        column :name, title: "Name"
        column :key, title: "Key"
        column :kind,
               title: "Kind",
               value: ->(publication, _context) { publication.kind_label }
        column :website, title: "Website"
        admin_action "#{RESOURCE_KEY}.show", as: :show_publication
        admin_action "#{RESOURCE_KEY}.edit", as: :edit_publication
        paginate per_page: 25
      end
      widget WIDGET_TOTAL
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

      action :create,
             text: "Create",
             method: :post,
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

      action :update,
             text: "Save",
             method: :patch,
             required_role: :admin
    end

    TotalPublicationsWidget = RecordingStudioAdmin::Widget.new(WIDGET_TOTAL, blast_radius: :site) do
      type :number
      title "Publications"
      value { |_context| RecordingStudioPublications.publications.count }
      link_to { |context| context.admin_screen_path(SCREEN_KEY) }
      hide_change
      hide_period
    end

    class << self
      def register!
        return unless defined?(::RecordingStudioAdmin)

        RecordingStudioAdmin.register_section(PublicationsSection)
        RecordingStudioAdmin.register_screen(PublicationsScreen)
        RecordingStudioAdmin.register_resource(PublicationsResource)
        RecordingStudioAdmin.register_widget(TotalPublicationsWidget)
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
