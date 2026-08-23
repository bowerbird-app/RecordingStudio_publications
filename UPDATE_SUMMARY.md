# Recording Studio Publications 0.2.0

`recording_studio_publications` is a grant-less publication directory for Recording Studio 4.x hosts.

- Shared `PublicationCatalogue` root (`label: "Publications"`). Accessible and Attachable stay off that root
- `Publication` children: name, key, kind, website, one Attachable image logo added after the title exists
- Logo add/change uses Attachable screens, not a FileInput on New/Edit
- Family admin section `publications` gated by host-owned `AdminRoot` + Resource `required_role: :admin`
- Dummy host stays thin: AdminRoot, resolvers, seeds, mounts. No public Publishable page
- Pins unchanged from 0.1.0: Recording Studio `v4.2.0`, Accessible `v0.7.0`, Attachable `0.4.0`, Admin `2.0.1`, FlatPack `v0.1.133`
- Authenticated dummy layout: `RecordingStudio::UsesDefaultLayout` plus html `data-theme="rounded"` head workaround
