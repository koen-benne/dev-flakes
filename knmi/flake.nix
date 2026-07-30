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
      pkgs = nixpkgs.legacyPackages.${system};
      ruby = nixpkgs-ruby.packages.${system}."ruby-3.4.8";
    in {
      devShell = with pkgs;
        mkShell {
          buildInputs = [
            yarn-berry

            ruby
            bundler # 2.7.2
            docker
            docker-compose
            postgresql_18 # for psql client tools
            libmysqlclient
            libyaml # NOTE: for psych gem
            openssl
            awscli2
            vips
            imagemagick

            pkg-config
            libxml2
            libxslt
            gcc
          ];
          env.LD_LIBRARY_PATH = "${pkgs.vips.out}/lib:${pkgs.imagemagick}/lib";
          env.LDFLAGS = "-L${libxml2.out}/lib -L${libxslt.out}/lib";
          env.CPPFLAGS = "-I${libxml2.dev}/include -I${libxslt.dev}/include";
        };
    });
}


