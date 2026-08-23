# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 4.x (`~> 4.2` in the gemspec; dummy GitHub tag `v4.2.0`)
- Accessible `~> 0.6` (dummy GitHub tag `v0.7.0`)
- Admin `~> 2.0` (dummy GitHub tag `2.0.1`)
- Attachable `~> 0.4` (dummy GitHub tag `0.4.0`)
- FlatPack `~> 0.1.133` (dummy GitHub tag `v0.1.133`)
- Public RubyGems and GitHub access for dependency installation

## Publications 0.2.0

Hosts need the engine catalogue migration plus, if missing:

- Host `admin_roots` table for the owned AdminRoot
- RecordingStudioAccessible tables (already required by 0.1.0 dummy)
- Active Storage tables
- RecordingStudioAttachable attachments table and indexes

Register `PublicationCatalogue`, `Publication`, `AdminRoot`, and `RecordingStudioAttachable::Attachment` before `RecordingStudio.validate_recordable_declarations!`.

Mount `RecordingStudioAttachable::Engine` so staff add or change a logo on Attachable’s screens after the title exists. Do not post `publication[logo]` from New/Edit.

Do not enable Accessible or Attachable on the shared catalogue root.

## Host layout

Authenticated screens should use `RecordingStudio::UsesDefaultLayout`. Core still puts `data-theme` on `<body>`. FlatPack themes belong on `<html>`. Hosts should add `app/views/recording_studio/_default_layout_head.html.erb` that renders `layouts/default_layout_head`, and `app/views/layouts/_default_layout_head.html.erb` that copies `data-theme="rounded"` onto `document.documentElement` with `javascript_tag nonce: true`. Do not put Sign out or a workspace switcher there.

## Verification

Install both bundles and run the complete gem and dummy app test path:

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

Run the dummy app from its directory for browser verification:

```bash
cd test/dummy
bin/dev
```

Use the [FlatPack repository](https://github.com/bowerbird-app/flatpack) and the live FlatPack demo linked from the top-level README for current component documentation.
