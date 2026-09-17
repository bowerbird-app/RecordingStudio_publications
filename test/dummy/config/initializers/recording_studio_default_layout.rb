# frozen_string_literal: true

# Gem clear-action screens (title new/show/edit, core Recording Studio pages)
# use the shared default layout. Dummy home and docs keep the host sidebar.
Rails.application.config.to_prepare do
  next unless defined?(RecordingStudio::ApplicationController)
  next unless defined?(RecordingStudio::UsesDefaultLayout)
  next if RecordingStudio::ApplicationController.included_modules.include?(RecordingStudio::UsesDefaultLayout)

  RecordingStudio::ApplicationController.include(RecordingStudio::UsesDefaultLayout)
end
