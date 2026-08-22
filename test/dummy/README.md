# Dummy App

This Rails app exists to validate the Recording Studio publications gem in a real host application for `recording_studio_publications`.

## What It Covers

- Devise authentication with a seeded admin user and a member without admin access
- `Current.actor` wiring for Recording Studio events
- Host-owned Workspace roots plus a separate owned `AdminRoot`
- Shared `PublicationCatalogue` root (no Accessible, no Attachable) and Publication children
- Attachable enabled on Publication only, for one image logo
- Family admin at `/admin` (`recording_studio_admin_for`, section `:publications`)
- Recording Studio default layout, FlatPack assets, and Tailwind source scanning
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
- `/admin` - publications hub (family RecordingStudioAdmin)
- `/admin/screens/publications` - inventory
- `/recording_studio_publications/admin/publications/new` - new title
- `/recording_studio` - redirects to `/` while the mounted Recording Studio engine stays available under that prefix
- `/users/sign_in` - Devise sign-in page
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` - dummy-only starter pages
- `/up` - Rails health check

## Why This App Exists

Use this app to verify the publications directory before copying host wiring into another app. The host stays thin: AdminRoot, resolvers, seeds, and mounts. Catalogue models and admin definitions live in the gem.

Authenticated pages use Recording Studio's shared default layout. The dummy copies FlatPack `rounded` onto `<html>` through `app/views/layouts/_default_layout_head.html.erb`, rendered from `app/views/recording_studio/_default_layout_head.html.erb`. Those partials do not put Sign out or a workspace switcher in the default-layout slot. Devise sign-in keeps `layouts/application`.

The home page stays a minimal demo surface. Open `/admin` for hub, inventory, new, show, and edit.
