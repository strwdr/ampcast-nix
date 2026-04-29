# ampcast-nix

A Nix flake packaging [rekkyrosso/ampcast](https://github.com/rekkyrosso/ampcast)
(Electron music player for streaming services and personal media servers) with
a few patches that make it build cleanly under `nixpkgs`:

- swaps `electron-audio-loopback` for an inline stub (avoids an offline
  `npm ci` registry lookup caused by its `electron@>=31` peer);
- drops the castlabs Widevine `components` import/call and the
  `electron-updater` / `electron-log` auto-updater path;
- pins the system `electron` instead of downloading one;
- extends the bundled Google Fonts list.

The actual derivation lives in [`default.nix`](./default.nix); `flake.nix` is
just a thin wrapper exposing it as a flake output.

## Usage

Add it as an input in your own flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ampcast.url  = "github:<you>/ampcast-nix";
    ampcast.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ampcast, ... }: {
    # NixOS
    nixosConfigurations.mybox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [ ampcast.packages.${pkgs.system}.default ];
        })
      ];
    };

    # Home Manager
    # home.packages = [ ampcast.packages.${pkgs.system}.default ];
  };
}
```

Or pull it in via the overlay:

```nix
nixpkgs.overlays = [ ampcast.overlays.default ];
# then: pkgs.ampcast
```

## One-shot

```sh
nix run github:<you>/ampcast-nix
nix build github:<you>/ampcast-nix
```

## Supported systems

`x86_64-linux`, `aarch64-linux` (upstream is Linux-only).

## Updating

When bumping `version` in `default.nix`, refresh all three hashes in order —
each one will fail with the correct expected hash on first build:

1. `src` (`fetchFromGitHub`)
2. `appDeps` (`fetchNpmDeps` for `app/`)
3. `npmDepsHash` (top-level `buildNpmPackage`)
