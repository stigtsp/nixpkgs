{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.n3n;
  supernodeConfig = pkgs.writeText "supernode.conf" ''
    [connection]
    bind=${toString cfg.supernode.listenPort}
  '';
  edgeConfig = pkgs.writeText "${cfg.edge.sessionName}.conf" ''
    [tuntap]
    name=${cfg.edge.sessionName}
    ${if cfg.edge.macaddr != "" then "macaddr=${cfg.edge.macaddr}" else ""}
    ${if cfg.edge.ip != "" then ''
    address_mode=static
    ip=${cfg.edge.ip}
    ''
    else ""}

    [community]
    name=${cfg.edge.community}
    key=${cfg.edge.key}
    supernode=${cfg.edge.supernode}
  '';


in {

  options.services.n3n.enable = mkEnableOption "n3n";
  options.services.n3n.supernode.enable = mkEnableOption "n3n supernode";

  options.services.n3n.supernode.listenPort = mkOption {
    default = 7654;
    type = types.port;
    description = ''
      TCP and UDP port used by the n3n supernode
    '';
  };

  options.services.n3n.edge = {
    enable = mkEnableOption "n3n edge";
    sessionName = mkOption {
      type = types.str;
      example = "mysession";
      description = "name of your session";
    };
    community = mkOption {
      type = types.str;
      example = "mygroup";
      description = "name of your community";
    };
    key = mkOption {
      type = types.str;
      example = "hunter2";
      description = "password for group";
    };
    supernode = mkOption {
      type = types.str;
      example = "supernode.example.com:7777";
      description = "supernode address";
    };
    ip = mkOption {
      type = types.str;
      example = "127.0.0.1";
      description = "your ip";
    };
    macaddr = mkOption {
      type = types.str;
      example = "blabalefefef";
      description = "your mac address";
    };
  };


  config = mkIf cfg.enable (
    mkMerge [
      (mkIf cfg.supernode.enable {
      systemd.services.n3n-supernode = {
      description = "n3n-supernode";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network-online.target" ];

      path = [ pkgs.n3n ];

      preStart = ''
        mkdir -p /run/n3n/supernode
      '';

      serviceConfig = {
        ExecStart = "${pkgs.n3n}/bin/n3n-supernode start ${supernodeConfig}";
        Restart = "always";
        KillMode = "process";
        TimeoutStopSec = 5;
      };
    };
  })
      (mkIf cfg.edge.enable {

    systemd.services.n3n-edge = {
      description = "n3n-edge";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network-online.target" ];

      path = [ pkgs.n3n ];


      serviceConfig = {
        ExecStart = "${pkgs.n3n}/bin/n3n-edge start ${edgeConfig}";
        Restart = "always";
        KillMode = "process";
        TimeoutStopSec = 5;
      };
    };
      })
    ]);

}
