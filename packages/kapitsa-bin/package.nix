{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kapitsa-bin";
  version = "0.2.31";

  src = fetchurl {
    url = "https://github.com/nace-ai/kapitsa/releases/download/v${finalAttrs.version}/kapitsa-${finalAttrs.version}-darwin-arm64.tar.gz";
    hash = "sha256-qrwDRLLLeEni4IKMP8uEJaPdLeQEDEj9h9t/tHFL3ug=";
  };

  # Leave the prebuilt Mach-O binaries untouched (they only link system
  # libraries), and keep the `#!/usr/bin/env python3` shebang of
  # kapitsa-drex-pointer as shipped.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 kapitsa $out/bin/kapitsa
    install -Dm755 kapitsa-systemone $out/bin/kapitsa-systemone
    install -Dm755 kapitsa-drex-pointer $out/bin/kapitsa-drex-pointer

    # `kapitsa bench compare` looks for its harness in share/kapitsa/bench.
    mkdir -p $out/share/kapitsa
    cp -r bench $out/share/kapitsa/bench
    install -Dm644 LICENSE THIRD_PARTY_NOTICES -t $out/share/kapitsa

    runHook postInstall
  '';

  meta = {
    description = "Fast local Qwen and Nemotron inference for Apple Silicon, with an OpenAI- and Anthropic-compatible server";
    homepage = "https://github.com/nace-ai/kapitsa";
    changelog = "https://github.com/nace-ai/kapitsa/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "kapitsa";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
