with import <nixpkgs> {};
let
  default = {
    deployment.targetEnv = "libvirtd";
    deployment.libvirtd = {
      headless = true;
      memorySize = 1024;
    };
  };
in {
  swarm1 = default;
  swarm2 = default;
  swarm3 = default;
}
# vim:ts=2:sw=2:et:syn=nix:
