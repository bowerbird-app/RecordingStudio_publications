# frozen_string_literal: true

module RecordingStudioPublications
  class PublishedPublication
    def self.build(publication:, logo_recording: nil)
      raise ArgumentError, "publication is required" if publication.blank?

      new(
        name: publication.name,
        publication_type_label: publication.publication_type&.label,
        website: publication.website,
        logo_url: logo_url_for(logo_recording),
        logo_alt: logo_alt_for(publication, logo_recording)
      )
    end

    def self.logo_url_for(logo_recording)
      file = logo_recording&.recordable&.file
      return unless file&.attached?
      return unless defined?(Rails) && Rails.application.respond_to?(:routes)

      Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
    end
    private_class_method :logo_url_for

    def self.logo_alt_for(publication, logo_recording)
      return if logo_recording.blank?

      "#{publication.name} logo"
    end
    private_class_method :logo_alt_for

    def initialize(name:, publication_type_label:, website:, logo_url:, logo_alt:)
      @name = name
      @publication_type_label = publication_type_label
      @website = website
      @logo_url = logo_url
      @logo_alt = logo_alt
    end
    private_class_method :new

    attr_reader :name, :publication_type_label, :website, :logo_url, :logo_alt

    def document_title
      name
    end

    def social_title
      name
    end
  end
end
