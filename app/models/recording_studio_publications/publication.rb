# frozen_string_literal: true

module RecordingStudioPublications
  class Publication < ApplicationRecord
    self.table_name = "recording_studio_publications_publications"

    KINDS = PublicationType::TOKENS
    ALLOWED_PARENT_TYPES = ["RecordingStudioPublications::PublicationCatalogue"].freeze
    KEY_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

    recording_studio_recordable label: "Publication",
                                root: false,
                                allowed_parent_types: ALLOWED_PARENT_TYPES
    RecordingStudio.enable_capability(:accessible, on: self)

    include RecordingStudio::Capabilities::Attachable.to(
      allowed_content_types: ["image/*"],
      enabled_attachment_kinds: %i[image],
      authorize_with: FamilyAuthorization
    )

    include RecordingStudio::Capabilities::Publishable.to(
      public_controller: "recording_studio_publications/public_publications",
      public_action: :show,
      public_layout: "recording_studio_publications/public",
      path: "/publications/:uuid/:slug",
      schedule: true,
      seo: true
    )

    validates :name, presence: true
    validates :kind, presence: true, inclusion: { in: KINDS }
    validates :key, presence: true, format: { with: KEY_FORMAT }
    validate :website_must_be_http_url

    before_validation :assign_key_from_name, on: :create
    before_create { self.created_at ||= Time.current }

    def publication_type
      PublicationType.try_parse(kind)
    end

    def kind_label
      publication_type&.label || kind.to_s.titleize
    end

    private

    def assign_key_from_name
      self.key = self.class.unique_key_for(name) if key.blank? && name.present?
    end

    def website_must_be_http_url
      return if website.blank?

      uri = URI.parse(website)
      return if uri.is_a?(URI::HTTP) && uri.host.present?

      errors.add(:website, "must be an http or https URL")
    rescue URI::InvalidURIError
      errors.add(:website, "must be an http or https URL")
    end

    class << self
      def unique_key_for(name, except_recording: nil)
        base = name.to_s.parameterize.presence || "publication"
        candidate = base
        suffix = 2

        while RecordingStudioPublications::Catalogue.key_in_use?(candidate, except_recording: except_recording)
          candidate = "#{base}-#{suffix}"
          suffix += 1
        end

        candidate
      end
    end
  end
end
