# ampcast-nix

Nix flake for [Ampcast](https://github.com/rekkyrosso/ampcast), an Electron
music player for streaming services and personal media servers.

Patches upstream to drop the auto-updater and the castlabs Widevine init,
inline `electron-audio-loopback` (its peer dep breaks offline `npm ci`),
and use the system `electron`.

```sh
nix run github:strwdr/ampcast-nix
```

As a flake input:

```nix
{
  inputs.ampcast.url = "github:strwdr/ampcast-nix";
  inputs.ampcast.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { nixpkgs, ampcast, ... }: {
    # environment.systemPackages = [ ampcast.packages.${system}.default ];
    # or via overlay: nixpkgs.overlays = [ ampcast.overlays.default ];
  };
}
```
