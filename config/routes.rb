# frozen_string_literal: true

RecordingStudioPublications::Engine.routes.draw do
  # Keep /admin/* URLs and admin_* helpers without a controller Admin
  # namespace. Zeitwerk maps app/controllers/.../admin/ onto
  # RecordingStudioPublications::Admin and would shadow the family admin
  # definitions in lib/recording_studio_publications/admin.rb.
  scope path: "admin", as: "admin" do
    resources :publications, only: %i[index new create show edit update]
  end
end
