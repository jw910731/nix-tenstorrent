# UNOFFICIAL nix flake for tenstorrent software stack

# Environment Variables
`TT_METAL_RUNTIME_ROOT` environment variable is mandatory for tt-metal and ttnn to work.
Snippet like the following can be used.

```
TT_METAL_RUNTIME_ROOT = "${pkgs.tt-metal}/libexec/tt-metalium";
```

# TTNN Python support
Use something like this to create a python environment with ttnn

```nix
(pkgs.python3.withPackages (
    ps: with ps; [
    (ps.toPythonModule tt-metal)
    ]
)) 
```

The `tt-metal` here can be `pkgs.tt-metal` when overlay is used.