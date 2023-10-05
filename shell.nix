let
  pkgs = import <nixpkgs> { };
in
pkgs.stdenv.mkDerivation {
  name = "_Users_richard_zkvm_optimism-1.1.4";
  buildInputs = with pkgs; [
    go
    gopls
    nodePackages.pnpm
  ];
}
