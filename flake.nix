{
  description = "A simple NixOS flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      # Define packages
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      # Add packages
      packages.x86_64-linux = {
        hysteria2 = pkgs.callPackage ./pkg/hysteria2/package.nix { };
        hf_proxy = pkgs.callPackage ./pkg/hf_proxy/default.nix { };
        xray-docker = pkgs.callPackage ./pkg/xray-docker/pakcage.nix { };
        overtls = pkgs.callPackage ./pkg/overtls/default.nix { };
      };

      # NixOS modules
      nixosModules = {
        hysteria2 = ./module/hysteria2;
        overtls = ./module/overtls;
        china-ip = ./module/china-ip;
      };
    };
}
