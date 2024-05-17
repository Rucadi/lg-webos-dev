{
  description = "Cmake with webOs toolchain";

  inputs = { 
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    ares-cli-pkgs.url = "github:rucadi/nixpkgs/ares-cli";
    toolchain.url = "github:rucadi/native-toolchain";
  };

  outputs = { self, toolchain, ares-cli-pkgs, nixpkgs }:
    let
      allSystems = [
        "x86_64-linux" # 64bit AMD/Intel x86
        "aarch64-linux" # 64bit ARM
        "x86_64-darwin" # 64bit AMD/Intel macOS
        "aarch64-darwin" # 64bit ARM macOS
      ];

      forAllSystems = fn:
        nixpkgs.lib.genAttrs allSystems
        (system: fn 
        { 
          pkgs = import nixpkgs { inherit system; }; 
          ares-cli = (import ares-cli-pkgs {inherit system;}).ares-cli;
          webos-toolchain = toolchain.defaultPackage."${system}";
          inherit system;
        });
    in {

      devShells = forAllSystems ({ pkgs, ares-cli, webos-toolchain, system }:
      {
        default = let 
          vscodeCmakeKit = [
            {
             name = "webos-toolchain";
             cmake = "${pkgs.cmake}/bin/cmake";
             toolchainFile = "${webos-toolchain}/share/buildroot/toolchainfile.cmake";
            }
          ];
        in pkgs.mkShell {
          nativeBuildInputs = [  pkgs.cmake ares-cli webos-toolchain ];         
          shellHook = ''
            alias cmake='${pkgs.cmake}/bin/cmake -DCMAKE_CXX_FLAGS="-I ${webos-toolchain}/include/glib-2.0 -I ${webos-toolchain}/lib/glib-2.0/include" -DCMAKE_TOOLCHAIN_FILE=${webos-toolchain}/share/buildroot/toolchainfile.cmake'
            function lg-init-vscode-cmake-kit { 
              echo '${builtins.toJSON vscodeCmakeKit}' > $1
            }
          '';
        };
      });
    };
}