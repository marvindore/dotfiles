{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages =
        [ 
            pkgs.asdf-vm
            pkgs.bat
            pkgs.fzf
            pkgs.git
            pkgs.gnupg
            pkgs.logseq
            pkgs.mkalias
            pkgs.neovim
            pkgs.ripgrep
            pkgs.stow
            pkgs.zoxide
            pkgs.zsh
        ];

      # Must be logged into app store for this to work
      # Search for mac store apps with `mas search <appName>` then add to masApps like "AppName" = <appID>
      homebrew = {
        enable = true;
        brews = [
        "mas"
        ];
        casks = [
            "hammerspoon"
            "nikitabobko/tap/aerospace"
        ];
        masApps = {

        };
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };
      fonts.packages = [ 
        pkgs.nerd-fonts.jetbrains-mono
      ];

      # Macos alias for gui apps
    system.activationScripts.applications.text = let
      env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = "/Applications";
      };
    in
      pkgs.lib.mkForce ''
      # Set up applications.
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
          '';

      # `darwin-help` command or mynixos.com has list of available settings
      system.defaults = {
        dock.autohide = true;
      };
      # Auto upgrade nix package and daemon service
      services.nix-daemon.enable = true;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;
      programs.zsh.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # TODO: The platform the configuration will be used on. (x86_64-darwin) (aarch64-darwin)
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."mchip" = nix-darwin.lib.darwinSystem {
      modules = [ 
      configuration 
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # TODO: Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "amari";

            autoMigrate = true; # true if you have pre-existing homebrew install
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience
    darwinPackages = self.darwinConfigurations."mchip".pkgs;
  };
}
