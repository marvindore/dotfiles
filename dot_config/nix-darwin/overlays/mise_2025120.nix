# overlays/mise_2025120.nix
# calculate hash and store it in nix store: 
# nix store prefetch-file <url>
final: prev: {
  mise = prev.stdenv.mkDerivation {
    pname = "mise";
    version = "2025.12.0";

    # fetch the release tarball
    src = prev.fetchurl {
      url = "https://github.com/jdx/mise/releases/download/v2025.12.0/mise-v2025.12.0-macos-arm64.tar.gz";
      sha256 = "sha256-TWlFXNNf8owKdMBy8tqtiVdCzQ+4R95X+YZmjAW4uxQ=";
    };

    # no build needed
    dontBuild = true;
    dontConfigure = true;
    dontPatch = true;

    installPhase = ''
      # $out is the destination path in the Nix store where binary will permanently live
      mkdir -p $out/bin
      
      # We also don't strictly need $sourceRoot here as nix cd's into it
      cp bin/mise $out/bin/mise
      
      chmod +x $out/bin/mise
      
      # Optional: Install man pages if included in the tarball
      # mkdir -p $out/share/man/man1
      # cp man/man1/mise.1 $out/share/man/man1/mise.1
    '';
  };
}
