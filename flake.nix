{
  description = "HA Voice Assistant Dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.services = pkgs.symlinkJoin {
          name = "my-ha-voice-assistant-services";
          paths = [ pkgs.colima pkgs.docker ];
        };
      });
}
