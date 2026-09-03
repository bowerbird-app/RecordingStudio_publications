RecordingStudioPublications install complete.

Next steps:

1. Review config/initializers/recording_studio_publications.rb and set any required options.
2. If you use environment-specific settings, create config/recording_studio_publications.yml.
3. Install the engine migrations with `bin/rails generate recording_studio_publications:migrations`.
4. Apply the migrations with `bin/rails db:migrate`.
5. Install Accessible, Admin, Attachable, Publishable, and Active Storage migrations if this host does not already have them.
6. Register `RecordingStudioPublications::PublicationCatalogue`, `RecordingStudioPublications::Publication`, host `AdminRoot`, `RecordingStudioAttachable::Attachment`, and `RecordingStudioPublishable::Publishable` in `RecordingStudio.configure`.
7. Create an owned `AdminRoot` (`shared: false`), enable Accessible on it, and `section :publications`. Point RecordingStudioAdmin resolvers at that recording and bootstrap first-owner admin access.
8. Run `bin/rails tailwindcss:build` if you use Tailwind CSS. Scan RecordingStudioAdmin, Attachable, and Publishable views as well as this engine.
9. Mount routes are added at the configured mount path. Also mount `recording_studio_admin_for`, `RecordingStudioAccessible::Engine` at `/admin/access` (AdminRoot Access UI), `RecordingStudioAttachable::Engine` so logo add/change uses Attachable’s screens, and `RecordingStudioPublishable::Engine` at `/`. Call `RecordingStudioPublications::FamilyManagement.install!` after any other Publishable authorizer. Adjust auth, layout, and current actor integration to match your host app.
10. Keep strict recordable declarations enabled and add `recording_studio_recordable(...)` to every configured recordable before running `RecordingStudio.validate_recordable_declarations!`.
11. Do not enable Accessible, Attachable, or Publishable on the shared Publications catalogue. Rename `LogoAuthorization` to `FamilyAuthorization`. There is no alias.