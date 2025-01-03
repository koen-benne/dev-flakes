{
  description = "Flake for Aviko backend project. Based on ddev-drupal flake.";

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
            (writeScriptBin "setup-site" ''
              #!${runtimeShell}
              if [ -z "$1" ]; then
                echo "Please specify a site name"
                exit 1
              fi

              platform db:dump -f db.sql -e "." --schema $1

              ddev import-db --database=$1 --file=./db.sql
              rm db.sql

              ddev drush cim -y -l $1; true
              ddev drush cim -y -l $1; true
            '')
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
            platformsh
            nodePackages.intelephense
          ];
        };
      };
    };
}
