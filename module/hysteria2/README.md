# Hysteria2 NixOS Module

This is a Hysteria2 proxy service module for NixOS.

## Features

- Enable or disable the Hysteria2 service
- Customizable Hysteria2 package
- Support for configuration via inline text or config file path
- Automatic creation of system user and group
- Privileged port binding support
- Full systemd service configuration

## Usage

### 1. Import the module in your NixOS configuration

```nix
{
  imports = [
    ./mymodule/hysteria2
  ];
}
```

### 2. Configure the Hysteria2 service

```nix
services.hysteria2 = {
  enable = true;
  package = pkgs.hysteria2;  # Optional: Specify the package
  
  # Method 1: Use inline text configuration
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
  
  # Method 2: Use a configuration file path
  # configFile = "/etc/hysteria2/config.yaml";
  
  # Optional: Customize user and group
  user = "hysteria2";
  group = "hysteria2";
  dataDir = "/var/lib/hysteria2";
};
```

## Configuration Options

### `services.hysteria2.enable`
- Type: `boolean`
- Default: `false`
- Description: Whether to enable the Hysteria2 service

### `services.hysteria2.package`
- Type: `package`
- Default: `pkgs.hysteria2`
- Description: The Hysteria2 package to use

### `services.hysteria2.config`
- Type: `string`
- Description: Hysteria2 configuration content (YAML format)

### `services.hysteria2.configFile`
- Type: `nullOr path`
- Default: `null`
- Description: Path to Hysteria2 configuration file (mutually exclusive with `config`)

### `services.hysteria2.user`
- Type: `string`
- Default: `"hysteria2"`
- Description: User to run the Hysteria2 service as

### `services.hysteria2.group`
- Type: `string`
- Default: `"hysteria2"`
- Description: Group to run the Hysteria2 service as

### `services.hysteria2.dataDir`
- Type: `path`
- Default: `"/var/lib/hysteria2"`
- Description: Hysteria2 data directory

## Example Configuration

### Basic Server Configuration

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

### Client Configuration

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

## Service Management

```bash
# Start the service
sudo systemctl start hysteria2

# Stop the service
sudo systemctl stop hysteria2

# Restart the service
sudo systemctl restart hysteria2

# Check service status
sudo systemctl status hysteria2

# View logs
sudo journalctl -u hysteria2 -f
```

## Note

1. Ensure the firewall allows the port(s) used by Hysteria2
2. If using TLS, make sure certificate files exist and have correct permissions
3. The config file will be automatically given proper permissions (600)
4. The user and group necessary for the service will be created automatically
5. Binding to privileged ports (<1024) is supported
