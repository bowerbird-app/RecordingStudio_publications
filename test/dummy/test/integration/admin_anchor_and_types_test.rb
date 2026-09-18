# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "nokogiri"

class AdminAnchorAndTypesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.find_or_create_by!(email: "admin-anchor-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    @admin_recording = admin_root_recording_for_test
    Current.actor = @admin
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
  end

  teardown do
    Current.actor = nil
  end

  test "inventory actions pass the inventory as the default-layout origin" do
    recording = RecordingStudioPublications.record_publication!(
      { name: "Origin Magazine", key: "origin-magazine", kind: "magazine" },
      actor: @admin
    )

    get "/admin/publications"
    assert_response :success
    page = Nokogiri::HTML(response.body)
    new_link = page.css("a").find { |anchor| anchor["href"]&.include?("/admin/publications/new") }
    assert new_link
    assert_includes new_link["href"], "anchor_url=%2Fadmin%2Fpublications"

    get "/admin/screens/publications/table", params: { search: "Origin Magazine" }
    assert_response :success
    table = Nokogiri::HTML(response.body)
    show_link = table.css("a").find { |anchor| anchor.text.strip == "Origin Magazine" }
    assert_equal "#{recording_studio_publications.admin_publication_path(recording)}?anchor_url=%2Fadmin%2Fpublications",
                 show_link["href"]
  end

  test "action screens keep the first trigger on close edit and save" do
    origin = "/admin/publications"

    get recording_studio_publications.new_admin_publication_path, params: { anchor_url: origin }
    assert_response :success
    assert_select "a[href='#{origin}'][aria-label='Close']"
    assert_select "input[name='anchor_url'][value='#{origin}']"
    new_page = Nokogiri::HTML(response.body)
    cancel = new_page.css("a").find { |anchor| anchor.text.strip == "Cancel" }
    assert_equal origin, cancel["href"]

    post recording_studio_publications.admin_publications_path, params: {
      anchor_url: origin,
      publication: {
        name: "Anchored Journal",
        key: "anchored-journal",
        kind: "journal",
        website: "https://anchored.example"
      }
    }

    publication = RecordingStudioPublications.publications.find_by!(key: "anchored-journal")
    recording = RecordingStudioPublications.recording_for(publication)
    assert_redirected_to "#{recording_studio_publications.admin_publication_path(recording)}?anchor_url=#{CGI.escape(origin)}"

    follow_redirect!
    assert_response :success
    assert_select "a[href='#{origin}'][aria-label='Close']"
    show_page = Nokogiri::HTML(response.body)
    edit_link = show_page.css("a").find { |anchor| anchor.text.strip == "Edit" }
    assert_includes edit_link["href"], "anchor_url=#{CGI.escape(origin)}"

    get recording_studio_publications.edit_admin_publication_path(recording), params: { anchor_url: origin }
    assert_response :success
    assert_select "a[href='#{origin}'][aria-label='Close']"

    patch recording_studio_publications.admin_publication_path(recording), params: {
      anchor_url: origin,
      publication: {
        name: "Anchored Journal Revised",
        key: "anchored-journal",
        kind: "journal",
        website: "https://anchored.example/revised"
      }
    }
    assert_redirected_to "#{recording_studio_publications.admin_publication_path(recording)}?anchor_url=#{CGI.escape(origin)}"
  end

  test "article actions keep the articles inventory as the origin" do
    origin = "/admin/articles"
    publication_recording = RecordingStudioPublications.record_publication!(
      { name: "Anchor Daily", key: "anchor-daily", kind: "newspaper" },
      actor: @admin
    )

    get recording_studio_publications.new_admin_publication_article_path(publication_recording),
        params: { anchor_url: origin }
    assert_response :success
    assert_select "a[href='#{origin}'][aria-label='Close']"

    post recording_studio_publications.admin_publication_articles_path(publication_recording), params: {
      anchor_url: origin,
      article: { title: "Anchored Story", url: "https://daily.example/story" }
    }
    article = RecordingStudioPublications.articles_for(publication_recording.recordable).find_by!(title: "Anchored Story")
    article_recording = RecordingStudioPublications.article_recording_for(article)
    assert_redirected_to "#{recording_studio_publications.admin_publication_article_path(
      publication_recording,
      article_recording
    )}?anchor_url=#{CGI.escape(origin)}"

    follow_redirect!
    assert_select "a[href='#{origin}'][aria-label='Close']"
  end

  test "publication types screen lists every category with a usage count" do
    RecordingStudioPublications.record_publication!(
      { name: "Type Magazine One", key: "type-magazine-one", kind: "magazine" },
      actor: @admin
    )
    RecordingStudioPublications.record_publication!(
      { name: "Type Magazine Two", key: "type-magazine-two", kind: "magazine" },
      actor: @admin
    )
    RecordingStudioPublications.record_publication!(
      { name: "Type Journal", key: "type-journal", kind: "journal" },
      actor: @admin
    )

    rows = RecordingStudioPublications::Admin.publication_type_rows
    assert_equal RecordingStudioPublications::PublicationType::TOKENS, rows.map(&:token)
    magazine = rows.find { |row| row.token == "magazine" }
    journal = rows.find { |row| row.token == "journal" }
    broadcast = rows.find { |row| row.token == "broadcast" }
    assert_equal "Magazine", magazine.label
    assert_operator magazine.publications_count, :>=, 2
    assert_operator journal.publications_count, :>=, 1
    assert_equal RecordingStudioPublications.publications.where(kind: "broadcast").count,
                 broadcast.publications_count

    get "/admin/publication_types"
    assert_response :success
    assert_includes response.body, "Publication types"
    assert_includes response.body, "How many titles sit in each category"

    get "/admin/screens/publication_types/table"
    assert_response :success
    table = Nokogiri::HTML(response.body)
    assert_includes response.body, "Magazine"
    assert_includes response.body, "Newspaper"
    assert_includes response.body, "Journal"
    assert_includes response.body, "Site"
    assert_includes response.body, "Broadcast"
    magazine_count = table.css("a").find { |anchor| anchor["href"]&.include?("publication_type=magazine") }
    assert magazine_count, "expected the magazine count to link to the filtered inventory"
    assert_equal magazine.publications_count.to_s, magazine_count.text.strip
    assert_includes magazine_count["href"], "/admin/publications"
    assert_includes magazine_count["href"], "publication_type=magazine"
    assert_includes magazine_count["href"], "anchor_url=%2Fadmin%2Fpublication_types"
  end
end
