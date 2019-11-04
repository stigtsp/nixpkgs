{ stdenv, python2Packages, fetchzip }:

with python2Packages;
buildPythonApplication rec {
  pname = "mysql-utilities";
  version = "1.6.5";

  src = fetchzip {
    url = "https://downloads.mysql.com/archives/get/file/${pname}-${version}.zip";
    sha256 = "1f0c35mrpb4gsy5m8lrqyi49hy7vai3n5fklmn9jgs2x3r14byhs";
  };

  propagatedBuildInputs = [ configparser ];

  meta = with stdenv.lib; {
    homepage = "https://downloads.mysql.com/archives/utilities/";
    description = "Utilities that are used for maintenance and administration of MySQL servers";
    license = licenses.gpl2;
    maintainers = [ maintainers.sgo ];
  };
}
