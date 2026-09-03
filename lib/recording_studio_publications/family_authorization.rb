# frozen_string_literal: true

module RecordingStudioPublications
  module FamilyAuthorization
    Request = Data.define(:actor, :recording, :role)

    module_function

    # Attachable authorize_with plus ignored extra keywords from other mixins.
    def call(action:, actor:, recording:, role: :edit, **)
      _ = action
      allow?(Request.new(actor: actor, recording: recording, role: role))
    end

    def allow?(request)
      return false if request.actor.blank?
      return true if admin_catalogue_actor?(request.actor, request.role)
      return false unless defined?(RecordingStudioAccessible::Authorization)

      RecordingStudioAccessible::Authorization.allowed?(
        actor: request.actor,
        recording: request.recording,
        role: request.role
      )
    end

    def admin_catalogue_actor?(actor, role)
      return false unless defined?(RecordingStudioAdmin)
      return false unless defined?(RecordingStudioAccessible)

      admin_recording = admin_access_recording
      return false if admin_recording.blank?

      RecordingStudioAccessible.authorized?(actor: actor, recording: admin_recording, role: role)
    end

    def admin_access_recording
      resolver = RecordingStudioAdmin.configuration.access_recording_resolver
      return unless resolver.respond_to?(:call)

      resolver.call(nil)
    rescue StandardError
      nil
    end
  end
end
