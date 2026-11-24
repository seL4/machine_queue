{
  description = "Machine Queue scripts for remote access to our CI system";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    machine-locks.url = "github:au-ts/machine-locks";
  };

  outputs = inputs: {
    devShells = builtins.mapAttrs (system: pkgs: {
      default = pkgs.mkShell {
        packages = [
          inputs.machine-locks.packages.${system}.client
          pkgs.jq
        ];
      };
    }) inputs.nixpkgs.legacyPackages;
  };
}
