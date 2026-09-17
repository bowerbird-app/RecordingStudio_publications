# frozen_string_literal: true

module RecordingStudioPublications
  class Engine < ::Rails::Engine # rubocop:disable Metrics/ClassLength -- Rails engine hooks
    isolate_namespace RecordingStudioPublications

    class << self
      def apply_model_extensions(target)
        apply_extensions(target, extensions_for(:model, extension_keys_for(target)))
      end

      def apply_controller_extensions(target)
        apply_extensions(target, extensions_for(:controller, extension_keys_for(target)))
      end

      private

      def extensions_for(kind, names)
        hooks = RecordingStudioPublications.configuration.hooks
        Array(names).flat_map do |name|
          if kind == :model
            hooks.model_extensions_for(name)
          else
            hooks.controller_extensions_for(name)
          end
        end
      end

      def apply_extensions(target, extensions)
        return unless target

        applied = target.instance_variable_get(:@recording_studio_publications_applied_extensions) || identity_hash

        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        target.instance_variable_set(:@recording_studio_publications_applied_extensions, applied)
      end

      def extension_keys_for(target)
        names = [target.name, target.name&.demodulize].compact.uniq
        names.map(&:to_sym)
      end

      def identity_hash
        {}.compare_by_identity
      end
    end

    # Run before_initialize hooks
    initializer "recording_studio_publications.before_initialize",
                before: "recording_studio_publications.load_config" do |_app|
      RecordingStudioPublications.configuration.hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_publications.load_config" do |app|
      # Load config/recording_studio_publications.yml via Rails config_for if present
      if app.respond_to?(:config_for)
        begin
          yaml = begin
            app.config_for(:recording_studio_publications)
          rescue StandardError
            nil
          end
          RecordingStudioPublications.configuration.merge!(yaml) if yaml.respond_to?(:each)
        rescue StandardError => _e
          # ignore load errors; host app can provide initializer overrides
        end
      end

      # Merge Rails.application.config.x.recording_studio_publications if present
      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_publications)
        xcfg = app.config.x.recording_studio_publications
        if xcfg.respond_to?(:to_h)
          RecordingStudioPublications.configuration.merge!(xcfg.to_h)
        else
          begin
            # try converting OrderedOptions
            hash = {}
            xcfg.each_pair { |k, v| hash[k] = v } if xcfg.respond_to?(:each_pair)
            RecordingStudioPublications.configuration.merge!(hash) if hash&.any?
          rescue StandardError => _e
            # ignore
          end
        end
      end

      # Run on_configuration hooks after config is loaded
      RecordingStudioPublications.configuration.hooks.run(:on_configuration, RecordingStudioPublications.configuration)
    end

    # Run after_initialize hooks
    initializer "recording_studio_publications.after_initialize",
                after: "recording_studio_publications.load_config" do |_app|
      RecordingStudioPublications.configuration.hooks.run(:after_initialize, self)
    end

    # Apply model extensions when models are loaded
    initializer "recording_studio_publications.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioPublications::Engine.apply_model_extensions(model)
        end
      end
    end

    # Apply controller extensions
    initializer "recording_studio_publications.apply_controller_extensions" do
      config.to_prepare do
        next unless defined?(ActionController::Base)

        ActionController::Base.descendants.each do |controller|
          RecordingStudioPublications::Engine.apply_controller_extensions(controller)
        end
      end
    end

    initializer "recording_studio_publications.family_engines", before: :load_config_initializers do
      require "recording_studio_attachable" if defined?(Bundler) || defined?(RecordingStudioAttachable)
      require "recording_studio_admin" if defined?(Bundler) || defined?(RecordingStudioAdmin)
      require "recording_studio_publishable" if defined?(Bundler) || defined?(RecordingStudioPublishable)
    rescue LoadError
      # Hosts that have not bundled family engines yet still boot this engine.
    end

    initializer "recording_studio_publications.admin_definitions" do
      config.to_prepare do
        next unless defined?(RecordingStudioAdmin)

        require "recording_studio_publications/admin"
        RecordingStudioPublications::Admin.register!
      end
    end

    initializer "recording_studio_publications.admin_view_paths" do
      config.to_prepare do
        next unless defined?(ActionController::Base)
        next unless defined?(RecordingStudioAdmin::Engine)

        ActionController::Base.prepend_view_path(
          RecordingStudioPublications::Engine.root.join("app/overrides")
        )
        ActionController::Base.append_view_path(RecordingStudioAdmin::Engine.root.join("app/views"))
      end
    end
  end
end
