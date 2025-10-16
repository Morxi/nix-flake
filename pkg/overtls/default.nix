{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
}:

let
  version = "0.3.7";

  # 根据系统架构选择对应的二进制文件
  src =
    if stdenv.hostPlatform.system == "x86_64-linux" then
      fetchzip {
        url = "https://github.com/ShadowsocksR-Live/overtls/releases/download/v${version}/overtls-x86_64-unknown-linux-musl.zip";
        sha256 = "sha256-l1jAFMbgwfsaM4tmMSMbcCQbyuyvkuMSe+N6hgD8Pts=";
        stripRoot = false;
      }
    else if stdenv.hostPlatform.system == "aarch64-linux" then
      fetchzip {
        url = "https://github.com/ShadowsocksR-Live/overtls/releases/download/v${version}/overtls-aarch64-unknown-linux-gnu.zip";
        sha256 = "sha256-RJGbzQ+86v2QGqcUyy4StjYtZCdz9VnLlvYj2q6oh5M=";
        stripRoot = false;
      }
    else
      throw "Unsupported system: ${stdenv.hostPlatform.system}";

in
stdenv.mkDerivation {
  pname = "overtls";
  inherit version src;

  nativeBuildInputs = [ autoPatchelfHook ];

  # 不需要构建，直接安装
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm755 overtls-bin $out/bin/overtls

    runHook postInstall
  '';

  meta = with lib; {
    description = "A simple proxy to bypass firewalls through TLS";
    homepage = "https://github.com/ShadowsocksR-Live/overtls";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    maintainers = [ ];
    mainProgram = "overtls";
  };
}
