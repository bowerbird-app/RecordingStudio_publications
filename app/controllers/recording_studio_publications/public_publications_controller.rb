# frozen_string_literal: true

module RecordingStudioPublications
  class PublicPublicationsController < ActionController::Base
    skip_forgery_protection

    def show
      @page = PublishedPublication.build(
        publication: @publication,
        logo_recording: RecordingStudioPublications.logo_recording_for(@publication)
      )
    end
  end
end
