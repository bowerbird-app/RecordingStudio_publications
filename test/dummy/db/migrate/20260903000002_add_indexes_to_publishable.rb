# frozen_string_literal: true

class AddIndexesToPublishable < ActiveRecord::Migration[8.1]
  def change
    add_index :recording_studio_publishable_publishables, %i[status publish_at unpublish_at],
              name: "index_publishables_on_status_and_publish_times"
  end
end
