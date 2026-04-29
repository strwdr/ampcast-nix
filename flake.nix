{
  description = "Ampcast - patched Nix package for rekkyrosso's ampcast";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          ampcast = pkgs.callPackage ./default.nix { };
        in
        {
          inherit ampcast;
          default = ampcast;
        }
      );

      overlays.default = _final: prev: {
        ampcast = prev.callPackage ./default.nix { };
      };

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.ampcast}/bin/ampcast";
        };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
