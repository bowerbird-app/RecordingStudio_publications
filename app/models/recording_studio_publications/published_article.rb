# frozen_string_literal: true

module RecordingStudioPublications
  class PublishedArticle < ApplicationRecord
    self.table_name = "recording_studio_publications_published_articles"

    ALLOWED_PARENT_TYPES = ["RecordingStudioPublications::Publication"].freeze
    HTTP_URL_ATTRIBUTES = %i[url canonical_url].freeze

    recording_studio_recordable label: "Article",
                                root: false,
                                allowed_parent_types: ALLOWED_PARENT_TYPES

    include RecordingStudio::Capabilities::Attachable.to(
      allowed_content_types: ["image/*"],
      enabled_attachment_kinds: %i[image],
      authorize_with: FamilyAuthorization
    )

    validates :title, presence: true
    validate :http_urls_must_be_valid

    before_create { self.created_at ||= Time.current }

    private

    def http_urls_must_be_valid
      HTTP_URL_ATTRIBUTES.each do |attribute|
        value = public_send(attribute)
        next if value.blank?

        uri = URI.parse(value)
        next if uri.is_a?(URI::HTTP) && uri.host.present?

        errors.add(attribute, "must be an http or https URL")
      rescue URI::InvalidURIError
        errors.add(attribute, "must be an http or https URL")
      end
    end
  end
end
