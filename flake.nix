{
  description = "Ready-made templates for easily creating flake-driven environments";

  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";

  outputs = inputs@{ flake-parts, ... }:
    let
      getSystem = "SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')";
      forEachDir = exec: ''
        for dir in */; do
          (
            cd "''${dir}"

            ${exec}
          )
        done
      '';
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [
        # This allows for creating overlays easily.
        inputs.flake-parts.flakeModules.easyOverlay
      ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Free overlay with easyOverlay module.
        overlayAttrs = {
          # inherit (config.packages) [name]
          dev-utils = config.packages.default;
        };
        # Devshell packages including some custom packages
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            (writeShellApplication {
              name = "format";
              runtimeInputs = with pkgs; [ nixfmt ];
              text = "nixfmt '**/*.nix'";
            })
            # only run this locally, as Actions will run out of disk space
            (writeShellApplication {
              name = "build";
              text = ''
                ${getSystem}

                ${forEachDir ''
                  echo "building ''${dir}"
                  nix build ".#devShells.''${SYSTEM}.default"
                ''}
              '';
            })
            (writeShellApplication {
              name = "check";
              text = forEachDir ''
                echo "checking ''${dir}"
                nix flake check --all-systems --no-build
              '';
            })
            (writeShellApplication {
              name = "update";
              text = forEachDir ''
                echo "updating ''${dir}"
                nix flake update
              '';
            })
            nixfmt
          ];
        };

        # Default package. Also used in the overlay
        packages.default = (
          pkgs.symlinkJoin {
            name = "dev-utils";
            paths = with pkgs; [
              (writeShellApplication {
                name = "dvt";
                text = ''
                  #!${runtimeShell}
                  if [ -z "$1" ]; then
                    echo "no template specified"
                    exit 1
                  fi

                  TEMPLATE=$1

                  nix \
                    --experimental-features 'nix-command flakes' \
                    flake init \
                    --template \
                    "github:the-nix-way/dev-templates#''${TEMPLATE}"
                '';
              })
              (writeShellApplication {
                name = "dvd";
                text = ''
                  #!${runtimeShell}
                  if [ -z "$1" ]; then
                    echo "no flake specified"
                    exit 1
                  fi
                  echo "use flake \"github:koen-benne/dev-flakes?dir=$1\"" >> .envrc
                  direnv allow
                '';
              })
            ];
          });
      };
      flake = {
        # Templates are defined here
        templates = rec {
          default = empty;

          empty = {
            path = ./empty;
            description = "Empty dev template that you can customize at will";
          };

          ddev-drupal = {
            path = ./ddev-drupal;
            description = "DDEV Drupal development environment";
          };
        };
      };
    };
}
