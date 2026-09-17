# frozen_string_literal: true

module RecordingStudioPublications
  module FamilyManagement
    # Publishable preview is not the management authorizer. Accessible :view on the
    # title fails for AdminRoot staff, and drafts often have no child yet, so Preview
    # 404s. Family install wraps both.
    module Preview
      module Authorization
        def authorize_preview?(recording:, actor:, controller: nil)
          actor ||= actor_for(controller: controller)
          parent = FamilyManagement.publication_parent(recording)
          return super unless parent

          FamilyAuthorization.allow?(
            FamilyAuthorization::Request.new(actor: actor, recording: parent, role: :view)
          )
        end
      end

      module EnsureChild
        def preview
          ensure_family_preview_child
          super
        end

        private

        def ensure_family_preview_child
          return unless preview_authorized?
          return unless FamilyManagement.publication_parent(@parent_recording)
          return unless defined?(RecordingStudioPublishable::Services::Publishables::EnsureChild)

          RecordingStudioPublishable::Services::Publishables::EnsureChild.call(
            parent_recording: @parent_recording,
            actor: current_publishable_actor
          )
        end
      end

      module_function

      def install!(config)
        wrap_authorization(config)
        wrap_controller
      end

      def wrap_authorization(config)
        return if config.singleton_class.ancestors.include?(Authorization)

        config.singleton_class.prepend(Authorization)
      end

      def wrap_controller
        apply_controller_wrap
        hook_controller_reload
      end

      def apply_controller_wrap
        return unless defined?(RecordingStudioPublishable)

        klass = RecordingStudioPublishable.const_get(:PublishablesController)
        return unless klass.is_a?(Class)
        return if klass.ancestors.include?(EnsureChild)

        klass.prepend(EnsureChild)
      rescue NameError
        nil
      end

      def hook_controller_reload
        return if @controller_reload_hooked

        @controller_reload_hooked = true
        reapply = -> { RecordingStudioPublications::FamilyManagement::Preview.apply_controller_wrap }
        if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
          Rails.application.config.to_prepare(&reapply)
        elsif defined?(ActiveSupport::Reloader)
          ActiveSupport::Reloader.to_prepare(&reapply)
        end
      end
    end
  end
end
