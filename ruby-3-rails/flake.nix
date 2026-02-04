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
      };
    in {
      devShell = with pkgs;
        mkShell {
          buildInputs = [
            # Node.js and Yarn
            nodejs_20
            yarn

            ruby-3
            bundler # 2.7.2
            docker
            postgresql_17
            libyaml # NOTE: for psych gem
          ];
        };
    });
}

