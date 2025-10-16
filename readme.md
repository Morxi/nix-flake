# Moxi's Nix Flakes

A collection of NixOS packages and modules for proxy services and network utilities.

## 📦 Packages

This flake provides the following packages for `x86_64-linux`:

- **hysteria2** - High-performance proxy protocol
- **hf_proxy** - HuggingFace reverse proxy with SOCKS5 support
- **xray-docker** - Xray proxy in Docker
- **overtls** - Lightweight proxy tool

### Usage

```bash
# Build a package
nix build github:your-username/flake#hysteria2

# Run a package
nix run github:your-username/flake#hf_proxy
```

## 🔧 NixOS Modules

### Hysteria2

A high-performance proxy service with obfuscation support.

```nix
{
  imports = [ inputs.moxi-flake.nixosModules.hysteria2 ];

  services.hysteria2 = {
    enable = true;
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
  };
}
```

[More details](./module/hysteria2/README.md)

### OverTLS

Lightweight proxy tool for secure connections.

```nix
{
  imports = [ inputs.moxi-flake.nixosModules.overtls ];

  services.overtls = {
    enable = true;
    # Add your configuration here
  };
}
```

### China IP

Automatically maintains an ipset of Chinese IP addresses, useful for routing decisions.

```nix
{
  imports = [ inputs.moxi-flake.nixosModules.china-ip ];

  services.chnip = {
    enable = true;
    ipsetName = "chn_ip";
    interval = "1d";  # Update daily
  };
}
```

Features:
- Automatic daily updates of Chinese IP list
- Fallback to cached list when network is unavailable
- Creates and maintains ipset for use with iptables/nftables

## 🚀 Getting Started

### As a Flake Input

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    moxi-flake.url = "github:your-username/flake";
  };

  outputs = { self, nixpkgs, moxi-flake, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        moxi-flake.nixosModules.hysteria2
        moxi-flake.nixosModules.china-ip
      ];
    };
  };
}
```

### Direct Installation

```bash
# Clone the repository
git clone https://github.com/your-username/flake
cd flake

# Build a package
nix build .#hysteria2

# Test a module
nixos-rebuild test --flake .
```

## 📝 License

This project is available under your chosen license.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.