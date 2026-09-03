# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-09-03

Publishable on each title, a public press page, family-management composition, and publication-type copy.

### Added
- `recording_studio_publishable ~> 0.2` runtime dependency. Dummy pins GitHub tag `v0.2.1`
- `RecordingStudio::Capabilities::Publishable.to` on `Publication` only, with public path `/publications/:uuid/:slug`
- `PublicationType` closed token registry. `Publication::KINDS` derives from it. `#publication_type` is a reader
- `FamilyAuthorization` replaces `LogoAuthorization` for logos and publish screens (AdminRoot first, then per-title Accessible)
- `FamilyManagement.install!` wraps the current Publishable authorizer and close-URL resolver. Idempotent. The engine does not assign those globals on boot
- `PublishedPublication` public page model and a callback-free `PublicPublicationsController#show`
- Public layout `recording_studio_publications/public` with no PageNav and no competing Open Graph tags
- Secondary button on show/edit opens the public-page screen. It says **Publish** for drafts and **Public page** when live, so it does not sit next to a Published badge
- Hub line chart **Publications over time** (`widgets.publications.over_time`) before the type chart

### Changed
- Admin section title is **Admin publications**. Screen, widget, catalogue label, and dummy `app_name` stay **Publications**. Keys stay `publications`
- Visible copy says **Publication type**. The `kind` column, param, sort key, and `widgets.publications.by_kind` stay `kind`
- Hub type chart title is **Publication types**

### Upgrade notes
- Bump to `0.3.0`
- Add `recording_studio_publishable ~> 0.2`, install its migrations, register `RecordingStudioPublishable::Publishable`, and mount `RecordingStudioPublishable::Engine` at `/`
- Call `RecordingStudioPublications::FamilyManagement.install!` after any host Publishable authorizer for other types
- Rename `LogoAuthorization` callers to `FamilyAuthorization`. There is no alias
- Scan Publishable views in Tailwind `@source`
- Form posts stay `publication[kind]`. Only the visible label changed

## [0.2.1] - 2026-09-02

Pins, dummy Tailwind scan for system gem paths, real seed logos, and dummy Admin recapture. Catalogue and CRUD stay as in 0.2.0.

### Changed
- Accessible gemspec `~> 0.9`, dummy GitHub tag `v0.9.0` (was `~> 0.6` / `v0.7.0`)
- Attachable gemspec `~> 0.5`, dummy GitHub tag `v0.5.0` (was `~> 0.4` / `0.4.0`)
- Flatpack gemspec `~> 0.1.143`, dummy GitHub tag `v0.1.143` (was `~> 0.1.133` / `v0.1.133`)
- Dummy Tailwind `@source` now also scans `/usr/local/lib/ruby/gems/**/bundler/gems` so Flatpack Grid/Table classes generate on Cloud Agent images that do not use `vendor/bundle`
- Dummy seed logos are a real 128px PNG (`test/dummy/db/seed_assets/publication_logo.png`), not a 1×1 pixel
- Dropped the copied Admin `sections/show` override. Family Admin 2.0.1 already renders Access avatars on the section
- Dummy Admin screens recaptured as public `doc/review/*.png` (hub, inventory, new, show, edit, Attachable add logo, Attachable change logo). Inventory shows the family Screen chart only. There is no compact titles-over-time card.

Left with family Admin / Flatpack, not forked here. Hub New/All publications render as `<button url>` because Admin 2.0.1 `sections/show` passes `url:` and Flatpack Button only links on `href:`. Titles-by-kind integer counts still draw on a 0.0–1.0 axis. Inventory table heading stays “Table data” (Admin `title` has no public hide API). Full chart widgets sit in the first cell of a 3-column Grid.

Recording Studio stays `~> 4.2` / dummy `v4.2.0`. Admin stays `~> 2.0` / dummy `2.0.1`. Root Switchable dummy stays `v0.5.0`. Do not pin unreleased Flatpack `0.1.144`.

### Upgrade notes
- Bump to `0.2.1`
- Hosts bump Accessible to `~> 0.9`, Attachable to `~> 0.5`, and Flatpack to `~> 0.1.143`
- Keep Recording Studio `~> 4.2` and Admin `~> 2.0`

## [0.2.0] - 2026-08-22

Shared publication catalogue and family-admin CRUD. Stacked on 0.1.0 identity/pins. No public Publishable pages.

