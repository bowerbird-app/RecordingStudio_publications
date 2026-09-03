===============================================================================

RecordingStudioPublications has been installed successfully!

The engine has been mounted at /recording_studio_publications in your application.

If you use Tailwind CSS:
1. Run 'bin/rails tailwindcss:build' to rebuild your CSS with RecordingStudioPublications styles

To use the engine:
1. Create the owned AdminRoot, register catalogue types, and bootstrap first staff access
2. Mount RecordingStudioAccessible at `/admin/access` for AdminRoot Access, RecordingStudioAttachable so logo add/change uses its screens, and RecordingStudioPublishable at `/`
3. Call `RecordingStudioPublications::FamilyManagement.install!` after any other Publishable authorizer
4. Start your Rails server
5. Visit the family admin publications section (dummy: http://localhost:3000/admin) and a published title at `/publications/:uuid/:slug`

===============================================================================
