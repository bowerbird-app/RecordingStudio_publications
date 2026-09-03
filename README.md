# RecordingStudioPublications

Publication directory addon for Recording Studio 4.x hosts.

This gem is the `recording_studio_publications` engine (`RecordingStudioPublications`). Version 0.3.0 adds Publishable on each title, a public page at `/publications/:uuid/:slug`, and family-management composition. It keeps the 0.2 grant-less shared catalogue and family-admin CRUD, and pins Accessible `~> 0.9`, Attachable `~> 0.5`, Publishable `~> 0.2`, and Flatpack `~> 0.1.143`. It does not ship Featured In or a per-title Manage-access UI.

## What's Included

- **PublicationCatalogue** — one shared Recording Studio root per host (`label: "Publications"`, `root: true`, `shared: true`). Same idea as `RecordingStudioUser::People`. Accessible and Attachable stay off this root.
- **Publication** — nested titles under that catalogue only. Required name, required publication type stored as `kind` (`magazine`, `newspaper`, `journal`, `site`, `broadcast`), optional website, and a stable key.
- **One Attachable logo** per title. Images only. Create the title first, then add or change the logo on Attachable’s own upload and attachment screens. Persist stays on `import_attachment` / `replace_attachment_file`. There is no FileInput on New or Edit, and no Publications upload wrapper.
- **Family admin** — one `publications` section in RecordingStudioAdmin 2.0. The section title is **Admin publications**. The inventory, count card, catalogue label, and dummy `app_name` stay **Publications**. Staff CRUD is gated by an owned host `AdminRoot` plus `RecordingStudioAdmin::Resource` `required_role: :admin`. The hub exposes family Access on that AdminRoot (`recording_studio_accessible_avatars`), a total-count widget (`type :number`), a publications-over-time line chart (`type :chart`, `chart_type :line`, widget key `widgets.publications.over_time`), and a publication-types bar chart (`type :chart`, `chart_type :bar`, widget key `widgets.publications.by_kind`). Inventory search is a Screen `filter :search`. Admin does not need a grant on each title.
- **Publishable on Publication only** — one `RecordingStudioPublishable::Publishable` child holds slug, schedule, SEO, and social state. Staff open Publishable’s screen from show/edit. Readers hit `/publications/:uuid/:slug` without signing in. Draft, scheduled, and expired URLs 404. A stale slug redirects. `PublicationCatalogue` stays capability-free.
- **Dummy host** (`test/dummy/`) — thin Devise host, FlatPack Rounded on `<html>` via the PWA head workaround, seeded titles with a real 128px logo PNG, and `/admin` as the catalogue. Dummy Tailwind `@source` scans Flatpack, Admin, and Attachable under `vendor/bundle`, `/usr/local/bundle`, and `/usr/local/lib/ruby/gems` so Cloud Agent images still emit Grid/Table classes.

This is a directory gem, not a two-sided marketplace. Hosts stay thin: they register recordable types, own `AdminRoot`, seed first staff access, and mount the engines.

## Quick Start

### GitHub Codespaces (Recommended)

1. Click **Code** → **Codespaces** → **Create codespace**
2. Wait for setup to complete
3. Run:
   ```bash
   cd test/dummy
   bin/rails db:setup
   bin/dev
   ```
4. Open port 3000, sign in at `/users/sign_in`, then open `/admin`

### Login Credentials

| Field    | Value             |
|----------|-------------------|
| Email    | admin@admin.com   |
| Password | Password          |

The login form is prefilled with these credentials for fast access. `member@admin.com` / `Password` is a signed-in user without AdminRoot access.

### Useful Routes

