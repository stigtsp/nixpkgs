import ./make-test-python.nix ({ lib, pkgs, ... }:

let
  port = 8890;
in
{
  name = "n3n";
  meta.maintainers = with lib.maintainers; [ sgo ];

  nodes = {
    supernode =
      { pkgs, ... }:
      {
        services.n3n.enable = true;
        services.n3n.supernode = {
          enable = true;
          listenPort = port;
                    otherSupernodes = [ "foo:1234" ];
        };
        services.n3n.edge = {
           enable = true;
           sessionName = "mynetwork";
           community   = "mygroup";
           key = "hunter2";
           supernode = "n3n://supernode:1234/PUBKEY-hjdsayikdaydasgdasgdasgk";
           ip = false;
           acceptDHCP = true;
         };
      };

# n3n://mygroup/uidsahdahdasjkdjhlkashjldsahjda/supernode=blabla

    node0 =
       { pkgs, ... }:
       {
         services.n3n.enable = true;
         services.n3n.edge = {
           enable = true;
           sessionName = "mynetwork";
           community   = "mygroup";
           key = "hunter2";
           supernode = "supernode:${toString port}";
           ip = "192.168.1.10";
         };
       };
    node1 =
       { pkgs, ... }:
       {
         services.n3n = {
           enable = true;
           sessions.mygroup = {
             ip         = [ "192.168.1.11/16" ];
             key        = "hunter2";
             supernodes = [ "supernode:7777" "verysupernode:1234" ];
           }
         };
       };
  };

  testScript = ''
    supernode.wait_for_unit("n3n-supernode")
    supernode.wait_for_open_port(${toString port})

    node0.wait_for_unit("n3n-edge")
    node1.wait_for_unit("n3n-edge")

    node0.wait_until_succeeds("ping -c 1 supernode")
    node0.wait_until_succeeds("ping -c 1 192.168.1.11")

    node1.wait_until_succeeds("ping -c 1 supernode")
    node1.wait_until_succeeds("ping -c 1 192.168.1.10")

  '';
})
