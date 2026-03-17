# Highly based on https://github.com/NixOS/nixpkgs/blob/nixos-25.11/pkgs/by-name/tt/tt-metal/package.nix
{
  buildWithSymbol ? false,
  enablePython ? true,
  lib,
  stdenv,
  callPackage,
  fetchFromGitHub,
  fetchurl,
  python3Packages,
  unixtools,
  boost,
  capstone,
  cmake,
  hwloc,
  mpi,
  ninja,
  numactl,
  pkg-config,
  python3,
}:
let
  arch =
    {
      aarch64-linux = "aarch64";
      x86_64-linux = "x86_64";
    }
    ."${stdenv.hostPlatform.system}" or (throw "SFPI does not support ${stdenv.hostPlatform.system}");
  sfpi-version = "7.17.0";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "tt-metal";
  version = "0.66.0";

  src = fetchFromGitHub {
    owner = "tenstorrent";
    repo = "tt-metal";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    leaveDotGit = true;
    hash = "sha256-K51Nkb9YEqSWdyW9LULmqN8VxDQv3iAKd0hM0CLeEpA=";
    postFetch = ''
      git -C "$out" rev-parse --short=10 HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  cpm = fetchurl {
    url = "https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.2/CPM.cmake";
    hash = "sha256-yM3DLAOBZTjOInge1ylk3IZLKjSjENO3EEgSpcotg10=";
  };

  dontStrip = buildWithSymbol;

  buildInputs = [
    numactl
    boost
    mpi
    hwloc
    capstone
  ];
  propagatedBuildInputs = lib.optionals enablePython [
    python3Packages.numpy
    python3Packages.loguru
    python3Packages.networkx
    python3Packages.graphviz
    python3Packages.pyyaml
    python3Packages.click
    python3Packages.pandas
    python3Packages.seaborn
  ];

  postUnpack = ''
    mkdir -p "$sourceRoot/runtime"
    ln -s "$sfpi" "$sourceRoot/runtime/sfpi"
    touch $sourceRoot/runtime/sfpi_${sfpi-version}_${arch}_unknown.txz
  '';

  cmakeFlags = [
    (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    (lib.cmakeBool "CPM_USE_LOCAL_PACKAGES" true)
    (lib.cmakeBool "ENABLE_FAKE_KERNELS_TARGET" true)
    (lib.cmakeFeature "VERSION_NUMERIC" "0.66.0")
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.10")
    (lib.cmakeFeature "BUILD_SHARED_LIBS" "ON")
    (lib.cmakeFeature "TT_INSTALL" "ON")
    (lib.cmakeFeature "TT_UNITY_BUILDS" "ON")
    (lib.cmakeFeature "TT_ENABLE_LIGHT_METAL_TRACE" "ON")
  ]
  ++ (lib.optionals enablePython [ (lib.cmakeFeature "WITH_PYTHON_BINDINGS" "ON") ])
  ++ (lib.optionals buildWithSymbol [ (lib.cmakeFeature "CMAKE_BUILD_TYPE" "RelWithDebInfo") ]);

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    python3
    unixtools.xxd
    python3Packages.pip
    python3Packages.wheel
    python3Packages.setuptools
    python3Packages.setuptools-scm
  ];

  sfpi = callPackage ./sfpi.nix { version = sfpi-version; };

  # CMake install fails because "$out/include/tt-logger" tree does not exist.
  preInstall = ''
    mkdir -p $out/include
    cp -r ../build/_deps/tt-logger-src/include/tt-logger $out/include/tt-logger
  '';

  prePatch = ''
    patchShebangs --build tt_metal
    patchShebangs --build scripts
  '';

  # Prevent unused function
  postPatch = ''
    cp $cpm cmake/CPM.cmake
    cp $cpm tt_metal/third_party/umd/cmake/CPM.cmake
    sed -i 's|ParseGitDescribe()||g' CMakeLists.txt
  '';

  patches = [
    ./patches/prevent_unused_var.patch
    ./patches/picosha2.patch
  ]
  ++ (lib.optionals enablePython [ ./patches/setup-py.patch ]);

  # Download all dependencies for CPM
  preConfigure = ''
    prependToVar cmakeFlags "-DVERSION_HASH:STRING=$(cat COMMIT)"
    mkdir -p build/_deps
    ${lib.concatMapAttrsStringSep "\n"
      (name: src: "cp -r --no-preserve=ownership,mode ${src} build/_deps/${name}-src")
      (
        import ./deps.nix {
          inherit fetchFromGitHub;
        }
      )
    }
    cp $cpm build/_deps/tt-logger-src/cmake/CPM.cmake
  '';

  postInstall = lib.concatStringsSep "\n" (lib.optional enablePython ''
    pushd $NIX_BUILD_TOP/$sourceRoot
    env TT_NIX_BUILD_DIR=$out TT_NIX_RUNTIME_DIR=$out/libexec/tt-metalium python -m pip install . --no-index --no-warn-script-location --prefix="$out" --no-cache --no-deps --no-clean --no-build-isolation
    popd
  '');

  enableParallelBuilding = true;

  # Fixes the parallel hook crashing in the fixupPhase with no error.
  noAuditTmpdir = true;

  meta = {
    description = "TT-NN operator library, and TT-Metalium low level kernel programming model";
    homepage = "https://github.com/tenstorrent/tt-metal";
    license = lib.licenses.asl20;
    maintainers = [
      {
        name = "Jerry Wu";
        email = "jw910731@gmail.com";
        matrix = "@jw910731:matrix.org";
        github = "jw910731";
        githubId = 16759389;
        keys = [ { fingerprint = "A988 C648 FFB9 E3AF FB6B  8089 4057 7344 00ED A14E"; } ];
      }
    ];
    platforms = lib.platforms.linux;
  };
})
