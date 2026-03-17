{
  version,
  stdenv,
  autoPatchelfHook,
  fetchurl,
  runCommand,
  expat,
  ncurses,
  isl_0_23,
  mpfr,
  libmpc,
  xz,
  zstd,
}:
let 
  arch =
    {
      aarch64-linux = "aarch64";
      x86_64-linux = "x86_64";
    }
    ."${stdenv.hostPlatform.system}" or (throw "SFPI does not support ${stdenv.hostPlatform.system}");
in
runCommand "sfpi-${version}"
{
  inherit version;

  postPatch = ''
    touch runtime/sfpi_${version}_${arch}_nixos.txz
  '';

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    expat
    ncurses
    isl_0_23
    mpfr
    libmpc
    xz
    zstd
  ];

  src =
    {
      aarch64-linux = fetchurl {
        url = "https://github.com/tenstorrent/sfpi/releases/download/${version}/sfpi_${version}_aarch64_debian.txz";
        hash = "sha256-pIqsIzcAJUElPQJsUwOJa3LDaUMwlgfgyWuWQwFzycM=";
      };
      x86_64-linux = fetchurl {
        url = "https://github.com/tenstorrent/sfpi/releases/download/${version}/sfpi_${version}_x86_64_debian.txz";
        hash = "sha256-4j8KtZT+wHpIwnybnjN5FMruS7R9fVpO/eEIdgaoSHg=";
      };
    }
    ."${stdenv.hostPlatform.system}" or (throw "SFPI does not support ${stdenv.hostPlatform.system}");
}
''
  runPhase unpackPhase
  cp -r ../"$sourceRoot" "$out"
  runPhase fixupPhase
''