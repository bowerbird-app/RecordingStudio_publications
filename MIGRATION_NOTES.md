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

## Host layout

Authenticated screens should use `RecordingStudio::UsesDefaultLayout`. Core still puts `data-theme` on `body`. Hosts that need Flatpack Rounded (charcoal) on `:root` should add `app/views/recording_studio/_default_layout_head.html.erb` and set `data-theme="rounded"` on `html`. That partial should load Flatpack CSS only. Do not put Sign out or a workspace switcher there.

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
