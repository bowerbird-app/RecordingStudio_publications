# frozen_string_literal: true

module RecordingStudioPublications
  class CatalogueAdminController < ApplicationController
    include RecordingStudioAdmin::AdminActionAuditing if defined?(RecordingStudioAdmin::AdminActionAuditing)

    before_action :authenticate_user!
    before_action :set_current_actor

    helper_method :recording_studio_admin_context, :page_nav_anchor_url, :preserve_anchor_url,
                  :inventory_path, :articles_admin_path, :action_close_url, :hub_url_from_action

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

    def page_nav_anchor_url(default: nil)
      safe_url = RecordingStudioAdmin::UrlSafety.safe_href(params[:anchor_url], allow_external: true)
      return default if safe_url.blank? || safe_url == "#"

      safe_url
    end

    def preserve_anchor_url(url)
      RecordingStudioPublications::Admin.append_anchor_url(url, page_nav_anchor_url)
    end

    def action_close_url(default:)
      page_nav_anchor_url(default: default)
    end

    def hub_url_from_action(url)
      RecordingStudioPublications::Admin.append_anchor_url(url, request.path)
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
      RecordingStudioPublications::Admin.publications_screen_path(recording_studio_admin_context)
    end

    def articles_admin_path(publication = nil)
      RecordingStudioPublications::Admin.articles_screen_path(recording_studio_admin_context, publication: publication)
    end
  end
end
