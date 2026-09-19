{
  description = "Flobo Display: cross-platform visual development tool and SCPI instrument controller (fork of EEZ Studio)";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    npmlock2nix = {
      url = "github:ilkecan/npmlock2nix/";
      flake = false;
    };
    nix-utils.url = "git+https://git.sr.ht/~ilkecan/nix-utils";
  };

  outputs = { self, nixpkgs, flake-utils, npmlock2nix, ... }@inputs:
    let
      inherit (builtins)
        attrNames
        attrValues
      ;
      inherit (nixpkgs.lib)
        getAttrs
      ;
      inherit (flake-utils.lib)
        defaultSystems
        eachSystem
      ;
      nix-filter = inputs.nix-filter.lib;
      nix-utils = inputs.nix-utils.lib;
      inherit (nix-utils)
        createOverlays
        getUnstableVersion
      ;

      supportedSystems = defaultSystems;
      commonArgs = {
        version = getUnstableVersion self.lastModifiedDate;
        homepage = "https://github.com/cristianflobo/flobo-display";
        downloadPage = "https://github.com/cristianflobo/flobo-display/releases";
        changelog = null;
        maintainers = [
          {
            name = "ilkecan bozdogan";
            email = "ilkecan@protonmail.com";
            github = "ilkecan";
            githubId = "40234257";
          }
        ];
        platforms = supportedSystems;
      };

      derivations = {
        flobo-display = import ./nix/flobo-display.nix commonArgs;
      };
    in
    {
      overlays = createOverlays derivations {
        inherit
          nix-filter
          nix-utils
        ;
      };
      overlay = self.overlays.flobo-display;
    } // eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = attrValues self.overlays ++ [
            (final: prev: { npmlock2nix = import npmlock2nix { pkgs = prev; }; })
          ];
        };

        packageNames = attrNames derivations;
      in
      rec {
        checks = packages;

        packages = getAttrs packageNames pkgs;
        defaultPackage = packages.flobo-display;

        hydraJobs = {
          build = packages;
        };

        devShell =
          let
            packageList = attrValues packages;
          in
          pkgs.mkShell {
            packages = packageList;

            shellHook = ''
              $(${defaultPackage.preConfigure}) || true
              export PATH=./node_modules/.bin:$PATH
            '';
          };
      });
}
