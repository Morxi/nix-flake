# Hysteria2 NixOS Module

这是一个用于NixOS的Hysteria2代理服务模块。

## 功能特性

- 支持启用/禁用Hysteria2服务
- 可自定义Hysteria2包
- 支持通过文本配置或配置文件路径
- 自动创建系统用户和组
- 支持特权端口绑定
- 完整的systemd服务配置

## 使用方法

### 1. 在NixOS配置中导入模块

```nix
{
  imports = [
    ./mymodule/hyateria2
  ];
}
```

### 2. 配置Hysteria2服务

```nix
services.hysteria2 = {
  enable = true;
  package = pkgs.hysteria2;  # 可选：指定特定的包
  
  # 方法1：使用文本配置
  config = ''
    listen: :443
    auth: "your-password"
    tls:
      cert: /etc/ssl/certs/hysteria2.crt
      key: /etc/ssl/private/hysteria2.key
    obfs:
      type: salamander
      salamander:
        password: "your-obfs-password"
  '';
  
  # 方法2：使用配置文件路径
  # configFile = "/etc/hysteria2/config.yaml";
  
  # 可选：自定义用户和组
  user = "hysteria2";
  group = "hysteria2";
  dataDir = "/var/lib/hysteria2";
};
```

## 配置选项

### `services.hysteria2.enable`
- 类型：`boolean`
- 默认值：`false`
- 描述：是否启用Hysteria2服务

### `services.hysteria2.package`
- 类型：`package`
- 默认值：`pkgs.hysteria2`
- 描述：要使用的Hysteria2包

### `services.hysteria2.config`
- 类型：`string`
- 描述：Hysteria2配置文件内容（YAML格式）

### `services.hysteria2.configFile`
- 类型：`nullOr path`
- 默认值：`null`
- 描述：Hysteria2配置文件路径（与config选项二选一）

### `services.hysteria2.user`
- 类型：`string`
- 默认值：`"hysteria2"`
- 描述：运行Hysteria2服务的用户

### `services.hysteria2.group`
- 类型：`string`
- 默认值：`"hysteria2"`
- 描述：运行Hysteria2服务的组

### `services.hysteria2.dataDir`
- 类型：`path`
- 默认值：`"/var/lib/hysteria2"`
- 描述：Hysteria2数据目录

## 示例配置

### 基本服务器配置

```nix
services.hysteria2 = {
  enable = true;
  config = ''
    listen: :443
    auth: "your-secure-password"
    tls:
      cert: /etc/ssl/certs/hysteria2.crt
      key: /etc/ssl/private/hysteria2.key
    obfs:
      type: salamander
      salamander:
        password: "your-obfs-password"
    bandwidth:
      up: "1 gbps"
      down: "1 gbps"
  '';
};
```

### 客户端配置

```nix
services.hysteria2 = {
  enable = true;
  config = ''
    server: your-server.com:443
    auth: "your-password"
    obfs:
      type: salamander
      salamander:
        password: "your-obfs-password"
    bandwidth:
      up: "20 mbps"
      down: "100 mbps"
  '';
};
```

## 服务管理

```bash
# 启动服务
sudo systemctl start hysteria2

# 停止服务
sudo systemctl stop hysteria2

# 重启服务
sudo systemctl restart hysteria2

# 查看服务状态
sudo systemctl status hysteria2

# 查看日志
sudo journalctl -u hysteria2 -f
```

## 注意事项

1. 确保防火墙允许Hysteria2使用的端口
2. 如果使用TLS，确保证书文件存在且权限正确
3. 配置文件会自动设置适当的权限（600）
4. 服务会自动创建必要的用户和组
5. 支持绑定特权端口（<1024）


