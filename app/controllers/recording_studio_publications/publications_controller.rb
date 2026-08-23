# frozen_string_literal: true

module RecordingStudioPublications
  class PublicationsController < CatalogueAdminController
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
      recording = persist_new_publication!
      return render_new_invalid unless recording

      redirect_to admin_publication_path(recording)
    rescue ActiveRecord::RecordInvalid => e
      @publication = e.record
      render :new, status: :unprocessable_entity
    end

    def edit
      @logo_recording = RecordingStudioPublications.logo_recording_for(@recording)
    end

    def update
      recording = persist_revised_publication!
      return render :edit, status: :unprocessable_entity unless recording

      redirect_to admin_publication_path(recording)
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

    def persist_new_publication!
      perform_recording_studio_admin_action!(
        RecordingStudioPublications::Admin::RESOURCE_KEY,
        :new,
        nil,
        audit_action: :create
      ) { write_publication! }
    end

    def persist_revised_publication!
      perform_recording_studio_admin_action!(
        RecordingStudioPublications::Admin::RESOURCE_KEY,
        :edit,
        @publication,
        audit_action: :update
      ) { RecordingStudioPublications.revise_publication!(@publication, publication_params, actor: current_user) }
    end

    def render_new_invalid
      @publication ||= Publication.new(publication_params)
      render :new, status: :unprocessable_entity
    end

    def write_publication!
      RecordingStudioPublications.record_publication!(publication_params, actor: current_user)
    end

    def publication_params
      params.fetch(:publication, {}).permit(:name, :key, :kind, :website)
    end
  end
end
