# frozen_string_literal: true

module RecordingStudioPublications
  class PublishedArticlesController < CatalogueAdminController
    before_action :set_publication
    before_action :set_article, only: %i[show edit update]
    before_action :authorize_current_publication!

    def index
      @articles_index = RecordingStudioPublications::PublishedArticles::IndexQuery.new(publication: @publication, params: params)
      @article_entries = @articles_index.entries
      @new_article_action = resolve_publications_admin_action(:edit, @publication)
    end

    def show
      @edit_article_action = resolve_publications_admin_action(:edit, @publication)
      @screenshot_recording = RecordingStudioPublications.screenshot_recording_for(@recording)
    end

    def new
      @article = PublishedArticle.new
    end

    def create
      recording = persist_new_article!
      return render_new_invalid unless recording

      redirect_to admin_publication_article_path(@publication_recording, recording)
    rescue ActiveRecord::RecordInvalid => e
      @article = e.record
      render :new, status: :unprocessable_entity
    end

    def edit
      @screenshot_recording = RecordingStudioPublications.screenshot_recording_for(@recording)
    end

    def update
      recording = persist_revised_article!
      return render :edit, status: :unprocessable_entity unless recording

      redirect_to admin_publication_article_path(@publication_recording, recording)
    rescue ActiveRecord::RecordInvalid => e
      @article = e.record
      @recording = RecordingStudioPublications.article_recording_for(@article) || @recording
      render :edit, status: :unprocessable_entity
    end

    private

    def set_publication
      @publication_recording = RecordingStudio::Recording.find(params[:publication_id])
      unless @publication_recording.recordable_type == Publication.name && @publication_recording.trashed_at.blank?
        raise ActiveRecord::RecordNotFound
      end

      @publication = @publication_recording.recordable
    end

    def set_article
      @recording = RecordingStudio::Recording.find(params[:id])
      unless article_belongs_to_publication?
        raise ActiveRecord::RecordNotFound
      end

      @article = @recording.recordable
    end

    def article_belongs_to_publication?
      @recording.recordable_type == PublishedArticle.name &&
        @recording.trashed_at.blank? &&
        @recording.parent_recording_id == @publication_recording.id
    end

    def authorize_current_publication!
      authorize_publications_record!(@publication)
    rescue RecordingStudioAdmin::AuthorizationFailed, RecordingStudioAdmin::DefinitionNotFound
      head :forbidden
    end

    def persist_new_article!
      perform_recording_studio_admin_action!(
        RecordingStudioPublications::Admin::RESOURCE_KEY,
        :edit,
        @publication,
        audit_action: :create
      ) { write_article! }
    end

    def persist_revised_article!
      perform_recording_studio_admin_action!(
        RecordingStudioPublications::Admin::RESOURCE_KEY,
        :edit,
        @publication,
        audit_action: :update
      ) { RecordingStudioPublications.revise_article!(@article, article_params, actor: current_user) }
    end

    def render_new_invalid
      @article ||= PublishedArticle.new(article_params)
      render :new, status: :unprocessable_entity
    end

    def write_article!
      RecordingStudioPublications.record_article!(@publication, article_params, actor: current_user)
    end

    def article_params
      params.fetch(:article, {}).permit(:title, :url, :canonical_url, :published_on, :byline, :excerpt)
    end

    def publications_resource_action
      case action_name
      when "index", "show" then :show
      when "new", "create", "edit", "update" then :edit
      else action_name
      end
    end
  end
end
