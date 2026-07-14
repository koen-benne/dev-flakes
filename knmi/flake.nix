{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
      pkgs = nixpkgs.legacyPackages.${system};
      ruby = nixpkgs-ruby.packages.${system}."ruby-3.4.8";
    in {
      devShell = with pkgs;
        mkShell {
          buildInputs = [
            # Combined Docker management script for PostgreSQL and Redis
            (writeScriptBin "docker-start" ''
              #!${runtimeShell}
              MYSQL_PORT="''${MYSQL_PORT:-3306}"
              PG_PORT="''${RAILS_DATABASE_PORT:-''${DB_PORT:-5432}}"
              BASE_NAME="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]-' '-' | sed 's/^-*//' | sed 's/-*$//')"
              PROJECT_NAME="$BASE_NAME"

              COMPOSE_FILE=$(cat <<EOF
              services:
                mysql:
                  image: mysql:8.0
                  container_name: $PROJECT_NAME-mysql-$MYSQL_PORT
                  environment:
                    - MYSQL_ROOT_PASSWORD=root
                    - MYSQL_DATABASE=''${PROJECT_NAME}_development
                  ports:
                    - "$MYSQL_PORT:3306"
                  volumes:
                    - mysql_data:/var/lib/mysql
                postgres:
                  image: postgres:18
                  container_name: $PROJECT_NAME-postgres-$PG_PORT
                  environment:
                    - POSTGRES_HOST_AUTH_METHOD=trust
                    - POSTGRES_USER=''${USER:-postgres}
                  ports:
                    - "$PG_PORT:5432"
                  volumes:
                    - postgres_data:/var/lib/postgresql/data

              volumes:
                mysql_data:
                postgres_data:
              EOF
              )

              echo "Starting MySQL on port $MYSQL_PORT and PostgreSQL on port $PG_PORT..."
              echo "$COMPOSE_FILE" | docker compose -p "$PROJECT_NAME" -f - up -d
              echo "Services started successfully!"
              echo "  MySQL:      localhost:$MYSQL_PORT"
              echo "  PostgreSQL: localhost:$PG_PORT"
            '')

            yarn-berry

            ruby
            bundler # 2.7.2
            docker
            docker-compose
            postgresql_18 # for psql client tools
            libmysqlclient
            libyaml # NOTE: for psych gem
            openssl
            awscli2
            vips
            imagemagick

            pkg-config
            libxml2
            libxslt
            gcc
          ];
          env.LD_LIBRARY_PATH = "${pkgs.vips.out}/lib:${pkgs.imagemagick}/lib";
          env.LDFLAGS = "-L${libxml2.out}/lib -L${libxslt.out}/lib";
          env.CPPFLAGS = "-I${libxml2.dev}/include -I${libxslt.dev}/include";
        };
    });
}


