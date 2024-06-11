{
  description = "A Nix-flake-based Python development environment";

  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs"; # IMPORTANT!!!
    nix-gl-host = {
      url = "github:numtide/nix-gl-host";
      inputs.nixpkgs.follows = "nix-ros-overlay/nixpkgs";
    };
  };

  outputs = { nixpkgs, nix-gl-host, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          venvDir = "venv";
          packages = with pkgs; [ python311 ] ++
            [ nix-gl-host.defaultPackage.${system} ] ++
            (with pkgs.python311Packages; [
              pip
              venvShellHook
              python-lsp-server

              torch
              omegaconf
              tqdm

              (buildPythonPackage rec {
                pname = "vector_quantize_pytorch";
                version = "1.14.24";
                pyproject = true;
                src = fetchPypi {
                  inherit pname version;
                  hash = "sha256-j0LXglWChRw0IPjgln2h1MP9gReklBRd/eeLdb9BryY="; # pkgs.lib.fakeHash;
                };
                propagatedBuildInputs = [
                  hatchling
                  (buildPythonPackage rec {
                    pname = "einops";
                    version = "0.8.0";
                    src = fetchPypi {
                      inherit pname version;
                      hash = "sha256-Y0hlF/7TRXEqg4XBAMsnkQjZ1H5q5ZCZsHZX6YPeroU="; # pkgs.lib.fakeHash;
                    };
                    pyproject = true;
                    nativeBuildInputs = [ hatchling ];
                    propagatedBuildInputs = [ ];
                    doCheck = false;
                  })
                  (buildPythonPackage rec {
                    pname = "einx";
                    version = "0.2.2";
                    src = fetchPypi {
                      inherit pname version;
                      hash = "sha256-efT/d8BzcMSQU1M4Nl7XtBfG0OhuiTWE1QvT/eRsYug="; # pkgs.lib.fakeHash;
                    };
                    propagatedBuildInputs = [ ];
                    doCheck = false;
                  })
                  torch
                ];
              })
              (buildPythonPackage rec {
                pname = "vocos";
                version = "0.1.0";
                src = fetchFromGitHub {
                  owner = "gemelo-ai";
                  repo = pname;
                  rev = "v0.1.0";
                  hash = "sha256-K1ontwueJm42j8m8lkn+Xto031dZ3D9mG6FeVyJeHDo="; # pkgs.lib.fakeHash;
                };
                propagatedBuildInputs = [ ];
                doCheck = false;
              })
              (buildPythonPackage rec {
                pname = "WeTextProcessing";
                version = "1.0.0";
                src = fetchPypi {
                  inherit pname version;
                  hash = "sha256-D5++ZEcDyyrzfDQYJ0FFHt4ISywMjUh5SxoRhJsyVlE="; # pkgs.lib.fakeHash;
                };
                patches = [ ./nix/fix-wetext-processing.patch ];
                propagatedBuildInputs = [ ];
                doCheck = false;
              })
              (buildPythonPackage rec {
                pname = "pynini";
                version = "2.1.5.post2";
                pyproject = true;
                src = fetchPypi {
                  inherit pname version;
                  hash = "sha256-giHniMd6OLT4DTR9pVyeL1QcDmQZepsphWafiEwl+H8="; # pkgs.lib.fakeHash;
                };
                propagatedBuildInputs = [
                  setuptools
                  (buildPythonPackage rec {
                    pname = "Cython";
                    version = "3.0.10";
                    src = fetchPypi {
                      inherit pname version;
                      hash = "sha256-3MlnOTMfuFTc9QP5RgdXbP6EiAZsYcpQ39VYNvEy3pk="; # pkgs.lib.fakeHash;
                    };
                    doCheck = false;
                  })
                  openfst
                ];
                doCheck = false;
              })
              ipython

              gradio
              torchaudio
              encodec
              scipy
              transformers
              frozendict
              regex
            ]);
          shellHook = /* bash */ ''
            export LD_LIBRARY_PATH="$(nixglhost -p):$LD_LIBRARY_PATH"

            # venvShellHook
            if [[ -v venvDir ]]; then
              if [[ -d "$venvDir" ]]; then
                printf "%s\n" "Skipping venv creation, '$venvDir' already exists"
                source "$venvDir/bin/activate"
              else
                printf "%s\n" "Creating new venv environment in path: '$venvDir'"
                python -m venv "$venvDir"
                source "$venvDir/bin/activate"
              fi
            fi
          '';
        };
      });
    };
}
