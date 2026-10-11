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
        whisperModelName = "ggml-large-v3-turbo-q5_0.bin";
        whisperModelHash = "sha256-OUIhcJzVrR9AxG5gMcphvOiJMebgiMGIKUxtWlX/p+I=";

        whisperModel = pkgs.fetchurl {
          url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${whisperModelName}";
          hash = whisperModelHash;
        };
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
          postBuild = ''
            mkdir -p $out/share/whisper
            ln -s ${whisperModel} $out/share/whisper/${whisperModelName}
          '';
        };
      });
}
