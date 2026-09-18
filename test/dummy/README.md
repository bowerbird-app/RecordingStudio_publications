# Dummy App

This Rails app exists to validate the Recording Studio publications gem in a real host application for `recording_studio_publications`.

## What It Covers

- Devise authentication with a seeded admin user and a member without admin access
- `Current.actor` wiring for Recording Studio events
- Host-owned Workspace roots plus a separate owned `AdminRoot`
- Shared `PublicationCatalogue` root (no Accessible, no Attachable, no Publishable) and Publication children
- `PublishedArticle` children under a Publication. Dummy seeds three Atlantic articles and one screenshot
- Attachable enabled on Publication (logo) and PublishedArticle (screenshot), images only, added after the record exists
- Publishable enabled on Publication only. Seeded The Atlantic is currently published
- Family admin at `/admin` (`recording_studio_admin_for`, `root_section: :root`). The home title is **Publications demo**. The publications section has count-plus-chart widgets, Accessible avatars, and buttons to both inventories plus publication types
- Accessible mounted at `/admin/access` so the publications section can manage AdminRoot grants
- Attachable mounted at `/recording_studio_attachable` for add/change logo, using Attachable’s blank layout so those screens have one PageNav (not a second back from default_layout)
- Flatpack sidebar (`flat_pack_sidebar`) for authenticated home and docs. Recording Studio default layout only on gem title and article new/show/edit. FlatPack assets and Tailwind `@source` scanning for `vendor/bundle`, `/usr/local/bundle`, and `/usr/local/lib/ruby/gems` so Cloud Agent images still emit Grid/Table classes
- Dummy-only `/docs/*` pages for gem-specific onboarding

## Quick Start

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Run the commands above from the dummy app directory, not the repository root.

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

`member@admin.com` / `Password` can sign in but cannot open publications admin.

## Useful Routes

- `/` - dummy app home and a short link into publications admin
- `/admin` - dummy admin home (title **Publications demo** and a primary button to the publications section)
- `/admin/sections/publications` - publications section with totals, over-time charts, and buttons to both inventories plus publication types
- `/admin/access` - family Access UI for the owned AdminRoot
- `/admin/publications` - inventory with family search, the Screen publications-over-time chart, Name / Publication type / Website / Articles columns, and **Publication** under the title
- `/admin/articles` - articles inventory with a publication filter
- `/admin/publication_types` - closed publication types with a count of titles in each category
- `/publications/:uuid/:slug` - public page for a currently published title
- `/recording_studio_publications/admin/publications/new` - new title (no logo field)
- `/recording_studio_publications/admin/publications/:id/articles` - articles for that title
- `/recording_studio_attachable/recordings/:id/attachments/upload` - add a logo after the title exists
- `/recording_studio_attachable/attachments/:id` - change an existing logo
- `/recording_studio` - redirects to `/` while the mounted Recording Studio engine stays available under that prefix
- `/users/sign_in` - Devise sign-in page
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` - dummy-only starter pages
- `/up` - Rails health check

## Why This App Exists

Use this app to verify the publications directory before copying host wiring into another app. The host stays thin: AdminRoot, resolvers, seeds, and mounts. Catalogue models and admin definitions live in the gem.

Authenticated dummy home and docs use the Flatpack sidebar (`flat_pack_sidebar`), like other Recording Studio gems. Title and article new/show/edit stay on Recording Studio's shared default layout. The dummy copies FlatPack `rounded` onto `<html>` through `app/views/layouts/_default_layout_head.html.erb`, rendered from `app/views/recording_studio/_default_layout_head.html.erb`. Sign out and the workspace switcher live on the sidebar and top nav, not in the default-layout slot. Devise sign-in keeps `layouts/application`. Attachable add/change use Attachable’s blank layout so they keep one PageNav.

The host home stays a short demo surface. Open `/admin` for the demo home, then the publications section for inventory, new, show, and edit. Add or change a logo from the saved title — Attachable owns those screens. Change publish state from show/edit with the status dropdown. Draft and scheduled titles use **Preview** on that menu (staff-only public page with a Preview badge). Currently published titles use **View** for the live `/publications/:uuid/:slug` URL, which readers can open without signing in.
