{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.chnip;
in
{
  options.services.chnip = {
    enable = mkEnableOption "Chinese IP address list service";

    url = mkOption {
      type = types.str;
      default = "https://raw.githubusercontent.com/mayaxcn/china-ip-list/refs/heads/master/chnroute.txt";
      description = "URL to download the Chinese IP address list";
    };

    ipsetName = mkOption {
      type = types.str;
      default = "chn_ip";
      description = "Name of the ipset to store Chinese IP addresses";
    };

    interval = mkOption {
      type = types.str;
      default = "1d";
      description = "How often to update  the IP list (systemd time format)";
    };

    connectionTimeout = mkOption {
      type = types.int;
      default = 10;
      description = "Connection timeout in seconds for downloading the IP list";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.chnip-update = {
      description = "Update Chinese IP address list";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      path = with pkgs; [
        ipset
        curl
        coreutils
      ];

      script = ''
        set -euo pipefail  # Exit on error, undefined variables, and pipe failures

        # Use systemd's STATE_DIRECTORY environment variable
        # When DynamicUser=true, this points to /var/lib/private/chnip
        # When DynamicUser=false, this points to /var/lib/chnip
        CACHE_FILE="$STATE_DIRECTORY/chnroute.txt"
        TEMP_FILE="$STATE_DIRECTORY/chnroute.txt.tmp"

        echo "Creating/updating ipset ${cfg.ipsetName}..."
        # Create ipset if it doesn't exist
        if ! ipset list ${cfg.ipsetName} &>/dev/null; then
          echo "Creating new ipset ${cfg.ipsetName}"
          ipset create ${cfg.ipsetName} hash:net maxelem 100000
        else
          echo "ipset ${cfg.ipsetName} already exists"
        fi

        # Flush existing entries
        echo "Flushing existing entries in ipset ${cfg.ipsetName}"
        ipset flush ${cfg.ipsetName}

        # Function to load IP list from file into ipset
        load_from_file() {
          local file="$1"
          echo "Loading IP list from $file"
          
          if [ ! -f "$file" ]; then
            echo "ERROR: File $file does not exist!"
            return 1
          fi
          
          local count=0
          local errors=0
          
          # Temporarily disable errexit for the loop
          set +e
          
          while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            
            # Validate IP format: only allow digits, dots, and slashes
            # This prevents command injection by ensuring only valid CIDR notation
            if ! [[ "$line" =~ ^[0-9./]+$ ]]; then
              errors=$((errors + 1))
              if [ $errors -le 5 ]; then
                echo "Warning: Invalid IP format (contains illegal characters): $line"
              fi
              continue
            fi
            
            # Additional validation: check for valid CIDR format (x.x.x.x/x)
            if ! [[ "$line" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
              errors=$((errors + 1))
              if [ $errors -le 5 ]; then
                echo "Warning: Invalid CIDR format: $line"
              fi
              continue
            fi
            
            # Add IP to ipset, capture errors but continue processing
            if output=$(ipset add ${cfg.ipsetName} "$line" 2>&1); then
              count=$((count + 1))
            else
              errors=$((errors + 1))
              if [ $errors -le 5 ]; then
                echo "Warning: Failed to add IP: $line - $output"
              fi
            fi
          done < "$file"
          
          # Re-enable errexit
          set -e
          
          echo "Successfully loaded $count IP entries into ipset ${cfg.ipsetName}"
          if [ $errors -gt 0 ]; then
            echo "Warning: $errors entries failed to load"
          fi
          
          return 0
        }

        # Try to download from URL
        echo "Checking URL connectivity: ${cfg.url}"
        if curl -sSf --connect-timeout ${toString cfg.connectionTimeout} --head "${cfg.url}" >/dev/null 2>&1; then
          echo "URL is reachable, downloading IP list..."
          if curl -sSf --connect-timeout ${toString cfg.connectionTimeout} "${cfg.url}" -o "$TEMP_FILE"; then
            echo "Download successful, saving to cache..."
            mv "$TEMP_FILE" "$CACHE_FILE"
            load_from_file "$CACHE_FILE"
          else
            echo "Download failed, attempting to load from cache..."
            if [ -f "$CACHE_FILE" ]; then
              load_from_file "$CACHE_FILE"
            else
              echo "Error: No cache file available and download failed!"
              exit 1
            fi
          fi
        else
          echo "URL is not reachable, loading from cache..."
          if [ -f "$CACHE_FILE" ]; then
            load_from_file "$CACHE_FILE"
          else
            echo "Error: No cache file available and URL is not reachable!"
            exit 1
          fi
        fi
        #1016
      '';

      serviceConfig = {
        Type = "simple";
        RemainAfterExit = true;
        StateDirectory = "chnip";
        StateDirectoryMode = "0700"; # Only root can access

        # Run as root (required for ipset operations)
        User = "root";

        # Security hardening
        # Note: ipset data is stored in kernel space, only accessible by root/CAP_NET_ADMIN
        PrivateTmp = true;
        ProtectHome = true;
      };
    };

    # Create a timer to periodically update the IP list
    systemd.timers.chnip-update = {
      description = "Timer for updating Chinese IP address list";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = cfg.interval;
      };
    };

    # Check service - reload from cache if ipset is empty
    systemd.services.chnip-check = {
      description = "Check Chinese IP address list and reload if empty";
      after = [ "network.target" ];

      path = with pkgs; [
        ipset
        coreutils
      ];

      script = ''
        CACHE_FILE="/var/lib/chnip/chnroute.txt"

        # Check if ipset exists and get entry count
        if ipset list ${cfg.ipsetName} &>/dev/null; then
          ENTRY_COUNT=$(ipset list ${cfg.ipsetName} | grep -c "^[0-9]" || echo 0)
          echo "ipset ${cfg.ipsetName} has $ENTRY_COUNT entries"
          
          # If ipset is empty or has very few entries, reload from cache
          if [ "$ENTRY_COUNT" -lt 10 ]; then
            echo "ipset ${cfg.ipsetName} is empty or nearly empty, reloading from cache..."
            
            if [ -f "$CACHE_FILE" ]; then
              echo "Cache file found, loading..."
              
              # Flush existing entries
              ipset flush ${cfg.ipsetName}
              
              # Load from cache
              count=0
              while IFS= read -r line; do
                [[ -z "$line" || "$line" =~ ^# ]] && continue
                # Validate IP format to prevent command injection
                [[ ! "$line" =~ ^[0-9./]+$ ]] && continue
                [[ ! "$line" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]] && continue
                ipset add ${cfg.ipsetName} "$line" 2>/dev/null && count=$((count + 1))
              done < "$CACHE_FILE"
              
              echo "Reloaded $count IP entries from cache"
            else
              echo "ERROR: Cache file not found at $CACHE_FILE"
              exit 1
            fi
          else
            echo "ipset ${cfg.ipsetName} is healthy"
          fi
        else
          echo "ipset ${cfg.ipsetName} does not exist, creating and loading from cache..."
          ipset create ${cfg.ipsetName} hash:net maxelem 100000
          
          if [ -f "$CACHE_FILE" ]; then
            count=0
            while IFS= read -r line; do
              [[ -z "$line" || "$line" =~ ^# ]] && continue
              # Validate IP format to prevent command injection
              [[ ! "$line" =~ ^[0-9./]+$ ]] && continue
              [[ ! "$line" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]] && continue
              ipset add ${cfg.ipsetName} "$line" 2>/dev/null && count=$((count + 1))
            done < "$CACHE_FILE"
            echo "Created ipset and loaded $count entries from cache"
          else
            echo "WARNING: Cache file not found, ipset created but empty"
          fi
        fi
      '';

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        PrivateTmp = true;
        ProtectHome = true;
      };
    };

    # Timer to check ipset every 5 minutes
    systemd.timers.chnip-check = {
      description = "Timer for checking Chinese IP address list";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
      };
    };
  };
}
