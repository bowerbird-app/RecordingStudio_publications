# frozen_string_literal: true

module RecordingStudioPublications
  module Admin
    class PublicationsController < BaseController
      before_action :set_publication, only: %i[show edit update]
      before_action :authorize_current_publication!

      def index
        redirect_to inventory_path
      end

      def show
        @edit_publication_action = resolve_publications_admin_action(:edit, @publication)
        @logo_recording = RecordingStudioPublications.logo_recording_for(@recording)
      end

      def new
        @publication = Publication.new
      end

      def create
        recording = perform_recording_studio_admin_action!(
          RecordingStudioPublications::Admin::RESOURCE_KEY,
          :create,
          nil,
          audit_action: :create
        ) do
          write_publication!
        end

        if recording
          attach_uploaded_logo!(recording.recordable)
          redirect_to admin_publication_path(recording)
        else
          @publication ||= Publication.new(publication_params)
          render :new, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordInvalid => e
        @publication = e.record
        render :new, status: :unprocessable_entity
      end

      def edit
        @logo_recording = RecordingStudioPublications.logo_recording_for(@recording)
      end

      def update
        recording = perform_recording_studio_admin_action!(
          RecordingStudioPublications::Admin::RESOURCE_KEY,
          :update,
          @publication,
          audit_action: :update
        ) do
          RecordingStudioPublications.revise_publication!(@publication, publication_params, actor: current_user)
        end

        if recording
          attach_uploaded_logo!(recording.recordable)
          redirect_to admin_publication_path(recording)
        else
          render :edit, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordInvalid => e
        @publication = e.record
        @recording = RecordingStudioPublications.recording_for(@publication) || @recording
        render :edit, status: :unprocessable_entity
      end

      private

      def set_publication
        @recording = RecordingStudio::Recording.find(params[:id])
        unless @recording.recordable_type == Publication.name && @recording.trashed_at.blank?
          raise ActiveRecord::RecordNotFound
        end

        @publication = @recording.recordable
      end

      def authorize_current_publication!
        authorize_publications_admin_action!(@publication)
      end

      def write_publication!
        RecordingStudioPublications.record_publication!(publication_params, actor: current_user)
      end

      def attach_uploaded_logo!(publication)
        upload = params.dig(:publication, :logo)
        return if upload.blank?

        RecordingStudioPublications.attach_or_replace_logo!(
          publication,
          io: upload.tempfile,
          filename: upload.original_filename,
          content_type: upload.content_type,
          actor: current_user
        )
      end

      def publication_params
        params.fetch(:publication, {}).permit(:name, :key, :kind, :website)
      end
    end
  end
end
