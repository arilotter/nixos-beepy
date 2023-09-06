{ pkgs, kernel }:
# https://github.com/ardangelo/sharp-drm-driver
pkgs.stdenv.mkDerivation rec {
  pname = "sharp-drm";
  version = "0.0.1-${kernel.version}";

  src = pkgs.fetchFromGitHub {
    owner = "ardangelo";
    repo = "sharp-drm-driver";
    rev = "8bdc22653f0555b286c014dbb95bc8064f9693c4";
    sha256 = "sha256-eRj74G3SNwHgMqF9KYfCGLfaf2g+EZSdpIdnKW+FPwI=";
  };

  hardeningDisable = [ "pic" "format" ];
  buildInputs = [ pkgs.nukeReferences ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  # Required to build kernel modules with `make`.
  LINUX_DIR = "${kernel.dev}/lib/modules/${kernel.version}/build";

  installPhase = ''
    runHook preInstall
    
    # Install built modules
    mkdir -p $out/lib/modules/${kernel.version}/misc
    for x in $(find . -name '*.ko'); do
      nuke-refs $x
      cp $x $out/lib/modules/${kernel.version}/misc/
    done

    # Copy DTS to output, so we can include in firmware.
    cp ./sharp-drm.dts $out

    runHook postInstall
  '';
}
