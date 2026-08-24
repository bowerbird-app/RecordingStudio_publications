# frozen_string_literal: true

module RecordingStudioPublications
  # Attachable asks Accessible for :edit on the Publication recording.
  # Family admin writes through AdminRoot, not per-publication grants, so
  # catalogue staff can attach a logo without a magazine grant.
  module LogoAuthorization
    module_function

    def call(action:, actor:, recording:, role:) # rubocop:disable Lint/UnusedMethodArgument -- Attachable contract
      return false if actor.blank?
      return true if admin_catalogue_actor?(actor, role)
      return false unless defined?(RecordingStudioAccessible::Authorization)

      RecordingStudioAccessible::Authorization.allowed?(actor: actor, recording: recording, role: role)
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
