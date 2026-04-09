{
  config,
  pkgs-stable,
  pkgs,
  zen-browser,
  ...
}:
let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [
      "30.0.3"
      "34.0.0"
      "35.0.0"
    ]; # Adjust based on your Flutter/Android requirements
    cmakeVersions = [ "3.22.1" ];
    platformVersions = [
      "31"
      "33"
      "34"
      "35"
      "36"
      "latest"
    ]; # Adjust as needed (e.g., match your app's min/target SDK)
    systemImageTypes = [ "google_apis_playstore" ]; # Optional, for Google services in emulators
    includeNDK = true;
    ndkVersions = [
      "26.3.11579264"
      "27.0.12077973"
      "28.2.13676358"
    ];
    includeExtras = [ "extras;google;auto" ];
    extraLicenses = [
      "android-googlexr-license"
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };

  androidSdk = androidComposition.androidsdk;

  myjdk = pkgs.jdk17;

  zen-custom = zen-browser.packages."${pkgs.system}".twilight.override {
    extraPolicies = {
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
    };
  };
  kde-app-menu = pkgs.runCommandLocal "xdg-application-menu" { } ''
    mkdir -p $out/etc/xdg/menus/
    ln -s ${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu $out/etc/xdg/menus/applications.menu
  '';
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "amdgpu" ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.allowed-users = [ "sagiri" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  fileSystems."/mnt/nas" = {
    device = "192.168.1.nas:/volume1/Folder";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "users"
      "nofail"
    ];
  };

  hardware.bluetooth = {
    enable = true;
    settings.General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr
    ];
  };
  services.xserver.videoDrivers = [ "amdgpu" ];
  nixpkgs.config.rocmSupport = true;

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-nord
      rime-data
      fcitx5-rime
      fcitx5-gtk
    ];
  };

  users.users.sagiri = {
    isNormalUser = true;
    description = "sagiri";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "render"
    ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gnome
    ];
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.protectKernelImage = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    nerd-fonts.symbols-only
    font-awesome
    source-code-pro
  ];

  services.printing.enable = false;
  services.flatpak.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  services.ollama = {
    enable = false;
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "65536";
    };
  };

  virtualisation.containers.enable = false;
  virtualisation.podman = {
    enable = false;
    dockerCompat = true;
    defaultNetwork.settings.dns_enables = true;
    extraPackages = [ pkgs.rocmPackages.clr ];
  };

  # virtualisation.oci-containers.backend = "podman";

  services.opensnitch.enable = true;

  environment.systemPackages = with pkgs; [
    waybar
    mako
    fuzzel
    alacritty
    nautilus
    pavucontrol
    libnotify
    htop
    unzip
    gammastep
    keepassxc
    newsflash

    nixd
    nixfmt
    git
    gcc
    go
    gopls
    nodejs_latest
    flutter
    androidSdk
    myjdk
    androidStudioPackages.canary
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        vscodevim.vim
        jnoortheen.nix-ide
        dart-code.flutter
        dart-code.dart-code
        golang.go
        haskell.haskell
        justusadam.language-haskell
        mechatroner.rainbow-csv
        rust-lang.rust-analyzer
      ];
    })

    kdePackages.dolphin
    kdePackages.kservice
    kdePackages.kate
    kde-app-menu

    signal-desktop
    pkgs-stable.ungoogled-chromium

    poppler-utils
    imagemagickBig
    hpack

    gemini-cli-bin

    mullvad-browser

    # brave

    framesh
    xwayland-satellite

    qrencode

    rustup

    android-tools

    # appimage-run

    # podman-compose

    zen-custom

    opensnitch-ui
    # bubblewrap
  ];

  environment.variables = {
    CHROME_EXECUTABLE = "${pkgs.ungoogled-chromium}/bin/chromium";
    ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    JAVA_HOME = "${myjdk}";
    ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk-bundle";
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";
  };

  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  # environment.memoryAllocator.provider = "graphene-hardened";

  # programs.firejail = {
  #   enable = true;
  #   wrappedBinaries = {
  #     zen-custom = {
  #       executable = "${zen-custom}/bin/zen-twilight";
  #       profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
  #       extraArgs = [
  #         "--blacklist=/etc/ld-nix.so.preload"
  #       ];
  #     };
  #   };
  # };

  system.stateVersion = "25.11"; # Did you read the comment?

}
