{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.bugzilla;
  dataDir = "/var/lib/bugzilla";
  user = "bugzilla";
  group = "bugzilla";
  localConfig =
    if cfg.localConfig == null
    then
      ''
        # $create_htaccess = 1;
        $webservergroup = 'apache';
        $use_suexec = 0;
        $db_driver = 'sqlite';
        #$db_host  = 'localhost';
        $db_name   = 'bugs';
        #$db_user  = 'bugs';
        #$db_pass  = "";
        $db_port   = 0;
        $db_sock   = "";
        $db_check = 1;
        $db_mysql_ssl_ca_file = "";
        $db_mysql_ssl_ca_path = "";
        $db_mysql_ssl_client_cert = "";
        $db_mysql_ssl_client_key = "";
        $index_html = 0;
        $interdiffbin = "";
        $diffpath = '/nix/store/8ynk6xvczjnjv81bfghkjwrap0hn6qah-diffutils-3.10/bin';
        chomp($site_wide_secret = qx(cat /run/bugzilla/secret))
      ''
    else
      cfg.localConfig;
    localConfigFile = pkgs.writeText "bz-localconfig" localConfig;
in
{
  options.services.bugzilla = {
    enable = mkEnableOption "Bugzilla";
    package = mkPackageOption pkgs "bugzilla" { };
    localConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      description = ''
          Contents of localconfig
        '';
      };
  };
  config = mkIf cfg.enable {

    users.users.${user} = {
      description = "Sympa mailing list manager user";
      group = group;
      home = dataDir;
      createHome = false;
      isSystemUser = true;
    };

    users.groups.${group} = {};


    systemd.services.bugzilla = {
      wantedBy = [ "multi-user.target" ];
      after = [ "httpd.service" ];
      serviceConfig = {
        # TODO: hardening, DynamicUser = true;
        Type = "forking";
        PIDFile = "/run/bugzilla/fcgi.pid";
        Restart = "on-failure";
        RuntimeDirectory = "bugzilla";
        StateDirectory = "bugzilla";
        WorkingDirectory = "${cfg.package}/share/webroot";
        RestartSec = "5s";
        ExecStartPre = ''
          umask 0077
          if [ ! -f /var/lib/bugzilla/secret ]; then
            tr -dc A-Za-z0-9 < /dev/urandom | head -c$${1:-44} > /var/lib/bugzilla/secret
            chown ${user}:${group} /var/lib/bugzilla/secret
          fi
        '';
        ExecStart = ''${pkgs.spawn_fcgi}/bin/spawn-fcgi \
          -u ${user} \
          -g ${group} \
          -U nginx \
          -M 0600 \
          -F 4 \
          -P /run/bugzilla/fcgi.pid \
          -s /run/bugzilla/fcgi.socket
        '';
      };
    };
  };
}
