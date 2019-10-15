{ stdenv, fetchurl, perl, icu, zlib, gmp, readline, moarvm
, CoreServices, ApplicationServices }:

stdenv.mkDerivation rec {
  pname = "nqp";
  version = "2019.07.1";

  src = fetchurl {
    url    = "https://github.com/perl6/nqp/releases/download/2019.07.1/nqp-2019.07.1.tar.gz";
    sha256 = "0912n50psvklxaawd33pr5qz1xdx0migpjd30crhdi8396wfa93k";
  };

  buildInputs = [ icu zlib gmp readline perl ]
    ++ stdenv.lib.optionals stdenv.isDarwin [ CoreServices ApplicationServices ];
  configureScript = "perl ./Configure.pl";
  configureFlags = [ "--backends=moar" "--prefix=${moarvm}" ];

  meta = with stdenv.lib; {
    description = "Not Quite Perl -- a lightweight Raku-like environment for virtual machines";
    homepage    = "https://github.com/perl6/nqp";
    license     = licenses.artistic2;
    platforms   = platforms.unix;
    maintainers = with maintainers; [ thoughtpolice vrthra ];
  };
}
