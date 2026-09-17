# frozen_string_literal: true

module RecordingStudioPublications
  class PublicPublicationsController < ActionController::Base
    skip_forgery_protection
    helper RecordingStudioPublishable::Engine.helpers if defined?(RecordingStudioPublishable::Engine)

    def show
      @page = PublishedPublication.build(
        publication: @publication,
        logo_recording: RecordingStudioPublications.logo_recording_for(@publication)
      )
    end
  end
end
