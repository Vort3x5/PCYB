{
  description = "PCYB Log4Shell lab (Minecraft / Log4j)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      log4jApi = pkgs.fetchurl {
        pname = "log4j-api";
        version = "2.14.1";
        url = "https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-api/2.14.1/log4j-api-2.14.1.jar";
        hash = "sha256-jK9Y2wBsYJlJoAaBEDlaMwZ6K61wfD2jXpWcBHP5qRY=";
      };

      log4jCore = pkgs.fetchurl {
        pname = "log4j-core";
        version = "2.14.1";
        url = "https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-core/2.14.1/log4j-core-2.14.1.jar";
        hash = "sha256-redAKnBmenJ2NdXEwpSV9P+W8GHxJTl2P28SOXO0ZbA=";
      };

      log4jApiSafe = pkgs.fetchurl {
        pname = "log4j-api";
        version = "2.17.1";
        url = "https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-api/2.17.1/log4j-api-2.17.1.jar";
        hash = "sha256-sNikyKtPuLGIjQCVgicDsObUeTxBlVAgPanmkZYWHeQ=";
      };

      log4jCoreSafe = pkgs.fetchurl {
        pname = "log4j-core";
        version = "2.17.1";
        url = "https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-core/2.17.1/log4j-core-2.17.1.jar";
        hash = "sha256-yWfyI0h5gLk2TpSnx/mooB/T7nwZvb8LD5+MuFEfPUE=";
      };

      minecraftServer_1_16_5 = pkgs.fetchurl {
        pname = "minecraft-server";
        version = "1.16.5";
        url = "https://piston-data.mojang.com/v1/objects/1b557e7b033b583cd9f66746b7a9ab1ec1673ced/server.jar";
        hash = "sha256-WPMpx9JpZSb5SEcKpv0LRVRQObZMt1AV5kwSGUs3PaY=";
      };

      labTools = with pkgs; [
        jdk11
        wireshark
        tcpdump
        libcap  # setcap — scripts/setup-capture.sh
        nmap
        netcat-gnu
        curl
        jq
        wget
        git
        maven
        unzip
        ripgrep
        python3
        strace
        lsof
        typst
      ];

      shellHookCommon = ''
        export PCYB_ROOT="$(pwd)"
        export PCYB_VENDOR="$PCYB_ROOT/vendor"
        export JAVA_HOME="${pkgs.jdk11}"
        export PATH="$JAVA_HOME/bin:$PATH"
        export LOG4J_API_JAR="${log4jApi}"
        export LOG4J_CORE_JAR="${log4jCore}"
        export LOG4J_API_SAFE_JAR="${log4jApiSafe}"
        export LOG4J_CORE_SAFE_JAR="${log4jCoreSafe}"
        export MINECRAFT_SERVER_JAR="${minecraftServer_1_16_5}"
        mkdir -p "$PCYB_VENDOR" "$PCYB_ROOT/evidence" "$PCYB_ROOT/run"
        echo "PCYB: JDK11, Log4j 2.14.1 / 2.17.1 — ./scripts/run-full-lab.sh"
      '';
    in
    {
      packages.${system} = {
        log4j-api_2_14_1 = log4jApi;
        log4j-core_2_14_1 = log4jCore;
        log4j-api_2_17_1 = log4jApiSafe;
        log4j-core_2_17_1 = log4jCoreSafe;
        minecraft-server_1_16_5 = minecraftServer_1_16_5;
        default = log4jCore;
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          packages = labTools;
          shellHook = shellHookCommon;
        };

        mc-server = pkgs.mkShell {
          packages = labTools;
          shellHook = shellHookCommon + ''
            echo "role: mc-server — ./scripts/start-mc-server.sh"
          '';
        };

        mc-client = pkgs.mkShell {
          packages = labTools;
          shellHook = shellHookCommon + ''
            echo "role: mc-client — see scripts/trigger-mc-chat.md"
          '';
        };

        attacker = pkgs.mkShell {
          packages = labTools;
          shellHook = shellHookCommon + ''
            echo "role: attacker — start-http-payload / start-ldap / start-listener"
          '';
        };
      };

      checks.${system} = {
        jars = pkgs.runCommand "pcyb-jars-check" { } ''
          set -euo pipefail
          test -f ${log4jApi}
          test -f ${log4jCore}
          test -f ${log4jApiSafe}
          test -f ${log4jCoreSafe}
          test -f ${minecraftServer_1_16_5}
          ${pkgs.jdk11}/bin/java -version
          mkdir -p $out
          echo ok > $out/result
        '';
      };
    };
}
