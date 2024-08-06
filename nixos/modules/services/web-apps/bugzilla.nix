{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.bugzilla;
  dataDir = "/var/lib/bugzilla";
  rootDir = "${cfg.package}/share/bugzilla/wwwroot";
  user = "bugzilla";
  group = "bugzilla";
  initialConfig = pkgs.writeText "bugzillaz-initial-config" ''
    # All answers must be there for checksetup.pl to succeed
    $answer{'create_htaccess'} = 0;
    $answer{'webservergroup'} = "${group}";
    $answer{'use_suexec'} = 0;
    $answer{'db_mysql_ssl_ca_file'} = "";
    $answer{'db_mysql_ssl_ca_path'} = "";
    $answer{'db_mysql_ssl_client_cert'} = "";
    $answer{'db_mysql_ssl_client_key'} = "";
    $answer{'index_html'} = 0;
    $answer{'interdiffbin'} = "";
    $answer{'diffpath'} = "${pkgs.diffutils}/bin/";
    $answer{'db_sock'}   = "";
    $answer{'db_check'}  = 1;
    $answer{'db_host'}   = 'localhost';
    $answer{'db_driver'} = 'sqlite';
    $answer{'db_port'}   = 0;
    $answer{'db_name'}   = 'bugs';
    $answer{'db_user'}   = 'bugs';
    $answer{'db_pass'}   = 'bugs';
    $answer{'urlbase'} = 'http://${cfg.hostname}/'; # XXX: Patch to accept https URLs
    $answer{'ADMIN_EMAIL'} = 'myadmin@mydomain.net';
    $answer{'ADMIN_PASSWORD'} = 'fooey'; # XXX: Patch to acccept encrypted password
    $answer{'ADMIN_REALNAME'} = 'Joel Peshkin';
    $answer{'NO_PAUSE'} = 1
  '';
in
{
  options.services.bugzilla = {
    enable = mkEnableOption "Bugzilla";
    package = mkPackageOption pkgs "bugzilla" { };
    hostname = mkOption {
      type = types.str;
      default = "localhost";
      example = "bugzilla.example.com";
        description = ''
          VirtualHost to configure nginx for
        '';
      };
  };
  config = mkIf cfg.enable {

    users.users.${user} = {
      description = "Bugzilla user";
      group = group;
      home = dataDir;
      createHome = false;
      isSystemUser = true;
    };

    users.groups.${group} = {};

    services.memcached.enable = true;

    services.nginx = {
      enable = true;
      virtualHosts.${cfg.hostname} = {
        locations."/" = {
          root = rootDir;
        };
        locations."~ ^.*\\.cgi$".extraConfig = ''
           fastcgi_index index.cgi;
           fastcgi_pass  unix:/run/bugzilla/fcgi.socket;
           fastcgi_param SCRIPT_FILENAME ${rootDir}/$fastcgi_script_name;
           include       ${config.services.nginx.package}/conf/fastcgi_params;
        '';
      };
    };

    systemd.services.bugzilla = {
      wantedBy = [ "multi-user.target" ];
      before = [ "nginx.service" ];
      environment = {
        NIX_BZ_DATADIR = dataDir;
        NIX_BZ_LOCALCONFIG = "/run/bugzilla/localconfig";
        TZ = "UTC"; # XXX: bugzilla-pre-start[713]: DBD::SQLite::st execute failed: Cannot determine local time zone
      };
      preStart = ''
        mkdir -p /run/bugzilla
        mkdir -p /var/lib/bugzilla
        chown ${user}:${group} /run/bugzilla

        echo "\$site_wide_secret = \"`head -c 32 /dev/urandom | base64`\";" >> /run/bugzilla/localconfig
        chown -R ${user}:${group} /var/lib/bugzilla

        # XXX: Forcing true here after maybe successful 'install_setting_setup'
        ${cfg.package}/bin/checksetup.pl --no-templates --verbose ${initialConfig} || true
      '';
      serviceConfig = {
        # TODO: hardening, DynamicUser = true;
        Type = "forking";
        PIDFile = "/run/bugzilla/fcgi.pid";
        WorkingDirectory = rootDir;
        RestartSec = "5s";
        ExecStart = ''${pkgs.spawn_fcgi}/bin/spawn-fcgi \
          -u ${user} \
          -U nginx \
          -M 0600 \
          -d ${rootDir} \
          -F 1 \
          -P /run/bugzilla/fcgi.pid \
          -s /run/bugzilla/fcgi.socket \
          -- ${pkgs.fcgiwrap}/bin/fcgiwrap

        '';
      };
    };
  };
}
