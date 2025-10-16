# OverTLS 服务使用示例

{ config, pkgs, ... }:

{
  # 导入 OverTLS 模块
  imports = [
    ./default.nix
  ];

  # 示例 1: 服务器模式配置
  services.overtls = {
    enable = true;
    package = pkgs.overtls;

    config = ''
      {
        "tunnel_path": "/tunnel",
        "server_addr": "0.0.0.0:443",
        "cert": "/etc/ssl/certs/overtls.pem",
        "key": "/etc/ssl/private/overtls.key",
        "forward_addr": "127.0.0.1:8080"
      }
    '';
  };

  # 示例 2: 客户端模式配置
  # services.overtls = {
  #   enable = true;
  #   package = pkgs.overtls;
  #
  #   config = ''
  #     {
  #       "tunnel_path": "/tunnel",
  #       "server_addr": "your-server.com:443",
  #       "local_addr": "127.0.0.1:1080"
  #     }
  #   '';
  # };

  # 打开防火墙端口（如果需要）
  networking.firewall.allowedTCPPorts = [ 443 ];

  # 如果使用 TLS，确保证书文件存在
  # security.acme.acceptTerms = true;
  # security.acme.defaults.email = "your-email@example.com";
}
