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
            # Combined Docker management script for PostgreSQL and Redis
            (writeScriptBin "docker-start" ''
              #!${runtimeShell}
              PG_PORT="''${RAILS_DATABASE_PORT:-''${DB_PORT:-5432}}"
              REDIS_PORT="''${REDIS_PORT:-6379}"
              BASE_NAME="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]-' '-' | sed 's/^-*//' | sed 's/-*$//')"
              PROJECT_NAME="$BASE_NAME"

              # Create docker-compose.yml content
              COMPOSE_FILE=$(cat <<EOF
              services:
                db:
                  image: postgres:17
                  container_name: $PROJECT_NAME-postgres-$PG_PORT
                  environment:
                    - POSTGRES_HOST_AUTH_METHOD=trust
                    - POSTGRES_USER=''${USER:-postgres}
                  ports:
                    - "$PG_PORT:5432"
                  volumes:
                    - postgres_data:/var/lib/postgresql/data

                redis:
                  image: redis:7
                  container_name: $PROJECT_NAME-redis-$REDIS_PORT
                  ports:
                    - "$REDIS_PORT:6379"
                  volumes:
                    - redis_data:/data

              volumes:
                postgres_data:
                redis_data:
              EOF
              )

              echo "Starting PostgreSQL on port $PG_PORT and Redis on port $REDIS_PORT..."
              echo "$COMPOSE_FILE" | docker compose -p "$PROJECT_NAME" -f - up -d
              echo "Services started successfully!"
              echo "  PostgreSQL: localhost:$PG_PORT"
              echo "  Redis: localhost:$REDIS_PORT"
            '')

            # Node.js and Yarn
            nodejs_20
            yarn-berry

            ruby-3
            bundler # 2.7.2
            docker
            docker-compose
            postgresql_17 # for psql client tools
            redis # for redis-cli client tools
            libyaml # NOTE: for psych gem
            openssl
            awscli2
          ];
        };
    });
}

