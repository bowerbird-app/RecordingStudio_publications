# frozen_string_literal: true

class CreateRecordingStudioPublicationsCatalogue < ActiveRecord::Migration[8.1]
  def change
    create_catalogue_table
    create_publications_table
  end

  private

  def create_catalogue_table
    create_table :recording_studio_publications_catalogues, id: :uuid do |t|
      t.datetime :created_at, null: false
    end
  end

  def create_publications_table
    create_table :recording_studio_publications_publications, id: :uuid do |t|
      t.string :name, null: false
      t.string :key, null: false
      t.string :kind, null: false
      t.string :website
      t.datetime :created_at, null: false
    end

    add_index :recording_studio_publications_publications, :key
    add_index :recording_studio_publications_publications, :kind
    add_index :recording_studio_publications_publications, :name
  end
end
