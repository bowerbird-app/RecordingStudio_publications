# frozen_string_literal: true

module RecordingStudioPublications
  module FamilyManagement
    PUBLICATION_RECORDABLE_TYPE = "RecordingStudioPublications::Publication"

    module Installed
      @states = {}.compare_by_identity

      class << self
        def remember(config:, authorizer:, close_url:)
          @states[config] = { authorizer: authorizer, close_url: close_url }
        end

        def include?(config)
          @states.key?(config)
        end

        def authorizer_for(config)
          @states.dig(config, :authorizer)
        end

        def close_url_for(config)
          @states.dig(config, :close_url)
        end
      end
    end

    module_function

    def install!(config = default_publishable_config)
      return false if installed?(config)

      Installed.remember(
        config: config,
        authorizer: config.management_authorizer,
        close_url: config.management_close_url_resolver
      )
      wrap_publishable_config(config)
      true
    end

    def authorize(recording:, actor:, controller: nil)
      authorize_with(default_publishable_config, recording: recording, actor: actor, controller: controller)
    end

    def close_url(controller:, recording: nil)
      close_url_with(default_publishable_config, controller: controller, recording: recording)
    end

    def publication_parent(recording)
      current = recording
      while current
        return current if current.recordable_type == PUBLICATION_RECORDABLE_TYPE

        current = current.respond_to?(:parent_recording) ? current.parent_recording : nil
      end
    end

    def installed?(config)
      Installed.include?(config)
    end

    def default_publishable_config
      raise ArgumentError, "recording_studio_publishable is not loaded" unless defined?(RecordingStudioPublishable)

      RecordingStudioPublishable.configuration
    end

    def authorize_with(config, recording:, actor:, controller: nil)
      parent = publication_parent(recording)
      if parent
        FamilyAuthorization.allow?(
          FamilyAuthorization::Request.new(actor: actor, recording: parent, role: :edit)
        )
      else
        invoke(Installed.authorizer_for(config), recording: recording, actor: actor, controller: controller)
      end
    end

    def close_url_with(config, controller:, recording: nil)
      parent = publication_parent(recording)
      if parent
        require "recording_studio_publications/admin" unless defined?(Admin::SCREEN_KEY)
        Admin.publication_url(admin_context(controller), parent)
      else
        invoke(Installed.close_url_for(config), controller: controller, recording: recording)
      end
    end

    def wrap_publishable_config(config)
      config.management_authorizer = lambda { |recording:, actor:, controller: nil, **|
        authorize_with(config, recording: recording, actor: actor, controller: controller)
      }
      config.management_close_url_resolver = lambda { |controller:, recording: nil, **|
        close_url_with(config, controller: controller, recording: recording)
      }
    end

    def invoke(callable, **kwargs)
      return unless callable

      parameters = callable.parameters
      return callable.call(**kwargs) if parameters.any? { |type, _| type == :keyrest }

      supported = parameters.filter_map { |type, name| name if %i[key keyreq].include?(type) }
      callable.call(**kwargs.slice(*supported))
    end

    def admin_context(controller)
      Struct.new(:controller).new(controller)
    end
  end
end
