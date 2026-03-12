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
            # PostgreSQL management scripts
            (writeScriptBin "pg-start" ''
              #!${runtimeShell}
              export PGDATA="$HOME/.local/share/postgres/$(basename "$PWD")"
              mkdir -p "$(dirname "$PGDATA")"

              # Initialize PostgreSQL if not already initialized
              if [ ! -d "$PGDATA" ]; then
                echo "Initializing PostgreSQL data directory at $PGDATA..."
                initdb --auth=trust --no-locale --encoding=UTF8

                # Configure to use local socket directory
                echo "unix_socket_directories = '$PGDATA'" >> "$PGDATA/postgresql.conf"
              fi

              # Check if PostgreSQL is already running
              if pg_ctl status > /dev/null 2>&1; then
                echo "PostgreSQL is already running"
              else
                echo "Starting PostgreSQL..."
                pg_ctl start -l "$PGDATA/logfile"
                echo "PostgreSQL started successfully"
              fi
            '')

            (writeScriptBin "pg-stop" ''
              #!${runtimeShell}
              export PGDATA="$HOME/.local/share/postgres/$(basename "$PWD")"

              if pg_ctl status > /dev/null 2>&1; then
                echo "Stopping PostgreSQL..."
                pg_ctl stop -m fast
                echo "PostgreSQL stopped successfully"
              else
                echo "PostgreSQL is not running"
              fi
            '')

            (writeScriptBin "pg-status" ''
              #!${runtimeShell}
              export PGDATA="$HOME/.local/share/postgres/$(basename "$PWD")"

              if [ ! -d "$PGDATA" ]; then
                echo "PostgreSQL has not been initialized yet"
                echo "Run 'pg-start' to initialize and start PostgreSQL"
                exit 1
              fi

              if pg_ctl status > /dev/null 2>&1; then
                echo "PostgreSQL is running"
                pg_ctl status
              else
                echo "PostgreSQL is not running"
                echo "Run 'pg-start' to start PostgreSQL"
                exit 1
              fi
            '')

            # Node.js and Yarn
            nodejs_20
            yarn-berry

            ruby-3
            bundler # 2.7.2
            docker
            postgresql_17
            libyaml # NOTE: for psych gem
            openssl
            redis
            awscli2
          ];
        };
    });
}

