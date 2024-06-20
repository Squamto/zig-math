{
  description = "An empty project that uses Zig.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zls = {
      url = "github:zigtools/zls";
      inputs.zig-overlay.follows = "zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    # Used for shell.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    gitignore,
    ...
  } @ inputs: let
    overlays = [
      # Other overlays
      (final: prev: {
        zigpkgs = inputs.zig-overlay.packages.${prev.system};
        zls-master = inputs.zls.packages.${prev.system}.zls;
      })
    ];

    # Our supported systems are the same supported systems as the Zig binaries
    systems = builtins.attrNames inputs.zig-overlay.packages;
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {inherit overlays system;};
        zigCacheFlags = "--cache-dir $(pwd)/zig-cache --global-cache-dir $(pwd)/.cache";
        buildZigApp = flags: pkgs.stdenvNoCC.mkDerivation {
          pname = "Simple Zig App";
          version = "0.1.0";

          src = gitignore.lib.gitignoreSource ./.;

          nativeBuildInputs = with pkgs; [
            zigpkgs.master
          ];

          dontConfigure = true;
          dontInstall = true;
          doCheck = true;

          buildPhase = ''
            mkdir -p .cache
            zig build install ${zigCacheFlags} ${flags} --prefix $out
          '';

          checkPhase = ''
            zig build test ${zigCacheFlags} ${flags}
          '';

          meta = {
            description = "Simple Zig App";
            mainProgram = "main";
          };
        };
      in rec {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            zigpkgs.master
            zls-master
          ];
        };

        packages.safe = buildZigApp "-Doptimize=ReleaseSafe";
        packages.small = buildZigApp "-Doptimize=ReleaseSmall";
        packages.fast = buildZigApp "-Doptimize=ReleaseFast";
        packages.debug = buildZigApp "";
        packages.default = packages.safe;
      }
    );
}
