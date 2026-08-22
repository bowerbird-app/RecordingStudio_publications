# frozen_string_literal: true

RecordingStudioPublications::Engine.routes.draw do
  namespace :admin do
    resources :publications, only: %i[index new create show edit update]
  end
end
