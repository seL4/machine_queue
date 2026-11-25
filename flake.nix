{
  description = "Machine Queue scripts for remote access to our CI system";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    machine-locks.url = "github:au-ts/machine-locks";
  };

  outputs =
    inputs:
    let
      deps = system: pkgs: [
        inputs.machine-locks.packages.${system}.client
        pkgs.jq
      ];
    in
    {
      devShells = builtins.mapAttrs (system: pkgs: {
        default = pkgs.mkShell {
          packages = deps system pkgs;
        };
      }) inputs.nixpkgs.legacyPackages;
      packages = builtins.mapAttrs (system: pkgs: {
        default = pkgs.stdenv.mkDerivation {
          pname = "machine_queue";
          version = pkgs.lib.removeSuffix "\n" (builtins.readFile ./VERSION);
          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            cp -r mq.sh scripts $out/bin/

            wrapProgram $out/bin/mq.sh \
              --prefix PATH : ${pkgs.lib.makeBinPath (deps system pkgs)}

            runHook postInstall
          '';
        };
      }) inputs.nixpkgs.legacyPackages;
    };
}
