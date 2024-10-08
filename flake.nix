{
  description = "Deno build flake";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/24.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default =
          let
            hashedDeps = pkgs.stdenv.mkDerivation {
              pname = "hashedDeps";
              version = "1";
              src = ./.;
              buildCommand = ''
                mkdir -p $out
                cp -r $src/create_deno_nix_lockfile.js .
                cp -r $src/deno.lock .
                deno run -A create_deno_nix_lockfile.js > $out/deno.nix
              '';
              nativeBuildInputs = with pkgs; [ deno ];
            };
            cached =
              let
                fetchedDeps = map
                  (x: pkgs.fetchurl {
                    url = x.url;
                    hash = x.sha256;
                    rev = x.rev;
                  })
                  hashedDeps;
              in
              pkgs.stdenv.mkDerivation rec {
                pname = "cached";
                version = "1";

                src = fetchedDeps;

                installPhase = ''
                  cp -r . $out
                '';
                nativeBuildInputs = with pkgs; [ hashedDeps ];
              };
            denort = pkgs.stdenv.mkDerivation rec {
              pname = "denort";
              version = "1.45.5";
              src = pkgs.fetchurl {
                url = "https://dl.deno.land/release/v${version}/denort-x86_64-unknown-linux-gnu.zip";
                hash = "sha256-0fwhJKkb9KVywNgqoLE+9KiMLUPiSaZ8gGmEpmpejXo=";
              };
              sourceRoot = ".";
              nativeBuildInputs = with pkgs; [ autoPatchelfHook unzip ];
              buildInputs = with pkgs; [ stdenv.cc.cc.lib ];
              installPhase = ''
                install -Dm555 -t $out/bin denort
              '';
            };
          in
          pkgs.stdenv.mkDerivation {
            pname = "deno-compile";
            version = "1";
            src = ./.;
            buildCommand = ''
              cp -r $src/* .
              export DENORT_BIN="$(which denort)"
              export DENO_DIR=".deno"

              deno compile --cached-only --no-remote -o $out/hello ./src/main.ts
              
              # For testing
              # mkdir -p $out
              # touch $out/hello
              # cp -r ${cached} $out/has
            '';
            nativeBuildInputs = with pkgs; [ deno denort which cached ];
          };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.bashInteractive ];
          buildInputs = with pkgs; [
            deno
          ];
          # TODO: Google buildInputs vs nativeBuildInputs Nix
          # nativeBuildInputs = with pkgs; with pkgs.nodePackages; [
          #   deno
          #   unzip
          # ];
        };
      });
}

