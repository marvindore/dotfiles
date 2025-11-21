{
  description = "nix-darwin system flake";

      # `darwin-help` command or mynixos.com has list of available settings
      # https://mynixos.com/nix-darwin/options
      # sytem preferrences - https://daiderd.com/nix-darwin/manual/index.html 
        
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, neovim-nightly-overlay }:
  let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      system.primaryUser = "marvindore";
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages =
        [ 
            pkgs.aerospace
            pkgs.alacritty
            pkgs.asdf-vm
            pkgs.colima
            pkgs.bat
            pkgs.delta
            pkgs.difftastic
            pkgs.docker
                        #pkgs.docker-compose
            pkgs.eza
            pkgs.fzf
            pkgs.gcc
            pkgs.gh
            pkgs.git
            pkgs.gnupg
            pkgs.httpie
            pkgs.ilspycmd
            pkgs.k9s
            pkgs.logseq
            pkgs.mkalias
            inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default
            pkgs.nushell
            pkgs.ripgrep
            pkgs.rustup
            pkgs.starship
            pkgs.stow
                        #(pkgs.tealdeer.override { doCheck = false })
            pkgs.zellij
            pkgs.zoxide
            pkgs.zsh
        ];

      # Must be logged into app store for this to work
      # Search for mac store apps with `mas search <appName>` then add to masApps like "AppName" = <appID>
      homebrew = {
        enable = true;
        brews = [
        "bitwarden"
        "mas"
        "tree-sitter"
        ];
        casks = [
            "hammerspoon"
            "jordanbaird-ice"
            "google-chrome"
            "raycast"
            "scroll-reverser"
            "scoot"
            "slack"
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
        pathsToLink = ["/Applications"];
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

      system.defaults = {
        dock.autohide = true;
        dock.persistent-apps = [];
        loginwindow.GuestEnabled = false;
        NSGlobalDomain.KeyRepeat = 2;
        WindowManager.EnableStandardClickToShowDesktop = false;
      };

      # make nix-darwin manage the nix-daemon
      nix.enable = true;

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
            enableRosetta = false;

            # User owning the Homebrew prefix
            user = "marvindore";

            autoMigrate = false; # true if you have pre-existing homebrew install
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience
    darwinPackages = self.darwinConfigurations."mchip".pkgs;
  };
}
