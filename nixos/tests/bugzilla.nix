import ./make-test-python.nix ({ lib, pkgs, ... }:


{
  name = "bugzilla";
  meta.maintainers = with lib.maintainers; [ sgo ];

  nodes = {
    machine =
      { pkgs, ... }:
      {
        services.bugzilla = {
          enable = true;
          hostname = "localhost";
        };
      };
  };

  testScript = ''
    machine.wait_for_unit("bugzilla")
    machine.wait_for_open_port(80)
    machine.succeed("curl -f http://localhost/index.cgi 1>&2")
  '';
})
