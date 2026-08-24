# frozen_string_literal: true

RecordingStudioAttachable.configure do |config|
  config.allowed_content_types = ["image/*"]
  config.max_file_size = 25.megabytes
  config.max_file_count = 1
  config.enabled_attachment_kinds = %i[image]
  config.default_listing_scope = :direct
  config.default_kind_filter = :images

  # Attachable views already render one FlatPack PageNav. Core
  # default_layout always adds another back, so keep Attachable on its
  # blank layout. That layout already sets html data-theme="rounded".
  config.layout = :blank
  config.auth_roles = {
    view: :view,
    upload: :edit,
    revise: :edit,
    remove: :admin,
    restore: :admin,
    download: :view
  }
end
