{ ... }:

{
  nixie.battery = {
    description = "battery management (upower)";

    nixos = { ... }: {
      # Causes issues with dual batteries.
      # services.upower.enable = true;

      services.tlp = {
        enable = true;
        pd.enable = true;

        settings = {
          # AC = performance
          CPU_BOOST_ON_AC = 1;
          CPU_HWP_DYN_BOOST_ON_AC = 1;
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_MAX_PERF_ON_AC = 100;

          # BAT = balanced
          CPU_BOOST_ON_BAT = 0;
          CPU_HWP_DYN_BOOST_ON_BAT = 1;
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
          CPU_MAX_PERF_ON_BAT = 100;

          # SAV = extreme power saving
          CPU_BOOST_ON_SAV = 0;
          CPU_HWP_DYN_BOOST_ON_SAV = 0;
          CPU_SCALING_GOVERNOR_ON_SAV = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_SAV = "power";
          CPU_MAX_PERF_ON_SAV = 70;

          # Battery thresholds
          STOP_CHARGE_THRESH_BAT0 = 85;
          START_CHARGE_THRESH_BAT0 = 80;
          STOP_CHARGE_THRESH_BAT1 = 85;
          START_CHARGE_THRESH_BAT1 = 80;
        };
      };
    };
  };
}
