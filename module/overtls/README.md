# OverTLS NixOS Module

这是一个用于 NixOS 的 OverTLS 代理服务模块。OverTLS 是一个简单的代理工具，通过 TLS 来绕过防火墙。

## 功能特性

- 支持启用/禁用 OverTLS 服务
- 可自定义 OverTLS 包
- 支持通过文本配置
- 使用 DynamicUser 提高安全性
- 完整的 systemd 服务配置
- 支持特权端口绑定

## 使用方法

### 1. 在 NixOS 配置中导入模块

有两种方式导入模块：

**方法 1：通过 flake (推荐)**

在你的 flake.nix 中：

```nix
{
  inputs = {
    nix-config.url = "path:/path/to/nix-config";
  };

  outputs = { self, nixpkgs, nix-config, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        nix-config.nixosModules.overtls
        ./configuration.nix
      ];
    };
  };
}
```

**方法 2：直接导入路径**

```nix
{
  imports = [
    ./mymodule/overtls
  ];
}
```

### 2. 配置 OverTLS 服务

```nix
services.overtls = {
  enable = true;
  package = pkgs.overtls;  # 可选：指定特定的包
  
  config = ''
    {
      "tunnel_path": "/tunnel",
      "server_addr": "0.0.0.0:443",
      "cert": "/etc/ssl/certs/overtls.pem",
      "key": "/etc/ssl/private/overtls.key"
    }
  '';
};
```

## 配置选项

### `services.overtls.enable`
- 类型：`boolean`
- 默认值：`false`
- 描述：是否启用 OverTLS 服务

### `services.overtls.package`
- 类型：`package`
- 默认值：`pkgs.overtls`
- 描述：要使用的 OverTLS 包

### `services.overtls.config`
- 类型：`string`
- 描述：OverTLS 配置文件内容（JSON 格式）

## 示例配置

### 服务器模式配置

```nix
services.overtls = {
  enable = true;
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
```

### 客户端模式配置

```nix
services.overtls = {
  enable = true;
  config = ''
    {
      "tunnel_path": "/tunnel",
      "server_addr": "your-server.com:443",
      "local_addr": "127.0.0.1:1080"
    }
  '';
};
```

## 服务管理

```bash
# 启动服务
sudo systemctl start overtls

# 停止服务
sudo systemctl stop overtls

# 重启服务
sudo systemctl restart overtls

# 查看服务状态
sudo systemctl status overtls

# 查看日志
sudo journalctl -u overtls -f
```

## 注意事项

1. 确保防火墙允许 OverTLS 使用的端口
2. 如果使用 TLS，确保证书文件存在且权限正确
3. 配置文件会自动设置适当的权限（600）
4. 服务使用 DynamicUser，自动管理用户和组
5. 支持绑定特权端口（<1024）

## OverTLS 配置说明

OverTLS 使用 JSON 格式的配置文件，主要参数包括：

- `tunnel_path`: TLS 隧道路径
- `server_addr`: 服务器监听地址（服务器模式）或服务器地址（客户端模式）
- `local_addr`: 本地监听地址（客户端模式）
- `forward_addr`: 转发目标地址（服务器模式）
- `cert`: TLS 证书文件路径（服务器模式）
- `key`: TLS 密钥文件路径（服务器模式）

更多配置选项请参考 [OverTLS 官方文档](https://github.com/ShadowsocksR-Live/overtls)。