- `/` — dummy host home
- `/users/sign_in` — Devise sign-in
- `/admin` — publications admin hub (family RecordingStudioAdmin; section title Admin publications)
- `/admin/access` — Accessible engine for AdminRoot grants
- `/admin/screens/publications` — inventory (family search filter)
- `/publications/:uuid/:slug` — public page for a currently published title
- `/recording_studio_publications/admin/publications/new` — new title (no logo field)
- `/recording_studio_attachable/recordings/:id/attachments/upload` — Attachable add-logo screen
- `/recording_studio_attachable/attachments/:id` — Attachable change-logo screen
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` — dummy-only sandbox pages

## Architecture

### Shared catalogue

`RecordingStudioPublications::PublicationCatalogue` is the forest root. There is one per host. Nobody owns the forest through that node.

```ruby
RecordingStudioPublications.catalogue_root.record(RecordingStudioPublications::Publication) do |publication|
  publication.name = "The Atlantic"
  publication.kind = "magazine"
  publication.website = "https://www.theatlantic.com"
end
```

`Publication` may enable Accessible so later per-title grants can work. v1 does not ship a Manage-access UI. Admin CRUD authorizes against the host AdminRoot, not against a grant on the title.

Do not enable `:accessible` or Attachable on the shared catalogue. Accessible 0.9 rejects grants on shared roots. Attachable 0.5 is for domain children under that root.

### Host AdminRoot

The host owns a separate admin root (`shared: false`) and opts the publications section in:

```ruby
class AdminRoot < ApplicationRecord
  include RecordingStudioAdmin::AllowsAdminSections

  recording_studio_recordable label: "Admin", root: true, shared: false
  RecordingStudio.enable_capability(:accessible, on: self)

  recording_studio_admin_sections do
    section :publications
  end
