# ampcast-nix

Nix flake for [Ampcast](https://github.com/rekkyrosso/ampcast).

Patches upstream to drop the auto-updater and the castlabs Widevine init,
inline `electron-audio-loopback` (its peer dep breaks offline `npm ci`),
and use the system `electron`.

```sh
nix run github:strwdr/ampcast-nix
```

Linux only (`x86_64`, `aarch64`).

When bumping `version` in `default.nix`, the three hashes (`src`, `appDeps`,
`npmDepsHash`) need to be refreshed in that order from build failures.
