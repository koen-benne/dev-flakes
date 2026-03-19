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
            # PostgreSQL Docker management scripts
            (writeScriptBin "pg-start" ''
              #!${runtimeShell}
              PORT="''${RAILS_DATABASE_PORT:-5432}"
              BASE_NAME="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]-' '-' | sed 's/^-*//' | sed 's/-*$//')"
              PROJECT_NAME="$BASE_NAME-postgres-$PORT"
              
              # Create docker-compose.yml content
              COMPOSE_FILE=$(cat <<EOF
              services:
                db:
                  image: postgres:17
                  container_name: $PROJECT_NAME
                  environment:
                    - POSTGRES_HOST_AUTH_METHOD=trust
                    - POSTGRES_USER=''${USER:-postgres}
                  ports:
                    - "$PORT:5432"
                  volumes:
                    - postgres_data:/var/lib/postgresql/data

              volumes:
                postgres_data:
              EOF
              )
              
              # Check if container is already running
              if docker ps --format '{{.Names}}' | grep -q "^$PROJECT_NAME$"; then
                echo "PostgreSQL container is already running on port $PORT"
              else
                echo "Starting PostgreSQL container on port $PORT..."
                echo "$COMPOSE_FILE" | docker compose -p "$PROJECT_NAME" -f - up -d
                echo "PostgreSQL started successfully on port $PORT"
              fi
            '')

            (writeScriptBin "pg-stop" ''
              #!${runtimeShell}
              PORT="''${RAILS_DATABASE_PORT:-5432}"
              BASE_NAME="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]-' '-' | sed 's/^-*//' | sed 's/-*$//')"
              PROJECT_NAME="$BASE_NAME-postgres-$PORT"
              
              if docker ps --format '{{.Names}}' | grep -q "^$PROJECT_NAME$"; then
                echo "Stopping PostgreSQL container on port $PORT..."
                docker stop "$PROJECT_NAME"
                echo "PostgreSQL stopped successfully"
              else
                echo "PostgreSQL container on port $PORT is not running"
              fi
            '')

            (writeScriptBin "pg-status" ''
              #!${runtimeShell}
              PORT="''${RAILS_DATABASE_PORT:-5432}"
              BASE_NAME="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]-' '-' | sed 's/^-*//' | sed 's/-*$//')"
              PROJECT_NAME="$BASE_NAME-postgres-$PORT"
              
              if docker ps --format '{{.Names}}' | grep -q "^$PROJECT_NAME$"; then
                echo "PostgreSQL container is running on port $PORT"
                docker ps --filter "name=$PROJECT_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
              else
                echo "PostgreSQL container on port $PORT is not running"
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
            docker-compose
            postgresql_17 # for psql client tools
            libyaml # NOTE: for psych gem
            openssl
            redis
            awscli2
          ];
        };
    });
}

