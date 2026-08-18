{
  flake.modules.nixos.shiina = {
    services.throttled.enable = true;

    services.tlp.settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_MAX_PERF_ON_AC = 100;

      CPU_BOOST_ON_BAT = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 1;
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_MAX_PERF_ON_BAT = 100;

      CPU_BOOST_ON_SAV = 0;
      CPU_HWP_DYN_BOOST_ON_SAV = 0;
      CPU_SCALING_GOVERNOR_ON_SAV = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";
      CPU_MAX_PERF_ON_SAV = 60;

      START_CHARGE_THRESH_BAT0 = 80;
      STOP_CHARGE_THRESH_BAT0 = 85;
      START_CHARGE_THRESH_BAT1 = 80;
      STOP_CHARGE_THRESH_BAT1 = 85;
    };

    services.undervolt = {
      enable = true;
      coreOffset = -90;
      gpuOffset = -50;
    };
  };
}
