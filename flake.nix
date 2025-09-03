{
  description = "Python development environment with UV (FHS)";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = (pkgs.buildFHSEnv {
          name = "python-uv-dev";
          targetPkgs = pkgs:
            with pkgs; [
              # Essential system libraries
              glibc
              stdenv.cc.cc.lib

              # Python and UV
              python312
              uv

              # Build tools
              gcc
              pkg-config

              # Common dependencies
              zlib
              libffi
              openssl
              ncurses
              readline
              sqlite
              tk
              xz

              # Development tools
              git
              curl
              wget
              which

              # Additional libraries that Python packages might need
              libxml2
              libxslt
              libjpeg
              libpng
              freetype
              blas
              lapack
              gfortran
            ];

          runScript = "bash";

          profile = ''
            export UV_CACHE_DIR="$PWD/.uv-cache"
            mkdir -p "$UV_CACHE_DIR"

            # Force UV to use the Nix Python 3.12 (not its own Python downloads)
            export UV_PYTHON="$(which python3.12)"
            export UV_PYTHON_DOWNLOADS="never"

            # Clean start
            echo "Setting up Python development environment..."
            echo "Using Python: $(which python3.12)"
            echo "Python version: $(python3.12 --version)"

            # Only initialize if pyproject.toml doesn't exist
            if [ ! -f pyproject.toml ]; then
              echo "Initializing UV project with Python 3.12..."
              uv init --python python3.12
              uv add jupyter ipykernel ipywidgets notebook
              uv add torch  # This should work now with Python 3.12
              uv add --dev black ruff isort pytest
            fi

            # Sync dependencies
            uv sync

            # Install Jupyter kernel
            echo "Installing Jupyter kernel..."
            uv run python -m ipykernel install --user --name "$(basename $PWD)" --display-name "$(basename $PWD) (UV-FHS)"

            echo "Environment ready!"
            uv run python --version
          '';
        }).env;
      });
}
