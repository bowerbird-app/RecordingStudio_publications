# frozen_string_literal: true

class CreateRecordingStudioPublicationsPublishedArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_publications_published_articles, id: :uuid do |table|
      article_columns(table)
    end
  end

  def article_columns(table)
    table.string :title, null: false
    table.string :url
    table.string :canonical_url
    table.date :published_on
    table.string :byline
    table.text :excerpt
    table.datetime :created_at, null: false
    %i[title published_on byline].each { |column| table.index column }
  end
end
