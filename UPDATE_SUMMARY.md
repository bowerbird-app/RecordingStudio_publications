# Recording Studio Publications 0.1.0

`recording_studio_publications` is the publication-directory addon identity. This release is rename, pins, and dummy theme only.

- Gemspec: `recording_studio ~> 4.2`, `recording_studio_accessible ~> 0.6`, `recording_studio_admin ~> 2.0`, `recording_studio_attachable ~> 0.4`, `flat_pack ~> 0.1.133`
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.7.0`, Attachable `0.4.0`, Admin `2.0.1`, Root Switchable `v0.5.0`, FlatPack `v0.1.133`
- Authenticated dummy layout: `RecordingStudio::UsesDefaultLayout` plus FlatPack CSS/JS
- Dummy copies `data-theme="rounded"` onto `<html>` through `layouts/_default_layout_head`, rendered from the core `recording_studio/default_layout_head` hook
- Hooks and BaseService come from core; do not copy them into this addon
