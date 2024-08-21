{
  description = "Flake for node16 projects";

  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2305.*.tar.gz";

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        # Alter config to allow some packages
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.permittedInsecurePackages = [
            "nodejs-14.21.3"
            "openssl-1.1.1w"
          ];
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            nodejs_14
            (yarn.override { nodejs = pkgs.nodejs_14; })
          ];
        };
      };
    };
}
