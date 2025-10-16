{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.overtls;
in
{
  options.services.overtls = {
    enable = mkEnableOption "OverTLS proxy service";

    package = mkOption {
      type = types.package;
      default = pkgs.overtls;
      description = "The OverTLS package to use";
    };

    role = mkOption {
      type = types.str;
      description = "The role of the OverTLS proxy";
      example = "server";
    };

    config = mkOption {
      type = types.str;
      description = "OverTLS configuration file content";
      example = ''
            {
            "tunnel_path": "/secret-tunnel-path/",

            "server_settings": {
                "certfile": "/etc/mysite_cert/fullchain.pem",
                "keyfile": "/etc/mysite_cert/privkey.pem",
                "forward_addr": "http://127.0.0.1:80",
                "listen_host": "0.0.0.0",
                "listen_port": 443
            },

            "client_settings": {
                "server_host": "123.45.67.89",
                "server_port": 443,
                "server_domain": "example.com",
                "listen_host": "127.0.0.1",
                "listen_port": 1080
            }
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.overtls = {
      description = "OverTLS proxy service";
      after = [ "network.target" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        ExecStart = "${cfg.package}/bin/overtl -r ${cfg.role} -c /etc/overtls/config.json";
        Restart = "always";
        RestartSec = "5";
        StandardOutput = "journal";
        StandardError = "journal";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      };
    };

    environment.etc."overtls/config.json" = {
      text = cfg.config;
      mode = "0600";
    };
  };
}
