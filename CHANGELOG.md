# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_publications/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.2.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.1.0
