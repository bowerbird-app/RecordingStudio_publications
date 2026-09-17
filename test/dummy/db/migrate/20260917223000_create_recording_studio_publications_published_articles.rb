# frozen_string_literal: true

class CreateRecordingStudioPublicationsPublishedArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_publications_published_articles, id: :uuid do |t|
      t.string :title, null: false
      t.string :url
      t.string :canonical_url
      t.date :published_on
      t.string :byline
      t.text :excerpt
      t.datetime :created_at, null: false
    end

    add_index :recording_studio_publications_published_articles, :title
    add_index :recording_studio_publications_published_articles, :published_on
    add_index :recording_studio_publications_published_articles, :byline
  end
end
