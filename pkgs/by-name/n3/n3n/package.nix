{ lib, stdenv, fetchFromGitHub, autoreconfHook, pkg-config, libcap, perl, python3 }:

stdenv.mkDerivation rec {
  pname = "n3n";
  version = "3.3.4";

  src = fetchFromGitHub {
    owner = "n42n";
    repo = "n3n";
    rev = version;
    hash = "sha256-qOAQo8eIlX4pGo9+B9gMGnSEADe+Z5oN6SgkrGZnyLY=";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config perl ];

  buildInputs = [
    libcap python3
  ];

  postPatch = ''
    patchShebangs .
  '';

  installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp scripts/n3nctl apps/n3n-edge apps/n3n-supernode $out/bin

      runHook postInstall
  '';

  preAutoreconf = ''
    ./autogen.sh
  '';

  meta = with lib; {
    description = "Peer-to-peer VPN";
    homepage = "https://github.com/n42n/n3n";
    license = licenses.gpl3;
    maintainers = with maintainers; [ sgo ];
  };
}
