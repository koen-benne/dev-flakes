{
  description = "Ready-made templates for easily creating flake-driven environments";

  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (final: prev:
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
              {
                format = final.writeShellApplication {
                  name = "format";
                  runtimeInputs = with final; [ nixpkgs-fmt ];
                  text = "nixpkgs-fmt '**/*.nix'";
                };

                # only run this locally, as Actions will run out of disk space
                build = final.writeShellApplication {
                  name = "build";
                  text = ''
                    ${getSystem}

                    ${forEachDir ''
                      echo "building ''${dir}"
                      nix build ".#devShells.''${SYSTEM}.default"
                    ''}
                  '';
                };

                check = final.writeShellApplication {
                  name = "check";
                  text = forEachDir ''
                    echo "checking ''${dir}"
                    nix flake check --all-systems --no-build
                  '';
                };

                update = final.writeShellApplication {
                  name = "update";
                  text = forEachDir ''
                    echo "updating ''${dir}"
                    nix flake update
                  '';
                };

                dev-utils = final.symlinkJoin {
                  name = "dev-utils";
                  paths = with final; [
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
                };

              })
          ];
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ build check format update nixpkgs-fmt ];
        };

        packages.default = pkgs.dev-utils;
      };
      flake = {
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
