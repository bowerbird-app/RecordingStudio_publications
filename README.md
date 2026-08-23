# RecordingStudioPublications

Publication directory addon for Recording Studio 4.x hosts.

This gem is the `recording_studio_publications` engine (`RecordingStudioPublications`). Version 0.2.0 ships a grant-less shared catalogue and family-admin CRUD for titles. It does not ship public press pages, Featured In, or per-title access management.

## What's Included

- **PublicationCatalogue** — one shared Recording Studio root per host (`label: "Publications"`, `root: true`, `shared: true`). Same idea as `RecordingStudioUser::People`. Accessible and Attachable stay off this root.
- **Publication** — nested titles under that catalogue only. Required name, required kind (`magazine`, `newspaper`, `journal`, `site`, `broadcast`), optional website, and a stable key.
- **One Attachable logo** per title. Images only. Create the title first, then add or change the logo on Attachable’s own upload and attachment screens. Persist stays on `import_attachment` / `replace_attachment_file`. There is no FileInput on New or Edit, and no Publications upload wrapper.
- **Family admin** — one `publications` section in RecordingStudioAdmin 2.0. Staff CRUD is gated by an owned host `AdminRoot` plus `RecordingStudioAdmin::Resource` `required_role: :admin`. The hub exposes family Access on that AdminRoot (`recording_studio_accessible_avatars`), a total-count widget (`type :number`), and a titles-by-kind bar chart (`type :chart`, `chart_type :bar`). Inventory search is a Screen `filter :search`. Admin does not need a grant on each title.
- **Dummy host** (`test/dummy/`) — thin Devise host, FlatPack Rounded on `<html>` via the PWA head workaround, seeded titles, and `/admin` as the catalogue.

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
- `/admin` — publications admin hub (family RecordingStudioAdmin)
- `/admin/access` — Accessible engine for AdminRoot grants
- `/admin/screens/publications` — inventory (family search filter)
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

Do not enable `:accessible` or Attachable on the shared catalogue. Accessible 0.7.0 rejects grants on shared roots. Attachable 0.4.0 is for domain children under that root.

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

The hub keeps the compact total-count widget (`type :number`) and adds a full `type :chart` / `chart_type :bar` widget of title counts per Publication `KINDS` (`magazine`, `newspaper`, `journal`, `site`, `broadcast`). FlatPack `Chart::Component` is rendered by family Admin — this gem does not add a chart library. Inventory is a family Screen table with `filter :search` (name, key, kind, website) and no placeholder “Table data” heading. Access grants live on the owned AdminRoot (`required_role :admin`), via the section PageNav avatars and the Accessible mount at `/admin/access`. Do not put Accessible on the shared catalogue.

New is a standalone FlatPack Button (not a ButtonGroup). New/edit forms are Name, Key, Kind, and Website — one field per row. Kind is the Publication enum, not a second recordable. Cancel and Save are separate Buttons. Show (and Edit) display the current logo when one exists, plus a FlatPack Button to Attachable’s add or change screens. New has no logo field.

### Capabilities

| Recordable | Accessible | Attachable |
| --- | --- | --- |
| `PublicationCatalogue` | No | No |
| `Publication` | Yes (no Manage-access UI) | Yes, images only, one logo |
| Host `AdminRoot` | Yes | No |
| Host `Workspace` | Dummy only | No |

Logo add/replace is Attachable’s own UI. Authorization still goes through AdminRoot (see `LogoAuthorization`) so catalogue staff can attach without a per-title grant. Later per-title Accessible grants can still allow non-admin actors. Mount `RecordingStudioAttachable::Engine` in the host.

### FlatPack UI

All views use FlatPack ViewComponents. The live reference is [flatpack.bowerbird.io](https://flatpack.bowerbird.io/). Theme `rounded` is monochrome charcoal. Use family admin screens, widgets, and resources — do not invent a second admin stack.

## Installing in a host

1. Add the gem and the family pins from the gemspec / dummy Gemfile.
2. Run `rails generate recording_studio_publications:install`.
3. Run `rails generate recording_studio_publications:migrations`.
4. Install Accessible, Admin, and Attachable migrations if the host does not already have them. Attachable also needs Active Storage.
5. Register `AdminRoot`, `RecordingStudioPublications::PublicationCatalogue`, `RecordingStudioPublications::Publication`, and `RecordingStudioAttachable::Attachment` in `RecordingStudio.configure`.
6. Create an owned `AdminRoot`, enable Accessible on it, and `section :publications`.
7. Point `RecordingStudioAdmin` `access_recording_resolver` and `site_admin_recording_resolver` at that admin recording.
8. Mount `recording_studio_admin_for :admin, at: "/admin", root_section: :publications`.
9. Mount `RecordingStudioAccessible::Engine` at `/admin/access` so the section Access avatars open the family Access UI on the AdminRoot.
10. Mount `RecordingStudioAttachable::Engine` (dummy: `/recording_studio_attachable`) so add/change logo can use Attachable’s screens. Keep Attachable on its blank layout so core `default_layout` does not add a second back.
11. Bootstrap first-owner admin access on the AdminRoot recording.

Authenticated screens should keep `RecordingStudio::UsesDefaultLayout`. If core puts `data-theme` on `<body>`, render `layouts/_default_layout_head` from the `recording_studio/default_layout_head` hook so `<html>` gets `data-theme="rounded"`. Do not put Sign out or a workspace switcher in that slot.

## Out of scope

- Public Publishable pages
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
| Accessible      | `~> 0.6` (dummy GitHub tag `v0.7.0`) |
| Admin           | `~> 2.0` (dummy GitHub tag `2.0.1`) |
| Attachable      | `~> 0.4` (dummy GitHub tag `0.4.0`) |
| Root Switchable | dummy GitHub tag `v0.5.0` |
| FlatPack        | `~> 0.1.133` (dummy GitHub tag `v0.1.133`) |
| Devise          | latest  |

## Documentation

Dummy admin viewports live in `docs/ui-shots/` (`publications-admin-hub.png`, inventory, new, show, edit, plus Attachable add/change). Recapture those from the dummy host with `html data-theme="rounded"` and seeded titles.

The original gem template documentation is preserved in `docs/gem_template/` as architectural reference material. This README, `CHANGELOG.md`, and the dummy app are the source of truth for the publications directory.
