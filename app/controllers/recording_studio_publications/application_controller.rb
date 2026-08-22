# frozen_string_literal: true

module RecordingStudioPublications
  class ApplicationController < ActionController::Base
    include RecordingStudio::UsesDefaultLayout if defined?(RecordingStudio::UsesDefaultLayout)

    protect_from_forgery with: :exception
    layout "recording_studio/default_layout"

    helper RecordingStudio::LayoutHelper if defined?(RecordingStudio::LayoutHelper)

    append_view_path RecordingStudioAdmin::Engine.root.join("app/views") if defined?(RecordingStudioAdmin::Engine)
  end
end
