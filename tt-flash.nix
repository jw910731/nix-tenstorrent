{
  fetchFromGitHub,
  python3Packages,
  cargo,
  rustc,
}:
with python3Packages;
buildPythonApplication (finalAttrs: {
  pname = "tt-flash";
  version = "3.6.2";

  src = fetchFromGitHub {
    owner = "tenstorrent";
    repo = "tt-flash";
    tag = "v${finalAttrs.version}";
    hash = "sha256-nXq+tuci4lQegYk7yBctQ9dL2UHlWVjGkqyavQIW3lQ=";
  };

  nativeBuildInputs = [
    cargo
    rustc
  ];

  propagatedBuildInputs = [
    pyyaml
    requests
    pyluwen
    tabulate
    tt-tools-common
  ];

  dontCheckRuntimeDeps = true;

  pyproject = true;
  build-system = [ setuptools wheel ];
})
