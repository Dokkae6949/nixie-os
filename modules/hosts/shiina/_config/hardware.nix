{ lib, pkgs, config, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
      kernelModules = [ ];
    };

    kernelModules = [ "kvm-intel"];
    kernelParams = [ "psmouse.synaptics_intertouch=1" ];
    extraModulePackages = [ ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.useDHCP = lib.mkDefault true;
  networking.hostName = lib.mkDefault "shiina";

  services.fwupd.enable = true;

  systemd.services.trackpad-fix = {
    description = "Reload psmouse module for trackpad fix";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.kmod}/bin/rmmod psmouse && ${pkgs.kmod}/bin/modprobe psmouse'";
      RemainAfterExit = true;
    };
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
