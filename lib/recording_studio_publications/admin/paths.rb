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

      def with_originating_anchor(url, context)
        append_anchor_url(url, originating_page_for(context))
      end

      def append_anchor_url(url, origin)
        safe_url = RecordingStudioAdmin::UrlSafety.safe_href(url)
        origin = RecordingStudioAdmin::UrlSafety.safe_href(origin, allow_external: true)
        return safe_url if safe_url.blank? || origin.blank? || origin == "#"
        return safe_url unless safe_url.start_with?("/")

        uri = URI.parse(safe_url)
        query = Rack::Utils.parse_nested_query(uri.query)
        return safe_url if query["anchor_url"].present?

        uri.query = query.merge("anchor_url" => origin).to_query.presence
        uri.to_s
      rescue URI::InvalidURIError
        safe_url
      end

      def originating_page_for(context)
        params = context_params(context)
        explicit = params["anchor_url"]
        return explicit if explicit.present?
        return unless screens_controller?(context&.controller)

        pretty_screen_path(context.controller.params[:key], context)
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

      def context_params(context)
        raw = context&.params
        return {} if raw.blank?

        hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
        hash.stringify_keys
      end

      def screens_controller?(controller)
        defined?(RecordingStudioAdmin::ScreensController) &&
          controller.is_a?(RecordingStudioAdmin::ScreensController)
      end

      def pretty_screen_path(key, context)
        case key.to_s
        when SCREEN_KEY then publications_screen_path(context)
        when ARTICLES_SCREEN_KEY then articles_screen_path(context)
        when TYPES_SCREEN_KEY then publication_types_screen_path(context)
        else
          context&.admin_screen_path(key)
        end
      end

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
