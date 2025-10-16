{ pkgs ? import <nixpkgs> {} }:
let
  # Create a shell script to run go mod vendor before building
  preVendorScript = pkgs.writeShellScript "pre-vendor.sh" ''
    cd $PWD
    ${pkgs.go}/bin/go mod vendor
  '';
in

pkgs.buildGoModule {
  pname = "hf_proxy";
  version = "0.1.0";
  src = ./.;
  
  # When first building, use this and Nix will tell you the correct hash
  # vendorHash = pkgs.lib.fakeSha256;
  
  # After getting the correct hash from the error message, replace with:
  vendorHash = null; # Set to null if using go.mod with vendor directory
  
  postPatch = ''
    # Create a symbolic link to the pre-vendor script for execution
    ln -s ${preVendorScript} pre-vendor.sh
    chmod +x pre-vendor.sh
    ./pre-vendor.sh
    # Add debug output to help with Nix build troubleshooting
    echo "Debug: Building hf_proxy"
    echo "Debug: Current directory: $PWD"
    echo "Debug: Source directory: $src"
    echo "Debug: Go version: $(${pkgs.go}/bin/go version)"
    echo "Debug: Vendor directory contents:"
    ls -la vendor/ || echo "Debug: No vendor directory found"
    echo "Debug: Go module information:"
    ${pkgs.go}/bin/go mod graph || echo "Debug: Unable to show module graph"
  '';

  # Execute the pre-vendor script before building
  preBuild = ''
    ${preVendorScript}
  '';
  
  meta = with pkgs.lib; {
    description = "Hugging Face API proxy";
    homepage = "https://github.com/yourusername/hf_proxy";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