end
```

Seed first staff with `RecordingStudioAccessible.bootstrap_owner_access!` on that admin recording. Do not use `user.admin?`, Pundit, or a custom ACL.

### Family admin

The gem registers a Section, Screen, Resource, and widgets with `blast_radius :site`:

| Surface | Path |
| --- | --- |
| Hub | `/admin` or `/admin/sections/publications` |
| Access | `/admin/access/recordings/:admin_root_id/accesses` |
| Inventory | `/admin/screens/publications` |
| New / show / edit | `/recording_studio_publications/admin/publications/...` |

The hub keeps the compact total-count widget (`type :number`), a full `type :chart` / `chart_type :line` widget of cumulative titles by week, then a `type :chart` / `chart_type :bar` widget of title counts per publication type. Inventory is the family Admin Screen template: `filter :search`, a registered Screen `button :new_publication` to this gem’s New page, and the family Screen `chart` (`type :area`, cumulative count by `created_at`, weekly buckets). Family Screen widgets always render as compact cards, so inventory does not register a widget that would duplicate that growth chart. The inventory table is Name, Publication type, Website, and Actions — no Key column. The form still posts `publication[kind]`. The table already shows the row count, so the number widget stays on the hub only. Admin’s table `title` only assigns a present value, so the family default “Table data” heading stays. Access grants live on the owned AdminRoot (`required_role :admin`), via the section PageNav avatars and the Accessible mount at `/admin/access`. Do not put Accessible on the shared catalogue. FlatPack `Chart::Component` is rendered by family Admin — this gem does not add a chart library.

New, show, and edit stay this gem’s controllers and forms. New/edit forms are Name, Key, Publication type, and Website — one field per row. Publication type is the closed `kind` list, not a second recordable. Cancel and Save are separate Buttons. Show (and Edit) display the current logo when one exists, plus a FlatPack Button to Attachable’s add or change screens. When Edit is allowed, a secondary button opens the public-page screen: **Publish** for a draft, **Public page** when it is live, **Change schedule** when it is scheduled. The status badge stays a status, not a second Publish action. New has no logo field.

### Capabilities

| Recordable | Accessible | Attachable | Publishable |
| --- | --- | --- | --- |
| `PublicationCatalogue` | No | No | No |
| `Publication` | Yes (no Manage-access UI) | Yes, images only, one logo | Yes |
| Host `AdminRoot` | Yes | No | No |
| Host `Workspace` | Dummy only | No | No |

Logo add/replace is Attachable’s own UI. Authorization for logos and publish screens goes through `FamilyAuthorization`: AdminRoot first, then a per-title Accessible grant. Hosts call `RecordingStudioPublications::FamilyManagement.install!` after any other Publishable authorizer so Publication parents use family policy and other types keep their previous callable. The engine does not write Publishable’s global authorizer on boot. Mount `RecordingStudioAttachable::Engine` and `RecordingStudioPublishable::Engine` in the host.

### FlatPack UI

All views use FlatPack ViewComponents. The live reference is [flatpack.bowerbird.io](https://flatpack.bowerbird.io/). Theme `rounded` is monochrome charcoal. Use family admin screens, widgets, and resources — do not invent a second admin stack.

## Installing in a host

1. Add the gem and the family pins from the gemspec / dummy Gemfile.
2. Run `rails generate recording_studio_publications:install`.
3. Run `rails generate recording_studio_publications:migrations`.
4. Install Accessible, Admin, Attachable, and Publishable migrations if the host does not already have them. Attachable also needs Active Storage.
5. Register `AdminRoot`, `RecordingStudioPublications::PublicationCatalogue`, `RecordingStudioPublications::Publication`, `RecordingStudioAttachable::Attachment`, and `RecordingStudioPublishable::Publishable` in `RecordingStudio.configure`.
6. Create an owned `AdminRoot`, enable Accessible on it, and `section :publications`.
7. Point `RecordingStudioAdmin` `access_recording_resolver` and `site_admin_recording_resolver` at that admin recording.
8. Mount `recording_studio_admin_for :admin, at: "/admin", root_section: :publications`.
9. Mount `RecordingStudioAccessible::Engine` at `/admin/access` so the section Access avatars open the family Access UI on the AdminRoot.
10. Mount `RecordingStudioAttachable::Engine` (dummy: `/recording_studio_attachable`) so add/change logo can use Attachable’s screens. Keep Attachable on its blank layout so core `default_layout` does not add a second back.
11. Add `recording_studio_publishable ~> 0.2`, install its migrations, and mount `RecordingStudioPublishable::Engine` at `/`. Call `RecordingStudioPublications::FamilyManagement.install!` from a host initializer. Scan Publishable views in Tailwind `@source`.
12. Bootstrap first-owner admin access on the AdminRoot recording.

Authenticated screens should keep `RecordingStudio::UsesDefaultLayout`. If core puts `data-theme` on `<body>`, render `layouts/_default_layout_head` from the `recording_studio/default_layout_head` hook so `<html>` gets `data-theme="rounded"`. Do not put Sign out or a workspace switcher in that slot.

## Out of scope

- Featured In / press-kit foreign keys
- Moveable, Sitemaps, journalist or submission flows
- ISSN / country
- A second admin app, host Tailwind themes, or CSS forks

## Tech Stack

| Component       | Version |
|-----------------|---------|
| Ruby            | 3.3+    |
| Rails           | 8.1+    |
| PostgreSQL      | 16      |
| TailwindCSS     | 4       |
| RecordingStudio | 4.x (`~> 4.2` in the gemspec; dummy GitHub tag `v4.2.0`) |
| Accessible      | `~> 0.9` (dummy GitHub tag `v0.9.0`) |
| Admin           | `~> 2.0` (dummy GitHub tag `2.0.1`) |
| Attachable      | `~> 0.5` (dummy GitHub tag `v0.5.0`) |
| Publishable     | `~> 0.2` (dummy GitHub tag `v0.2.1`) |
| Root Switchable | dummy GitHub tag `v0.5.0` |
| FlatPack        | `~> 0.1.143` (dummy GitHub tag `v0.1.143`) |
| Devise          | latest  |

## Documentation

Dummy admin viewports live in `doc/review/` (`publications-admin-hub.png`, inventory, new, show, edit, plus Attachable add/change). Recapture those from the dummy host with `html data-theme="rounded"` and seeded titles. Inventory must show the family Screen chart only, not a compact titles-over-time card.

The original gem template documentation is preserved in `docs/gem_template/` as architectural reference material. This README, `CHANGELOG.md`, and the dummy app are the source of truth for the publications directory.
