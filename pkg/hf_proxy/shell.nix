{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    go
    gopls
    gotools
    go-outline
    gocode
    gopkgs
    godef
    golint
  ];

  shellHook = ''
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH
    export GO111MODULE=on
    
    # For SOCKS proxy environment variable
    export SOCKS_PROXY=${SOCKS_PROXY:-http-proxy-to-socks:8080}
    
    echo "Go development environment ready!"
  '';
}
