# NixOS Beepy

![Beepy Device](beepy.jpg)

## Introduction

**NixOS Beepy** is a Nix Flake that provides hardware support for the [Beepy by SQFMI x Beeper](https://beepy.sqfmi.com/). This includes support for its Sharp LCD and its Blackberry keyboard.

## Features

- Working Blackberry keyboard, using ardangelo/beepberry-keyboard-driver
- Working Sharp LCD, using ardangelo/sharp-drm-driver

## Not yet implemented, but PRs would be appreciated

- Simple Bluetooth config (just enable it and it does all the raspi config stuff)
- Simple side button config - run arbitrary command on press
- Automatic soft shutdown on low battery

## Usage

Include the module in your NixOS flake.nix, and enable it in your configuration.nix

`flake.nix`:

```nix
{
    inputs = {
        nixos-beepy.url = "github:arilotter/nixos-beepy";
    };
    outputs = { self, nixpkgs, nixos-beepy }: {
        nixosConfigurations.mybeepy = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
                nixos-beepy.nixosModule
                ./configuration.nix
            ];
        };
    };
}
```

`configuration.nix`:

```nix
{
  # The only thing you need to add to your config!
  # Set it up normally otherwise.
  hardware.beepy.enable = true;

  # If you have wired your Beepy yourself, and have a keyboard interrupt pin that isn't the default of "4", you can change it like this:
  # hardware.beepy.irqPin = 3;

  # You can change your framebuffer font!
  # Pick any one of 10x18, 6x10, 6x8, 7x14, Acorn8x8, MINI4x6, PEARL8x8, ProFont6x11, SUN12x22, SUN8x16, TER16x32, VGA8x16, VGA8x8
  # hardware.beepy.fbFont = "6x8";


  # Some other config things you'll need to install NixOS on a Beepy:
  nixpkgs.hostPlatform = "aarch64-linux";

  # The Raspberry Pi Zero W 2 doesn't do so hot without swap,
  # and `nixos-rebuild switch` *really* doesn't do so hot on the Pi without swap.
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 8 * 1024;
  }];
}
```

### Building an SD image

Once you've toggled the module on, you can build an SD card .img file of your entire config, ready to flash.

`$ nix build ./your-flake-dir#mybeepy.config.system.build.sdImage`

This will output an SD card image in the `result/` directory! (symlinked ofc)

Flash it using `dd`.

_(did you know that `dd` stands for Carbon Copy, but `cc` was taken by the c compiler??? what da hell)_

## Contributing

Contributions to this project are very very welcome! If you find any issues or have improvements to suggest, please open an issue or create a pull request!! <3

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Special thanks to the Beepy & NixOS communities for their support and contributions.

Shameless self-plug - check out the unofficial Beepy forum at https://beepy.space for discussions!