### Added
- `RecordingStudioPublications::PublicationCatalogue` shared root (`label: "Publications"`, `root: true`, `shared: true`). One per host. Accessible and Attachable are not enabled on this root
- `RecordingStudioPublications::Publication` nested only under that catalogue: required name, required kind (`magazine`, `newspaper`, `journal`, `site`, `broadcast`), optional website, stable key
- One Attachable logo per publication (images only). New has no logo field. Show and edit link to Attachable’s add (`/recording_studio_attachable/recordings/:id/attachments/upload`) and change (`/recording_studio_attachable/attachments/:id`) screens. Persist stays on `import_attachment` / `replace_attachment_file`
- Inventory uses the family Admin Screen template. New is a registered Screen `button` to this gem’s New page. Family table heading stays “Table data” (Admin `title` has no public hide API)
- Accessible enabled on Publication for later per-title grants. No Manage-access UI
- Family admin section `publications`: hub count widget (`type :number`), titles-by-kind bar chart (`type :chart`, `chart_type :bar`), inventory family Screen chart (`type :area`, no compact over-time widget), Screen `filter :search`, Resource `required_role: :admin` for writes, new/show/edit forms. Inventory table is Name, Kind, Website, Actions
- Section Access avatars on the owned AdminRoot via `recording_studio_accessible_avatars` and dummy mount `RecordingStudioAccessible::Engine` at `/admin/access`
- Dummy `AdminRoot` (`shared: false`) with `AllowsAdminSections`, Accessible, and `section :publications`
- Dummy seeds for The Atlantic, The Guardian, Nature, BBC News, and The Verge

### Upgrade notes
- Bump to `0.2.0` and install engine migrations (`create_recording_studio_publications_catalogue`)
- Register `RecordingStudioPublications::PublicationCatalogue` and `RecordingStudioPublications::Publication` in host `recordable_types`
- Add an owned host `AdminRoot` (`shared: false`), enable Accessible on it, and `section :publications`
- Configure `RecordingStudioAdmin` access and site-admin resolvers to that AdminRoot recording
- Mount `recording_studio_admin_for` and `RecordingStudioPublications::Engine`
- Mount `RecordingStudioAccessible::Engine` at `/admin/access` so the publications section can open family Access on the AdminRoot
- Install Attachable migrations and Active Storage if the host does not already have them
- Mount `RecordingStudioAttachable::Engine` and keep logo add/replace on those screens. Do not post `publication[logo]` from New/Edit
- Keep Attachable on its blank layout. Core `default_layout` always renders a back; wrapping Attachable in that layout stacks a second PageNav on add/change
- Bootstrap first-owner admin access on the AdminRoot recording. Do not grant Accessible on the shared catalogue
- Keep `UsesDefaultLayout` plus the html `data-theme="rounded"` head workaround from 0.1.0
- No public Publishable page ships in this version

## [0.1.0] - 2026-08-22

First `recording_studio_publications` identity. This release is rename, dependency pins, and dummy host theme only. It does not ship a publication directory.

### Added
- Gem name `recording_studio_publications` and namespace `RecordingStudioPublications`
- Gemspec pins: `recording_studio ~> 4.2`, `rails ~> 8.1.0`, `recording_studio_accessible ~> 0.6`, `recording_studio_admin ~> 2.0`, `recording_studio_attachable ~> 0.4`, `flat_pack ~> 0.1.133`
- Dummy host copies FlatPack `rounded` onto `<html>` via `layouts/_default_layout_head`, rendered from the core `recording_studio/default_layout_head` hook
- Dummy `recordable_types` includes `RecordingStudioAttachable::Attachment` so the Attachable pin can boot without enabling the capability

### Changed
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.7.0`, Attachable `0.4.0`, Admin `2.0.1`, FlatPack `v0.1.133`
- Dummy authenticated pages stay on `RecordingStudio::UsesDefaultLayout`; Devise keeps its own sign-in layout
- Dummy PageNav no longer puts Sign out or the workspace switcher in the default-layout slot

### Upgrade notes
- Require `recording_studio_publications` and mount `RecordingStudioPublications::Engine`
- Point host or dummy Gemfiles at Recording Studio `v4.2.0`, Accessible `v0.7.0`, Attachable `0.4.0`, Admin `2.0.1`, and FlatPack `v0.1.133`
- Keep `RecordingStudio::UsesDefaultLayout` for authenticated screens. If core puts theme on `body`, render `layouts/_default_layout_head` from the `recording_studio/default_layout_head` hook so `html` gets `data-theme="rounded"`
- Do not put Sign out or a workspace switcher in the default-layout slot or that head partial

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_publications/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.3.0
[0.2.1]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.2.1
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.2.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.1.0
