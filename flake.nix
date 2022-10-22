{
  description = "A very basic flake";
  inputs = {
    nixpkgs-upstream.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    haskell-nix.url = "/home/mangoiv/Work/iog/haskell.nix/";
    nixpkgs.follows = "haskell-nix/nixpkgs";
    haskell-nix-extra-hackage = {
      url = "github:mlabs-haskell/haskell-nix-extra-hackage";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.haskell-nix.follows = "haskell-nix";
    };
    iohk-nix = {
      url = "github:input-output-hk/iohk-nix";
      flake = false;
    };
  };
  outputs =
    inputs@{ self
    , nixpkgs
    , nixpkgs-upstream
    , haskell-nix
    , haskell-nix-extra-hackage
    , iohk-nix
    , ...
    }:
    let
      plainNixpkgsFor = system: import nixpkgs-upstream { inherit system; };
      nixpkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ haskell-nix.overlay ];
      };

      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      perSystem = nixpkgs.lib.genAttrs supportedSystems;

      ghcVersion = "8107";
      compiler-nix-name = "ghc" + ghcVersion;

      projectFor = system:
        let
          pkgs = nixpkgsFor system;
          plainPkgs = plainNixpkgsFor system;
          hackages = haskell-nix-extra-hackage.mkHackagesFor system compiler-nix-name 
          [
            "${./bla}"
          ];
        in
        pkgs.haskell-nix.cabalProject' {
          src = ./blup;
          inherit compiler-nix-name;
          inherit (hackages) extra-hackages extra-hackage-tarballs modules;

          shell = {
            withHoogle = false;
            exactDeps = true;

            nativeBuildInputs = [
              plainPkgs.cabal-install
            ];
          };
        };
    in {
      project = perSystem projectFor;
      flake = perSystem (system: self.project.${system}.flake { });

      packages = perSystem (system:
        self.flake.${system}.packages
      );

      devShells = perSystem (system: 
      {
        default = self.flake.${system}.devShell;
      }
      );

    };
}
