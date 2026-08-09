{
  description = "Modern nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    
    # The gold standard for Homebrew management in 2025
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    
    mac-app-util.url = "github:hraban/mac-app-util";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, neovim-nightly-overlay, mac-app-util }:
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
        act age atuin bat chezmoi cmake delta difftastic
        docker dua ec eza fd fzf gcc gh git gnupg
        ilspycmd imagemagick iproute2mac jc jq just k9s lazygit
        mas # Required for App Store CLI
        miller mise mkalias pngpaste ripgrep rustup sesh starship
        tmux tree-sitter zk zoxide zsh
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
          "WireGuard" = 1451685025;
        };

        taps = [
        ];
        
        brews = [
          "bitwarden-cli"
          "opencode"
           "sox_ng"
          "tree-sitter-cli"
          "wireguard-tools"
        ];

        # removed "wezterm@nightly"
        casks = [
          "aerospace" "antigravity-cli" "bruno" "dbeaver-community" "hammerspoon" "hiddenbar"
          "ghostty" "google-chrome" "google-drive" "linearmouse" "meld" "scoot" "slack"
          "font-jetbrains-mono-nerd-font"
          "macshot" "supercmdlabs/supercmd/supercmd" "thaw" "utm"
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
          HOMEBREW_NO_REQUIRE_TAP_TRUST = "1";
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

      # App Aliases (Fix for Homebrew Cask GUI apps in Spotlight)
      system.activationScripts.applications.text = pkgs.lib.mkForce ''
        echo "setting up /Applications and ~/Applications for Homebrew App Aliases..." >&2
        for app_dir in "/Applications" "/Users/${username}/Applications"; do
          if [ -d "$app_dir" ]; then
            find "$app_dir" -maxdepth 1 -type l | while read -r symlink; do
              target=$(readlink "$symlink")
              if [[ "$target" == /opt/homebrew/* ]]; then
                app_name=$(basename "$symlink")
                echo "Replacing Homebrew symlink with alias: $app_dir/$app_name -> $target" >&2
                rm "$symlink"
                ${pkgs.mkalias}/bin/mkalias "$target" "$app_dir/$app_name"
              fi
            done
          fi
        done

        echo "Triggering Spotlight metadata import for Applications..." >&2
        /usr/bin/mdimport /Applications
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
        mac-app-util.darwinModules.default
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

# defaults write .GlobalPreferences _HIHideMenuBar -bool true
# defaults write .GlobalPreferences AppleMenuBarVisibleInFullscreen -bool false

