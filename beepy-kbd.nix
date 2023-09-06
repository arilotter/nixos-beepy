{ pkgs, kernel }:
# https://github.com/ardangelo/beepberry-keyboard-driver
pkgs.stdenv.mkDerivation {
  pname = "beepy-kbd-driver";
  version = "0.0.1-${kernel.version}";

  src = pkgs.fetchFromGitHub {
    owner = "ardangelo";
    repo = "beepberry-keyboard-driver";
    rev = "9a755c0c4f1ac2d025a7f879d9132335420d235f";
    sha256 = "sha256-Hriw9tPOi2ZF/z56ySdXLBHFCeAqs0GMjuyAMswJrK0=";
  };

  hardeningDisable = [ "pic" "format" ];
  buildInputs = [ pkgs.nukeReferences ];
  nativeBuildInputs = kernel.moduleBuildDependencies ++ [ pkgs.dtc ];

  LINUX_DIR = "${kernel.dev}/lib/modules/${kernel.version}/build";

  installPhase = ''
    runHook preInstall

    # Install built out-of-tree kernel modules
    mkdir -p $out/lib/modules/${kernel.version}/misc
    for x in $(find . -name '*.ko'); do
      nuke-refs $x
      cp $x $out/lib/modules/${kernel.version}/misc/
    done

    # Install keymap
    ## The offical ardangelo keymap doesn't include a-z, enter, esc, backspace, etc.
    ## Somehow, this works for people on raspberry pi OS.
    ## There must be a fallback keymap, or something.
    ## Rather than figure that out, I just got someone to dump their working keymap.
    ## If anyone figures out why the fallback doesn't work, let me know
    # cp ./beepy-kbd.map $out/share/keymaps # commented out because we copy our own keymap instead
    mkdir -p $out/share/keymaps/
    cat ${./beepy-kbd.map} > $out/share/keymaps/beepy-kbd.map

    # Install device tree overlay
    mkdir -p $out/boot/overlays/
    cp ./beepy-kbd.dtbo $out/boot/overlays

    
    runHook postInstall
  '';
}
