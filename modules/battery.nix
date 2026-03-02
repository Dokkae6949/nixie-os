{ ... }:

{
  nixie.battery = {
    description = "battery management (upower)";

    nixos = { ... }: {
      services.upower.enable = true;

      services.tlp = {
        enable = true;

        settings = {
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;

          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 60;

          STOP_CHARGE_THRESH_BAT0 = 85;
          STOP_CHARGE_THRESH_BAT1 = 85;
          START_CHARGE_THRESH_BAT0 = 80;
          START_CHARGE_THRESH_BAT1 = 80;
        };
      };
    };
  };
}
