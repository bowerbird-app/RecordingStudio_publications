# frozen_string_literal: true

module RecordingStudioPublications
  module Admin
    module Paths
      def publications_screen_path(context = nil)
        "#{admin_mount_path(context)}/publications"
      end

      def articles_screen_path(context = nil, publication: nil)
        path = "#{admin_mount_path(context)}/articles"
        key = publication_filter_key(publication)
        return path if key.blank?

        "#{path}?#{{ publication: key }.to_query}"
      end

      def publication_types_screen_path(context = nil)
        "#{admin_mount_path(context)}/publication_types"
      end

      def new_publication_url(context = nil)
        with_originating_anchor(publication_routes(context).new_admin_publication_path, context)
      end

      def publication_url(context, recording)
        with_originating_anchor(publication_routes(context).admin_publication_path(recording), context)
      end

      def edit_publication_url(context, recording)
        with_originating_anchor(publication_routes(context).edit_admin_publication_path(recording), context)
      end

      def publication_routes(context)
        routes = context&.controller.respond_to?(:recording_studio_publications) ? context.controller : nil
        return routes.recording_studio_publications if routes

        main_app = context&.controller.respond_to?(:main_app) ? context.controller.main_app : nil
        return main_app.recording_studio_publications if main_app.respond_to?(:recording_studio_publications)

        RecordingStudioPublications::Engine.routes.url_helpers
      end

      def admin_mount_path(context)
        screen_path = context&.admin_screen_path(SCREEN_KEY).to_s
        return screen_path.split("/screens/").first if screen_path.include?("/screens/")

        RecordingStudioAdmin.configuration.default_mount_path
      end

      def draw_pretty_admin_routes!
        return unless defined?(RecordingStudioAdmin::Engine)

        draw_pretty_admin_route!("publications", "publications")
        draw_pretty_admin_route!("articles", "articles")
        draw_pretty_admin_route!("publication_types", "publication_types")
      end

      private

      def draw_pretty_admin_route!(path, screen_key)
        return if pretty_admin_route_drawn?(path)

        RecordingStudioAdmin::Engine.routes.append do
          get path, to: "screens#show", defaults: { key: screen_key }
        end
      end

      def pretty_admin_route_drawn?(path)
        RecordingStudioAdmin::Engine.routes.routes.any? do |route|
          spec = route.path.spec.to_s.split("(").first
          spec == "/#{path}" && route.defaults[:controller].to_s.end_with?("screens")
        end
      end

      def publication_filter_key(publication)
        return if publication.blank?
        return publication if publication.is_a?(String)

        publication.key
      end
    end
  end
end
