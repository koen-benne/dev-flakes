{
  description = "Ready-made templates for easily creating flake-driven environments";

  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";

  outputs = inputs@{ flake-parts, ... }:
    let
      dvt = final.writeShellApplication {
        name = "dvt";
        text = ''
          if [ -z $1 ]; then
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
      };
    in
    flake-parts.lib.mkFlake { inherit inputs dvt; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ build check format update nixpkgs-fmt ];
        });

        packages.default = dvt;
        templates = rec {
          default = empty;

          ddev-drupal = {
            path = ./ddev-drupal;
            description = "DDEV Drupal development environment";
          };
        };
      };
    };
}
