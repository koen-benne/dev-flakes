{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    nixpkgs-ruby,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [nixpkgs-ruby.overlays.default];
        config.permittedInsecurePackages = [
          "openssl-1.1.1w"
        ];
      };
    in {
      devShell = with pkgs;
        mkShell {
          buildInputs = [
            # Node.js and Yarn
            nodejs_20
            yarn

            pkgs."ruby-3.0.5"
            bundler
            docker
            postgresql_17
            libyaml # NOTE: for psych gem
          ];
        };
    });
}

