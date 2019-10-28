{ stdenv, lib, rustPlatform, fetchFromGitHub, pkgconfig, ncurses, python3, openssl, libgpgerror, gpgme, xorg }:

with rustPlatform;
buildRustPackage rec {
  version = "0.2.1";
  pname = "ripasso-cursive";

  src = fetchFromGitHub {
    owner = "cortex";
    repo = "ripasso";
    rev  = "release-${version}";
    sha256 = "1ank59hx2yc6vdfd7i3z3svcmn770pnigdb0v7i66isw835h9p5m";
  };

  cargoSha256 = "138nqannldrihzmd06sb4x2lw9aafq54qp8s06b5bnypcm63772q";
  cargoBuildFlags = [ "-p ripasso-cursive -p ripasso-man" ];

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [
    ncurses python3 openssl libgpgerror gpgme xorg.libxcb
  ];

  preFixup = ''
    mkdir -p "$out/man/man1"
    $out/bin/ripasso-man > $out/man/man1/ripasso-cursive.1
    rm $out/bin/ripasso-man
  '';

  meta = with stdenv.lib; {
    description = "A simple password manager written in Rust";
    homepage = "https://github.com/cortex/ripasso";
    license = licenses.gpl3;
    maintainers = with maintainers; [ sgo ];
    platforms = platforms.unix;
  };
}
