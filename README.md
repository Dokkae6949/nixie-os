# Nixi OS

A feature-oriented NixOS configuration using the dendritic pattern,
flake-parts, and Home Manager.

## Mental model

Every Nix file below `modules/` is a top-level flake-parts module discovered by
`import-tree`. These files declare native typed deferred modules through
`flake-parts.flakeModules.modules`. There is no custom module registry.

The system has four layers, ordered from reusable behavior to concrete output:

1. **Features** implement one independently useful capability.
2. **Profiles** compose features into reusable roles.
3. **Users** define identity; **hosts** define machine facts and local policy.
4. A host's **configuration** selects profiles and users and produces a concrete
   `nixosConfiguration`.

A profile is not a configuration. A profile is a reusable module bundle such
as `desktop` or `development`. A configuration is a deployable system such as
`nixosConfigurations.shiina`, including its hardware, users, selected profiles,
and Home Manager instances.

Each host's composition root is colocated at
`modules/hosts/<name>/configuration.nix`. The remaining files in that directory
contribute machine-specific settings to the host module. This keeps one obvious
entry point per machine without mixing reusable features into it.

## Repository layout

```text
modules/
├── features/          # Reusable behavior, one capability per file
├── profiles/          # Import-only bundles of features
├── users/             # Account and personal identity
├── hosts/
│   └── shiina/
│       ├── configuration.nix  # Composition root and flake output
│       ├── boot.nix
│       ├── hardware.nix
│       ├── power.nix
│       ├── storage.nix
│       └── system.nix
```

## Ownership rules

Use these rules to decide where a change belongs:

- Put reusable program or service behavior in `features/`.
- Put a reusable selection of features in `profiles/`.
- Put UID, authentication, login shell, home metadata, and personal authorship
  in `users/`.
- Put hardware, disks, boot, host keys, hardware tuning, and host-local
  authorization in `hosts/<name>/`.
- Put only module selection and Home Manager wiring in a host's
  `configuration.nix`.

If a setting could be reused unchanged on another machine, it should not be in
a host file. If it is not part of a person's identity, it should not be in a
user file.

## Features

A feature file owns all module-system implementations of that capability. For
example, Niri has both NixOS and Home Manager behavior in the same file:

```nix
{ inputs, ... }:

{
  flake.modules.nixos.niri = { pkgs, ... }: {
    programs.niri.enable = true;
  };

  flake.modules.homeManager.niri = { pkgs, ... }: {
    home.pointerCursor = { /* ... */ };
  };
}
```

Features do not import profiles and do not decide which hosts use them.

### Add a feature

1. Create `modules/features/<feature>.nix`.
2. Define `flake.modules.nixos.<feature>`,
   `flake.modules.homeManager.<feature>`, or both.
3. Add the feature to an appropriate profile, or select it directly in one
   host configuration if it is intentionally exceptional.
4. Run `nix flake check`.

For a new package-only feature:

```nix
{
  flake.modules.homeManager.example = { pkgs, ... }: {
    home.packages = [ pkgs.example ];
  };
}
```

### Change a feature

Change its single file in `modules/features/`. Every profile that imports the
feature receives the change. Host-specific overrides do not belong there.

## Profiles

Profiles are import-only compositions. They contain no program settings:

```nix
{ config, ... }:

{
  flake.modules.nixos.development.imports =
    with config.flake.modules.nixos; [
      docker
      nix-ld
      postgresql
    ];

  flake.modules.homeManager.development.imports =
    with config.flake.modules.homeManager; [
      direnv
      helix
      secrets
    ];
}
```

Use a profile when several hosts or users should share a meaningful role. Use
a feature directly when the selection is unique, small, and is unlikely to
become a reusable role.

### Add a profile

1. Create `modules/profiles/<profile>.nix`.
2. Define the NixOS side, Home Manager side, or both.
3. Populate only their `imports` lists with existing named features.
4. Select the profile in the relevant host configurations.

### Add or remove a feature from a profile

Edit only the profile's import list. Do not edit the feature to make it assign
itself to a profile.

## Users

`modules/users/<name>.nix` defines two identity modules when appropriate:

```text
flake.modules.nixos.<name>
flake.modules.homeManager.<name>
```

The NixOS side owns the account, password source, UID, and login shell. The
Home Manager side owns home metadata and personal identity such as Git author
information. General packages belong to features, not users.

### Add a user

1. Create `modules/users/<name>.nix`.
2. Define the NixOS account module and Home Manager identity module.
3. Add any encrypted password material under `secrets/users/` and update
   `.sops.yaml` recipients.
4. In each applicable host's `configuration.nix`, import the NixOS user module.
5. Add a `home-manager.users.<name>` entry selecting that user's profiles and
   identity module.

### Give a user different software on different hosts

Select different Home Manager profiles in each host's `configuration.nix`.
Do not put those packages in the user module.

For example, one host can use:

```nix
users.kurisu.imports = with config.flake.modules.homeManager; [
  base
  desktop
  development
  kurisu
];
```

while another can use only:

```nix
users.kurisu.imports = with config.flake.modules.homeManager; [
  base
  kurisu
];
```

### Add a host-local user permission

Put it in `modules/hosts/<host>/system.nix`. Group membership such as Docker
access is authorization on that machine, not reusable user identity.

## Hosts

A host directory contains machine-specific facts and exactly one composition
root. Files may be split by hardware concern when they are substantial.

### Add a host

1. Create `modules/hosts/<name>/configuration.nix`.
2. Define a merged host module at `flake.modules.nixos.<name>` in sibling files.
3. Add hardware, boot, disk, power, and host-secret settings to those sibling
   files.
4. Instantiate `flake.nixosConfigurations.<name>` in `configuration.nix`.
5. Select reusable NixOS profiles, the host module, and user modules.
6. Configure each user's Home Manager profile selection in the same file.
7. Add host secrets and `.sops.yaml` recipients when required.
8. Run `nix flake check` and build the system closure.

### Tweak one host

- Hardware or local policy: edit the appropriate file under that host.
- Reusable service behavior: edit or create a feature instead.
- Different feature selection: edit the host's `configuration.nix`.
- A change shared by a class of machines: create or change a profile.

### Tweak one user on one host

- Different software selection: change that user's Home Manager imports in the
  host's `configuration.nix`.
- Host-local permission: change the host's local policy.
- Personal identity that follows the user everywhere: change the user module.
- Reusable behavior that may apply elsewhere: make it a feature.

## Impermanence

Impermanence is opt-in. The `impermanent` profile imports:

- the base persistence feature, which imports the upstream impermanence module;
- NetworkManager's persistence integration;
- sops' persistent key integration.

Those integration modules are deferred. A host that does not select the
`impermanent` profile does not evaluate `environment.persistence` and does not
need the upstream impermanence module.

## Common commands

Evaluate every output without building it:

```bash
nix flake check --no-build --all-systems
```

Build Shiina without activating it:

```bash
nix build .#nixosConfigurations.shiina.config.system.build.toplevel
```

Activate Shiina:

```bash
sudo nixos-rebuild switch --flake .#shiina
```

When newly created files have not yet been added to Git, use `path:.` while
testing so flakes include them:

```bash
nix flake check path:.
```

## Validation checklist

Before switching a machine:

1. Run `nix flake check`.
2. Build the target system closure.
3. Run the VM when the relevant hardware behavior can be tested there.
4. Review changes to disks, boot, secrets, user authorization, and
   `stateVersion` especially carefully.
