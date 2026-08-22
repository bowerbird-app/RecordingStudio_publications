# frozen_string_literal: true

require "recording_studio"
require "recording_studio_publications/version"
require "recording_studio_publications/engine"
require "recording_studio_publications/configuration"
require "recording_studio_publications/capabilities/example"

module RecordingStudioPublications
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
