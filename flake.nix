{
  nixConfig = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://nix.cache.vapor.systems"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "nix.cache.vapor.systems-1:OjV+eZuOK+im1n8tuwHdT+9hkQVoJORdX96FvWcMABk="
    ];
  };

  inputs = {
    utils.url = "github:numtide/flake-utils";
    # nixpkgs.url = "github:NixOS/nixpkgs?rev=997d9f10ad1e4ed8f2836ad3eeb0bbfa3b43c2e4";
    nixpkgs.url = "github:NixOS/nixpkgs";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "utils";
      };
    };
  };

  outputs = { self, nixpkgs, utils, poetry2nix }:
    with nixpkgs.lib;
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };

        inherit (poetry2nix.legacyPackages.${system})
          mkPoetryApplication defaultPoetryOverrides;

        overrides = import ./overrides.nix {
          inherit pkgs;
          inherit (nixpkgs) lib;
        };
      in {

        devShells.default = let
          poetryEnv = pkgs.poetry2nix.mkPoetryEnv {
            projectDir = ./.;
            python = pkgs.python310;
            poetrylock = ./poetry.lock;
            preferWheels = true;
            overrides = [ overrides defaultPoetryOverrides ];
          };
        in pkgs.mkShell { buildInputs = with pkgs; [ poetryEnv poetry ]; };
      });
}
