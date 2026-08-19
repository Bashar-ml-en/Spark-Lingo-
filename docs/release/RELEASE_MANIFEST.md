# Release manifest and artifact evidence

Create a manifest only from a clean checkout of an **annotated immutable tag**
after the normal CI workflow is green. The script never creates a tag, builds
an artifact, uploads anything, or reads configuration values.

The tagged CI workflow first attaches a source manifest and deterministic
CycloneDX dependency SBOM. A protected signing workflow must regenerate the
manifest with the signed AAB/IPA and SBOM passed as `--artifact` before the
release owner accepts the final evidence.

```text
node scripts/generate_release_manifest.js \
  --tag v<approved-version> \
  --output release-evidence/release-manifest.json \
  --artifact <signed-android-aab> \
  --artifact <signed-ios-ipa> \
  --artifact <sbom-file>
```

It records the tag/commit, version/build number, ordered migration hashes,
Edge Function source-tree hashes, supplied artifact hashes, and the names (not
values) of build/server configuration variables. Attach the manifest, SBOM,
signed artifact hashes, CI run URL, deployment IDs, and policy approvals to
the protected release record.

The script rejects a dirty checkout, lightweight tag, tag/HEAD mismatch,
absolute/traversal output paths, and missing artifacts. It does not prove that
an artifact is store-signed, that a function is deployed, or that a hosted
secret exists; those require separate evidence in the release tracker.
