{
  description = "Drivers & Configuration for NixOS on the SQFMI Beepy";

  nixConfig = {
    extra-substituters = [ "https://raspberry-pi-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "raspberry-pi-nix.cachix.org-1:WmV2rdSangxW0rZjY/tBvBDSaNFQ3DyEQsVw8EvHn9o="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    raspberry-pi-nix.url = "github:tstat/raspberry-pi-nix";
  };

  outputs = { nixpkgs, raspberry-pi-nix, ... }@inputs:
    {
      nixosModule = { config, lib, pkgs, ... }@args: with lib;
        {
          imports = [
            raspberry-pi-nix.nixosModules.raspberry-pi
          ];
          options.hardware.beepy = {
            enable = mkEnableOption "Hardware support for the SQFMI x Beeper 'Beepy'";
            irqPin = mkOption {
              type = types.number;
              default = 4;
              description = "The pin on which to listen for hardware interrupts generated by the RP2040";
            };
            fbFont = mkOption {
              type = types.string;
              default = "6x8";
              description = "The fbcon font option - one of 10x18, 6x10, 6x8, 7x14, Acorn8x8, MINI4x6, PEARL8x8, ProFont6x11, SUN12x22, SUN8x16, TER16x32, VGA8x16, VGA8x8.";
            };
          };
          config =
            let
              kernel = pkgs.rpi-kernels.latest.kernel;

              sharpDriver = import ./sharp-drm.nix { pkgs = pkgs; kernel = kernel; };

              cmdline = pkgs.writeText "cmdline.txt" ''
                dwc_otg.lpm_enable=0 console=ttyAMA0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait console=tty2 fbcon=font:${config.hardware.beepy.fbFont} fbcon=map:10
              '';
              sharpOverlay = pkgs.runCommand "sharp-overlay" { } ''
                mkdir $out
                ${pkgs.dtc}/bin/dtc -@ -I dts -O dtb -o $out/sharp-drm.dtbo ${sharpDriver}/sharp-drm.dts
              '';
              keyboardDriver = import ./sharp-drm.nix { pkgs = pkgs; kernel = kernel; };
            in
            mkIf config.hardware.beepy.enable
              {
                # setup the Sharp display & Blackberry keyboard
                boot.extraModulePackages = [ sharpDriver keyboardDriver ];
                boot.kernelModules = [ "i2c-dev" "sharp-drm" "beepy-kbd" ];
                console.packages = [ keyboardDriver ];
                console.keyMap = "beepy-kbd";
                console.earlySetup = true;
                hardware.raspberry-pi.config.all = {
                  dt-overlays = {
                    sharp-drm = {
                      enable = true;
                      params = { };
                    };
                    beepy-kbd = {
                      enable = true;
                      params = {
                        irq_pin = {
                          enable = true;
                          value = toString config.hardware.beepy.irqPin;
                        };
                      };
                    };
                  };

                  base-dt-params = {
                    i2c_arm = {
                      enable = true;
                      value = "on";
                    };
                    spi = {
                      enable = true;
                      value = "on";
                    };
                  };

                  options = {
                    framebuffer_width = {
                      enable = true;
                      value = "400";
                    };
                    framebuffer_height = {
                      enable = true;
                      value = "240";
                    };
                  };
                };

                # fix for wifi rpi 3 and light 2
                boot.extraModprobeConfig = ''
                  options brcmfmac roamoff=1 feature_disable=0x82000
                '';

                sdImage = {
                  compressImage = false;
                  populateFirmwareCommands = ''
                    mkdir -p firmware/overlays/
                    chmod -R 777 firmware/overlays
                    ls -laR ${keyboardDriver}
                    cp ${sharpOverlay}/sharp-drm.dtbo firmware/overlays/
                    cp ${keyboardDriver}/boot/overlays/* firmware/overlays/
                    cp ${cmdline} firmware/cmdline.txt
                  '';
                };
              }
          ;
        };
    };
}