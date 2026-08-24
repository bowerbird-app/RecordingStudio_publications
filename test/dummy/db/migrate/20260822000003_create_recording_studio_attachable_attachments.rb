# frozen_string_literal: true

class CreateRecordingStudioAttachableAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_attachable_attachments, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.string :attachment_kind, null: false
      t.string :original_filename, null: false
      t.string :content_type, null: false
      t.bigint :byte_size, null: false
    end

    add_index :recording_studio_attachable_attachments, :attachment_kind
    add_index :recording_studio_attachable_attachments, %i[attachment_kind content_type],
              name: "idx_rs_attachable_kind_type"
  end
end
