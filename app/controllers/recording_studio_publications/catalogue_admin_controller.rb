# frozen_string_literal: true

module RecordingStudioPublications
  class CatalogueAdminController < ApplicationController
    include RecordingStudioAdmin::AdminActionAuditing if defined?(RecordingStudioAdmin::AdminActionAuditing)

    before_action :authenticate_user!
    before_action :set_current_actor

    helper_method :recording_studio_admin_context, :page_nav_anchor_url, :preserve_anchor_url,
                  :inventory_path, :publication_logo_url

    private

    def set_current_actor
      return unless defined?(Current) && Current.respond_to?(:actor=)

      Current.actor = current_user
    end

    def recording_studio_admin_context
      @recording_studio_admin_context ||= RecordingStudioAdmin::Context.new(
        params: params.to_unsafe_h,
        current_actor: current_user,
        controller: self,
        routes: (respond_to?(:main_app) ? main_app : self),
        view_context: view_context
      )
    end

    def page_nav_anchor_url(default: RecordingStudioAdmin.configuration.default_mount_path)
      safe_url = RecordingStudioAdmin::UrlSafety.safe_href(params[:anchor_url], allow_external: true)
      return default if safe_url.blank? || safe_url == "#"

      safe_url
    end

    def preserve_anchor_url(url)
      safe_url = RecordingStudioAdmin::UrlSafety.safe_href(url)
      anchor_url = page_nav_anchor_url

      return safe_url if safe_url.blank? || anchor_url.blank? || anchor_url == "#"
      return safe_url unless safe_url.start_with?("/")

      uri = URI.parse(safe_url)
      query = Rack::Utils.parse_nested_query(uri.query)
      uri.query = query.reverse_merge("anchor_url" => anchor_url).to_query.presence
      uri.to_s
    rescue URI::InvalidURIError
      safe_url
    end

    def authorize_publications_admin_action!(record = nil)
      if action_name == "index"
        authorize_publications_index!
      else
        authorize_publications_record!(record)
      end
    rescue RecordingStudioAdmin::AuthorizationFailed, RecordingStudioAdmin::DefinitionNotFound
      head :forbidden
    end

    def authorize_publications_index!
      # Index is a collection redirect. Resource :show has a per-row
      # visible_if, so skip record visibility and authorize the section.
      RecordingStudioAdmin.resolve_table_resource_action(
        key: RecordingStudioPublications::Admin::RESOURCE_KEY,
        context: recording_studio_admin_context,
        action: :show
      )
    end

    def authorize_publications_record!(record)
      RecordingStudioAdmin.authorize_resource!(
        key: RecordingStudioPublications::Admin::RESOURCE_KEY,
        action: publications_resource_action,
        context: recording_studio_admin_context,
        record: record,
        audit: true,
        audit_action: action_name
      )
    end

    def publications_resource_action
      case action_name
      when "create" then :new
      when "update" then :edit
      when "index" then :show
      else action_name
      end
    end

    def publication_logo_url(logo_recording)
      file = logo_recording&.recordable&.file
      return unless file&.attached?

      Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
    end

    def resolve_publications_admin_action(action, record)
      RecordingStudioAdmin.authorize_resource!(
        key: RecordingStudioPublications::Admin::RESOURCE_KEY,
        action: action,
        context: recording_studio_admin_context,
        record: record
      ).resolve(record, recording_studio_admin_context)
    rescue RecordingStudioAdmin::AuthorizationFailed, RecordingStudioAdmin::DefinitionNotFound
      nil
    end

    def inventory_path
      recording_studio_admin_context.admin_screen_path(RecordingStudioPublications::Admin::SCREEN_KEY)
    end
  end
end
