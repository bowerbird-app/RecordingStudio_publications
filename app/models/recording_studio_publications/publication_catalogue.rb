# frozen_string_literal: true

module RecordingStudioPublications
  class PublicationCatalogue < ApplicationRecord
    self.table_name = "recording_studio_publications_catalogues"

    recording_studio_recordable label: "Publications", root: true, shared: true

    before_create { self.created_at ||= Time.current }
  end
end
