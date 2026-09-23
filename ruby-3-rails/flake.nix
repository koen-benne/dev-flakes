{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
            nodejs
            # Install yarn via corepack enable

            ruby-3
            bundler # 2.7.2
            docker
            docker-compose
            postgresql_17 # for psql client tools
            redis # for redis-cli client tools
            libyaml # NOTE: for psych gem
            openssl
            awscli2
          ];
        };
    });
}

