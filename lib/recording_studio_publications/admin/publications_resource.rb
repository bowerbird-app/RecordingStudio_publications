# frozen_string_literal: true

module RecordingStudioPublications
  module Admin
    class PublicationsResource < RecordingStudioAdmin::Resource
      key RESOURCE_KEY
      section SECTION_KEY
      icon :newspaper
      title "Manage publications"
      subtitle "Add and edit titles in the directory"
      blast_radius :site

      action :show,
             text: "Show",
             icon: "eye",
             url: lambda { |row, context|
               recording = RecordingStudioPublications.recording_for(row)
               RecordingStudioPublications::Admin.publication_url(context, recording) if recording
             },
             visible_if: ->(row, _context) { RecordingStudioPublications.recording_for(row).present? }

      action :new,
             text: "New",
             icon: "plus",
             url: ->(_row, context) { RecordingStudioPublications::Admin.new_publication_url(context) },
             required_role: :admin

      action :edit,
             text: "Edit",
             icon: "pencil-square",
             url: lambda { |row, context|
               recording = RecordingStudioPublications.recording_for(row)
               RecordingStudioPublications::Admin.edit_publication_url(context, recording) if recording
             },
             required_role: :admin,
             visible_if: ->(row, _context) { RecordingStudioPublications.recording_for(row).present? }
    end
  end
end
