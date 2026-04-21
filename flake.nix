{
  description = "A nix devShell for Haskell Cabal Project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      pre-commit-hooks,
      ...
    }:

    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
      ];
      systems = builtins.attrNames nixpkgs.legacyPackages;
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hook = pre-commit-hooks.lib.${system};
          tools = import "${pre-commit-hooks}/nix/call-tools.nix" pkgs;
          hpkgs = pkgs.haskell.packages.ghc910.override {
            overrides = final: prev: {
              www-server = final.callCabal2nix "www-server" ./src/www { };
            };
          };
        in
        rec {
          packages.www-server = hpkgs.www-server;

          checks.pre-commit-check = hook.run {
            src = self;
            tools = tools;
            # enforce pre-commit-hook
            hooks = {
              cabal-fmt.enable = true;
              fourmolu.enable = true;
              nixfmt.enable = true;
            };
          };

          devShells.default = pkgs.haskell.packages.ghc910.shellFor {
            name = "cabal-project";
            # withHoogle = true; // uncomment to enable Hoogle support
            buildInputs = with pkgs; [
              zlib
              cabal-install
              fourmolu
              hlint
              yazi
              sqlite

              haskell-language-server
              haskellPackages.implicit-hie
              haskellPackages.cabal-fmt
              haskellPackages.ghc-prof-flamegraph
              haskellPackages.eventlog2html
              haskellPackages.ghc-debug-brick

              # build
              watchexec
              ghciwatch
              codespell

              # nix
              nixfmt

              figlet

              (writeShellScriptBin "haskell-language-server-wrapper" ''
                #!/bin/bash
                exec haskell-language-server
              '')
            ];
            packages = p: [ ];

            shellHook = ''
              ${checks.pre-commit-check.shellHook}
              set -o vi
              echo cabal dev env | figlet -f cybermedium
            '';
          };
        };
    };

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
    allow-import-from-derivation = true;
    accept-flake-config = true;
  };
}
