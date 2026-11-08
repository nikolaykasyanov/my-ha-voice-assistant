{
  lib,
  stdenvNoCC,
  _7zz,
  fetchurl,
  makeBinaryWrapper,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "omlx-bin";
  version = "0.7.3";

  src = fetchurl {
    url = "https://github.com/jundot/omlx/releases/download/v${finalAttrs.version}/oMLX-${finalAttrs.version}-macos26-27.dmg";
    hash = "sha256-Ks/eQa6sCwItvKgDyhCUN/PMrwwz80FYgVJrmFvuhvI=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    _7zz
    makeBinaryWrapper
  ];

  # Leave the signed app bundle untouched.
  dontFixup = true;

  postInstall = ''
    mkdir -p $out/Applications
    mv *.app $out/Applications/

    makeWrapper $out/Applications/*.app/Contents/MacOS/omlx-cli $out/bin/omlx-cli
  '';

  meta = {
    description = "LLM inference server with continuous batching and SSD caching for Apple Silicon, managed from the macOS menu bar";
    homepage = "https://github.com/jundot/omlx";
    changelog = "https://github.com/jundot/omlx/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "omlx-cli";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
