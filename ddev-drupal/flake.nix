# TODO: Make this more modular so that other flakes can extend it without duplicate code.
{
  description = "Flake for DDEV Drupal projects";

  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  # QEMU causes issues if too old, revert back to flakehub later
  # inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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
        # Allow unfree
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        devShells.default = pkgs.mkShell {
          # shellHook = ''
          #   colima start --cpu 4 --memory 8 --disk 100
          # '';
          nativeBuildInputs = with pkgs; [
            (writeScriptBin "colimastart" ''
              #!${runtimeShell}
              colima start --cpu 4 --memory 8 --disk 120
            '')
            phpPackages.composer
            ddev
            mkcert
            docker
            colima
            vscode-extensions.xdebug.php-debug
            nodePackages.intelephense
          ];
        };
      };
    };
}
