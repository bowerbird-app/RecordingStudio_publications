# frozen_string_literal: true

require "recording_studio"
require "recording_studio_attachable"
require "recording_studio_publications/version"
require "recording_studio_publications/logo_authorization"
require "recording_studio_publications/engine"
require "recording_studio_publications/configuration"
require "recording_studio_publications/capabilities/example"
require "recording_studio_publications/catalogue"
require "recording_studio_publications/admin"

module RecordingStudioPublications
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def catalogue_recordable
      Catalogue.catalogue_recordable
    end

    def catalogue_root
      Catalogue.catalogue_root
    end

    def publications
      Catalogue.publications
    end

    def recording_for(publication)
      Catalogue.recording_for(publication)
    end

    def logo_recording_for(publication)
      Catalogue.logo_recording_for(publication)
    end

    def record_publication!(...)
      Catalogue.record_publication!(...)
    end

    def revise_publication!(...)
      Catalogue.revise_publication!(...)
    end

    def attach_or_replace_logo!(...)
      Catalogue.attach_or_replace_logo!(...)
    end
  end
end
