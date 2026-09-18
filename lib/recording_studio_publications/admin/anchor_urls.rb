# frozen_string_literal: true

module RecordingStudioPublications
  module Admin
    module AnchorUrls
      def with_originating_anchor(url, context)
        append_anchor_url(url, originating_page_for(context))
      end

      def append_anchor_url(url, origin)
        safe_url = RecordingStudioAdmin::UrlSafety.safe_href(url)
        origin = RecordingStudioAdmin::UrlSafety.safe_href(origin, allow_external: true)
        return safe_url if skip_anchor?(safe_url, origin)

        merge_anchor_query(safe_url, origin)
      end

      def originating_page_for(context)
        params = context_params(context)
        explicit = params["anchor_url"]
        return explicit if explicit.present?
        return unless screens_controller?(context&.controller)

        pretty_screen_path(context.controller.params[:key], context)
      end

      private

      def skip_anchor?(safe_url, origin)
        safe_url.blank? || origin.blank? || origin == "#" || !safe_url.start_with?("/")
      end

      def merge_anchor_query(safe_url, origin)
        uri = URI.parse(safe_url)
        query = Rack::Utils.parse_nested_query(uri.query)
        return safe_url if query["anchor_url"].present?

        uri.query = query.merge("anchor_url" => origin).to_query.presence
        uri.to_s
      rescue URI::InvalidURIError
        safe_url
      end

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
    end
  end
end
