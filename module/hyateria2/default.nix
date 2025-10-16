{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.hysteria2;
in
{
  options.services.hysteria2 = {
    enable = mkEnableOption "Hysteria2 proxy service";

    package = mkOption {
      type = types.package;
      default = pkgs.hysteria2;
      description = "The Hysteria2 package to use";
    };

    config = mkOption {
      type = types.str;
      description = "Hysteria2 configuration file content";
      example = ''
        server: :443
        auth: your-password
        cert: /path/to/cert.pem
        key: /path/to/key.pem
        obfs: salamander
        obfs-password: your-obfs-password
      '';
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to Hysteria2 configuration file (alternative to config option)";
    };

    user = mkOption {
      type = types.str;
      default = "hysteria2";
      description = "User to run Hysteria2 service";
    };

    group = mkOption {
      type = types.str;
      default = "hysteria2";
      description = "Group to run Hysteria2 service";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/hysteria2";
      description = "Data directory for Hysteria2";
    };
  };

  config = mkIf cfg.enable {
    users.users = mkIf (cfg.user == "hysteria2") {
      hysteria2 = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
        createHome = true;
      };
    };

    users.groups = mkIf (cfg.group == "hysteria2") {
      hysteria2 = { };
    };

    systemd.services.hysteria2 = {
      description = "Hysteria2 proxy service";
      after = [ "network.target" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/hysteria server -c ${
          if cfg.configFile != null then cfg.configFile else "/etc/hysteria2/config.yaml"
        }";
        Restart = "always";
        RestartSec = "5";
        StandardOutput = "journal";
        StandardError = "journal";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ];
        CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      };

      preStart = ''
        mkdir -p ${cfg.dataDir}
        chown ${cfg.user}:${cfg.group} ${cfg.dataDir}
      '';
    };

    environment.etc = mkIf (cfg.configFile == null) {
      "hysteria2/config.yaml" = {
        text = cfg.config;
        mode = "0600";
        user = cfg.user;
        group = cfg.group;
      };
    };

    # Allow binding to privileged ports
    security.wrappers = {
      hysteria2 = {
        source = "${cfg.package}/bin/hysteria";
        owner = "root";
        group = "root";
        setuid = false;
        setgid = false;
        capabilities = "cap_net_bind_service+ep";
      };
    };
  };
}
