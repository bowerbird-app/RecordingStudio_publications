# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

SEED_LOGO_PATH = Rails.root.join("db/seed_assets/publication_logo.png") unless defined?(SEED_LOGO_PATH)

find_or_record_child = lambda do |recordable, root_recording, parent_recording|
  RecordingStudio::Recording.find_by(
    root_recording: root_recording,
    parent_recording: parent_recording,
    recordable: recordable,
    trashed_at: nil
  ) || RecordingStudio.record!(
    action: "created",
    recordable: recordable,
    root_recording: root_recording,
    parent_recording: parent_recording
  ).recording
end

bootstrap_owner_access = lambda do |actor, recording|
  result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
  raise result.error if result.failure?
end

ensure_seed_logo = lambda do |recording, key:, actor:|
  publication = recording.recordable
  logo = RecordingStudioPublications.logo_recording_for(publication)
  byte_size = logo&.recordable&.file&.byte_size.to_i
  return if logo && byte_size >= 200

  logo.remove_attachment(actor: actor) if logo.respond_to?(:remove_attachment)
  File.open(SEED_LOGO_PATH, "rb") do |io|
    recording.import_attachment(
      io: io,
      filename: "#{key}.png",
      content_type: "image/png",
      name: "Logo",
      actor: actor
    )
  end
end

ensure_published = lambda do |recording, slug:, actor:|
  return if recording.blank?
  return if recording.respond_to?(:currently_published?) && recording.currently_published?

  result = RecordingStudioPublishable::Services::Publishables::Update.call(
    parent_recording: recording,
    actor: actor,
    attributes: { status: "published", slug: slug }
  )
  raise result.error if result.failure?
end

seed_publication = lambda do |name:, key:, kind:, website:, actor:, created_at:, publish: false|
  existing = RecordingStudioPublications::Publication.find_by(key: key)
  if existing
    RecordingStudioPublications::Publication.where(id: existing.id).update_all(created_at: created_at)
    recording = RecordingStudioPublications.recording_for(existing)
    ensure_seed_logo.call(recording, key: key, actor: actor) if recording
    ensure_published.call(recording, slug: key, actor: actor) if publish
    return existing
  end

  recording = RecordingStudioPublications.record_publication!(
    { name: name, key: key, kind: kind, website: website },
    actor: actor
  )
  publication = recording.recordable
  RecordingStudioPublications::Publication.where(id: publication.id).update_all(created_at: created_at)
  ensure_seed_logo.call(recording, key: key, actor: actor)
  ensure_published.call(recording, slug: key, actor: actor) if publish
  publication
end

ensure_seed_article = lambda do |publication:, title:, url:, published_on:, byline:, excerpt:, actor:|
  existing = RecordingStudioPublications.articles_for(publication).find_by(title: title, url: url)
  return existing if existing

  RecordingStudioPublications.record_article!(
    publication,
    {
      title: title,
      url: url,
      published_on: published_on,
      byline: byline,
      excerpt: excerpt
    },
    actor: actor
  ).recordable
end
user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

member = User.find_or_create_by!(email: "member@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

# Create the workspace recordables
workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
accessible_workspace = Workspace.find_or_create_by!(name: "Client Workspace")
private_workspace = Workspace.find_or_create_by!(name: "Private Workspace")
folder = Folder.find_or_create_by!(name: "Product Docs")
page = Page.find_or_create_by!(title: "Getting Started")

previous_actor = Current.actor
Current.actor = user

begin
  # Create the root recording
  root_recording = RecordingStudio.root_recording_for(workspace)
  accessible_root_recording = RecordingStudio.root_recording_for(accessible_workspace)
  private_root_recording = RecordingStudio.root_recording_for(private_workspace)

  folder_recording = find_or_record_child.call(folder, root_recording, root_recording)

  find_or_record_child.call(page, root_recording, folder_recording)

  admin_root = AdminRoot.find_or_create_by!(name: "Admin")
  admin_root_recording = RecordingStudio.root_recording_for(admin_root)
  bootstrap_owner_access.call(user, admin_root_recording)

  atlantic = seed_publication.call(
    name: "The Atlantic",
    key: "the-atlantic",
    kind: "magazine",
    website: "https://www.theatlantic.com",
    actor: user,
    created_at: 8.weeks.ago,
    publish: true
  )
  rainforest = ensure_seed_article.call(
    publication: atlantic,
    title: "House in the Rainforest",
    url: "https://www.theatlantic.com/house-in-the-rainforest",
    published_on: Date.new(2024, 3, 12),
    byline: "Jane Architect",
    excerpt: "A house designed around the existing trees.",
    actor: user
  )
  ensure_seed_article.call(
    publication: atlantic,
    title: "Ten Australian Houses",
    url: "https://www.theatlantic.com/ten-australian-houses",
    published_on: Date.new(2023, 11, 2),
    byline: "Sam Editor",
    excerpt: "A survey of recent Australian residential work.",
    actor: user
  )
  ensure_seed_article.call(
    publication: atlantic,
    title: "New Architecture in Melbourne",
    url: "https://www.theatlantic.com/new-architecture-melbourne",
    published_on: Date.new(2025, 1, 18),
    byline: "Jane Architect",
    excerpt: "Civic buildings reshaping the city’s centre.",
    actor: user
  )
  rainforest_recording = RecordingStudioPublications.article_recording_for(rainforest)
  if rainforest_recording && RecordingStudioPublications.screenshot_recording_for(rainforest).blank?
    File.open(SEED_LOGO_PATH, "rb") do |io|
      rainforest_recording.import_attachment(
        io: io,
        filename: "house-in-the-rainforest.png",
        content_type: "image/png",
        name: "Screenshot",
        actor: user
      )
    end
  end
  seed_publication.call(
    name: "The Guardian",
    key: "the-guardian",
    kind: "newspaper",
    website: "https://www.theguardian.com",
    actor: user,
    created_at: 6.weeks.ago
  )
  seed_publication.call(
    name: "Nature",
    key: "nature",
    kind: "journal",
    website: "https://www.nature.com",
    actor: user,
    created_at: 4.weeks.ago
  )
  seed_publication.call(
    name: "BBC News",
    key: "bbc-news",
    kind: "broadcast",
    website: "https://www.bbc.com/news",
    actor: user,
    created_at: 2.weeks.ago
  )
  seed_publication.call(
    name: "The Verge",
    key: "the-verge",
    kind: "site",
    website: "https://www.theverge.com",
    actor: user,
    created_at: 3.days.ago
  )
ensure
  Current.actor = previous_actor
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: member@admin.com / Password (no admin access)"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Workspace '#{accessible_workspace.name}' with root recording ##{accessible_root_recording.id}"
puts "Seeded: Workspace '#{private_workspace.name}' with root recording ##{private_root_recording.id}"
puts "Seeded: Folder '#{folder.name}' and page '#{page.title}'"
puts "Seeded: Admin root with first-owner admin access for the publications directory"
puts "Seeded: #{RecordingStudioPublications.publications.count} publication titles under the shared Publications catalogue"
puts "Seeded: #{RecordingStudioPublications::PublishedArticle.count} articles under those titles"
puts "Unused member account: #{member.email}"
