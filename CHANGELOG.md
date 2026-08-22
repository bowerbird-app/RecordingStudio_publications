# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-08-22

First `recording_studio_publications` identity. This release is rename, dependency pins, and dummy host theme only. It does not ship a publication directory.

### Added
- Gem name `recording_studio_publications` and namespace `RecordingStudioPublications`
- Gemspec pins: `recording_studio ~> 4.2`, `rails ~> 8.1.0`, `recording_studio_accessible ~> 0.6`, `recording_studio_admin ~> 2.0`, `recording_studio_attachable ~> 0.4`, `flat_pack ~> 0.1.133`
- Dummy host `recording_studio/_default_layout_head` hook so Flatpack `data-theme="rounded"` lands on `html`
- Dummy `recordable_types` includes `RecordingStudioAttachable::Attachment` so the Attachable pin can boot without enabling the capability

### Changed
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.7.0`, Attachable `0.4.0`, Admin `2.0.1`, FlatPack `v0.1.133`
- Dummy authenticated pages stay on `RecordingStudio::UsesDefaultLayout`; Devise keeps its own sign-in layout
- Dummy PageNav no longer puts Sign out or the workspace switcher in the default-layout slot

### Upgrade notes
- Require `recording_studio_publications` and mount `RecordingStudioPublications::Engine`
- Point host or dummy Gemfiles at Recording Studio `v4.2.0`, Accessible `v0.7.0`, Attachable `0.4.0`, Admin `2.0.1`, and FlatPack `v0.1.133`
- Keep `RecordingStudio::UsesDefaultLayout` for authenticated screens. If core puts theme on `body`, add `app/views/recording_studio/_default_layout_head.html.erb` so `html` gets `data-theme="rounded"`
- Do not put Sign out or a workspace switcher in the default-layout slot or that head partial

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_publications/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.1.0
