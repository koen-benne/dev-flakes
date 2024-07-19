{
  description = "Flake for DDEV Drupal projects";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            (writeScriptBin "setup-site" ''
            #!${runtimeShell}
            if [ -z "$1" ]; then
              echo "Please specify a site name"
              exit 1
            fi

            platform db:dump -f db.sql -e "." --schema $1

            ddev import-db --database=$1 < db.sql
            rm db.sql

            ddev drush cim -y -l $1
            '')
            phpPackages.composer
            ddev
            colima
            vscode-extensions.xdebug.php-debug
            platformsh
          ];
        };
      };
    };
}