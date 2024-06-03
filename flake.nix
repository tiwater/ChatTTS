{
  description = "A Nix-flake-based Python development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          venvDir = "venv";
          packages = with pkgs; [ python311 ] ++
            (with pkgs.python311Packages; [
              pip
              venvShellHook

              torch
              omegaconf
              tqdm
              einops
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
                  einops
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
              transformers
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
              ipython

              gradio
              torchaudio
              encodec
            ]);
        };
      });
    };
}
