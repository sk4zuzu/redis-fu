with import <nixpkgs> {};
let
  removeNewLineChars = string:
    builtins.replaceStrings [ "\n" ] [ " " ]
    string;
  defaultPackages = with pkgs; [
    vim mc htop
    ethtool curl ncat
  ];
  default = systemPackages: configUpdate: { ... }: lib.recursiveUpdate {
    environment.systemPackages = systemPackages;
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 2380 2377 ];
    };
    virtualisation.docker = {
      enable = true;
      liveRestore = false;
    };
    services.etcd = {
      enable = true;
      initialCluster = [
        "swarm1=http://swarm1:2380"
        "swarm2=http://swarm2:2380"
        "swarm3=http://swarm3:2380"
      ];
      listenPeerUrls = [ "http://0.0.0.0:2380" ];
      listenClientUrls = [ "http://127.0.0.1:2379" ];
    };
    systemd.services.swarm-bootstrap = {
      serviceConfig = {
        Type = "simple";
        ExecStart = removeNewLineChars ''
          ${pkgs.bash}/bin/bash -lc '
            docker node inspect "$HOSTNAME" --format="{{ .Status.State }}"
            || (etcdctl get swarm/join-token/manager
            | xargs -d"\n" sh -c)
          '
        '';
        Restart = "on-failure";
        RestartSec = "8s";
      };
      requires = [ "etcd.service" "docker.service" ];
      wantedBy = [ "multi-user.target" ];
    };
  } configUpdate;
in {
  swarm1 = default defaultPackages {
    systemd.services.swarm-bootstrap.serviceConfig.ExecStart = removeNewLineChars ''
      ${pkgs.bash}/bin/bash -lc '
        docker node inspect "$HOSTNAME" --format="{{ .Status.State }}"
        || (docker swarm init --advertise-addr=`ip r s to 0/0
        | grep -o "dev [^ ]*"
        | grep -o "[^ ]*\$"`
        && docker swarm join-token manager
        | grep token
        | xargs
        | etcdctl set swarm/join-token/manager)
      '
    '';
    services.etcd.initialAdvertisePeerUrls = [ "http://swarm1:2380" ];
  };
  swarm2 = default defaultPackages {
    services.etcd.initialAdvertisePeerUrls = [ "http://swarm2:2380" ];
  };
  swarm3 = default defaultPackages {
    services.etcd.initialAdvertisePeerUrls = [ "http://swarm3:2380" ];
  };
}
# vim:ts=2:sw=2:et:syn=nix:
