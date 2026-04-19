{
  description = "Modern nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    
    # The gold standard for Homebrew management in 2025
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, neovim-nightly-overlay }:
  let
    # 1. Modular Overlays
    overlays = [
      (import ./overlays/mise_2025120.nix)
    ];

    # 2. Reusable Shared Configuration
    sharedConfig = { pkgs, config, username, ... }: {
      
      system.primaryUser = username;
      nixpkgs.config.allowUnfree = true;

      environment.systemPackages = with pkgs; [ 
        act aerospace age atuin bat bruno chezmoi colima delta difftastic
        docker dua eza fd flameshot fzf gcc gh git gnupg
        ilspycmd imagemagick iproute2mac jc jq k9s lazygit
        mas # Required for App Store CLI
        miller mise meld mkalias pngpaste ripgrep rustup serie sesh starship
        tmux tree-sitter utm zk zoxide zsh
        inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
          upgrade = true;
          cleanup = "zap"; # Removes apps/casks not in this list
        };

        # Best Practice: Find IDs using `mas search <name>`
        masApps = {
          "Pages" = 361309726;
          "Numbers" = 361304891;
          "Keynote" = 361285480;
        };

        taps = [ "isen-ng/dotnet-sdk-versions" ];
        
        brews = [
          "bitwarden-cli"
          "gemini-cli"
          "opencode"
          "tree-sitter-cli"
        ];

        # removed "wezterm@nightly"
        casks = [
          "dbeaver-community" "hammerspoon" "jordanbaird-ice"
          "ghostty" "google-chrome" "google-drive" "scoot" "slack"
          "font-jetbrains-mono-nerd-font"
          "isen-ng/dotnet-sdk-versions/dotnet-sdk10-0-100"
        ];
      };

      nix-homebrew = {
        enable = true;
        user = username;
        enableRosetta = false;
        autoMigrate = true;
        # Fix for issue #131: ensure mas is in the path for brew bundle
        extraEnv = {
          PATH = "${pkgs.mas}/bin:$PATH";
        };
      };

      # macOS System Defaults
      system.defaults = {
        dock = { autohide = true; persistent-apps = []; };
        loginwindow.GuestEnabled = false;
        NSGlobalDomain.KeyRepeat = 2;
        WindowManager.EnableStandardClickToShowDesktop = false;
      };

      # Fix sudo secure_path so brew bundle can find mas
      security.sudo.extraConfig = ''
        Defaults secure_path = /run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin
      '';

      # App Aliases (Fix for Nix GUI apps in Spotlight)
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = ["/Applications"];
        };
      in pkgs.lib.mkForce ''
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
      '';

      nix.enable = true;
      nix.settings.experimental-features = "nix-command flakes";
      programs.zsh.enable = true;
      system.stateVersion = 5;
      nixpkgs.hostPlatform = "aarch64-darwin";
    };

    # 3. Helper for creating system configurations
    mkDarwinConfig = { system, username, hostname }: nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username; };
      modules = [
        { nixpkgs.overlays = overlays; }
        sharedConfig
        nix-homebrew.darwinModules.nix-homebrew
      ];
    };
  in
  {
    darwinConfigurations."mchip" = mkDarwinConfig {
      system = "aarch64-darwin";
      username = "marvindore";
      hostname = "mchip";
    };

    darwinPackages = self.darwinConfigurations."mchip".pkgs;
  };
}
