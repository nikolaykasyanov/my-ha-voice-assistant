{
  description = "HA Voice Assistant Dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            colima
            docker
            whisper-cpp
          ];

          shellHook = ''
            echo "Dev environment ready"
          '';
        };

        packages.services = pkgs.symlinkJoin {
          name = "my-ha-voice-assistant-services";
          paths = [ pkgs.colima pkgs.docker pkgs.whisper-cpp ];
        };
      });
}
