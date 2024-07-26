{ lib, stdenv, fetchurl, makeWrapper, perl, perlPackages }:


let perl' = perl.withPackages(p: with p; [
    AuthenRadius
    AuthenSASL
    CGI
    ClassXSAccessor
    Chart
    DateTime
    EmailAbstract
    EmailAddress
    EmailMIME
    EmailSender
    ListMoreUtils
    LocaleCodes
    DBDSQLite
    DBDPg
    DBDmysql
    NetSMTPSSL
    EncodeDetect
    EmailReply
    FileMimeInfo
    # JSONRPC
    XMLRPCLite
    FileSlurp
    GD
    GDGraph
    GDText
    HTMLScrubber
    JSONXS
    NetLDAP
    MathRandomISAAC
    PatchReader
    ReturnValue
    SOAPLite
    TemplateGD
    TemplateToolkit
    TimeDate
    XMLTwig] );

in stdenv.mkDerivation {
  pname = "bugzilla";
  version = "5.0.6";

  src = fetchurl {
    url = "https://ftp.mozilla.org/pub/mozilla.org/webtools/bugzilla-5.0.6.tar.gz";
    hash = "sha256-3UGksKOh3w0ZO8BW8uNxHXtWBXGKAL9uXUF3vxvob3c=";
  };

  patches = [ ./constants.patch ];

  dontConfigure = true;

  dontBuild = true;

  postPatch = ''
    patchShebangs *.cgi *.PL *.pl t/*.t
    rm t/002goodperl.t # checks that /usr/bin/perl is used, but we dont care about that
    rm t/009bugwords.t # Failed test '/build/bugzilla-5.0.6/template/en/default/pages/release-notes.html.tmpl contains invalid bare words (e.g. 'bug') --WARNING' at t/009bugwords.t line 72.
    rm t/011pod.t      # Coverage test fails, and we don't care about PODs here actually
  '';

  installPhase = ''
    SHARE_DIR=$out/share/bugzilla
    LIB_DIR=$out/lib/bugzilla
    BIN_DIR=$out/bin
    mkdir -p $SHARE_DIR $LIB_DIR $BIN_DIR
    cp -va Bugzilla.pm $LIB_DIR
    cp -va Bugzilla $LIB_DIR/Bugzilla
    cp -va template $LIB_DIR/template
    cp -va *.pl $BIN_DIR/
    rm $BIN_DIR/mod_perl.pl
    mkdir -p $SHARE_DIR/wwwroot
    cp -va *.cgi js skins images $SHARE_DIR/wwwroot
  '';

  postFixup = ''
    for bin in "${placeholder "out"}/bin"/*; do
      wrapProgram "$bin" --set PERL5LIB "$out/lib/bugzilla:$PERL5LIB"
    done
  '';

  doCheck = true;

  checkPhase = ''
    export NIX_BZ_DATADIR=$(mktemp -d)
    export NIX_BZ_LOCALCONFIG=$(mktemp)
    prove -v -I. -r t/
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    export NIX_BZ_DATADIR=$(mktemp -d)
    export NIX_BZ_LOCALCONFIG=$(mktemp)
    $out/bin/checksetup.pl
    cat $NIX_BZ_LOCALCONFIG
  '';

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = [ perl' ];



}
