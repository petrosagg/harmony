with import <nixpkgs> {};

let
  mcl = stdenv.mkDerivation rec {
    name = "mcl";

    src = fetchFromGitHub {
      owner = "harmony-one";
      repo = name;
      rev = "99e9aa76e84415e753956c618cbc662b2f373df1";
      hash = "sha256-ee++ddQi7hneDIimTbK/MDNmSaYcQ8+9iRkaMPOwag4=";
    };

    nativeBuildInputs = [ pkgs.cmake ];
    buildInputs = [ pkgs.gmp6 pkgs.openssl ];
  };

  bls = stdenv.mkDerivation rec {
    name = "bls";

    src = fetchFromGitHub {
      owner = "harmony-one";
      repo = name;
      rev = "2b7e49894c0f15f5c40cf74046505b7f74946e52";
      hash = "sha256-lItcbhqHqX0gOoquZCB38AZ8qa+cJhaL+faV3AH1nUQ=";
    };

    nativeBuildInputs = [ pkgs.cmake ];
    buildInputs = [ mcl pkgs.gmp6 ];

    postInstall = ''
      ln -s libbls_c256.so $out/lib/libbls256.so
      ln -s libbls_c384_256.so $out/lib/libbls384_256.so
      ln -s libbls_c384.so $out/libbls384.so
    '';
  };

  hmy = buildGoModule rec {
    pname = "hmy";
    version = "1.2.9";

    src = fetchFromGitHub {
      owner = "harmony-one";
      repo = "go-sdk";
      rev = "v${version}";
      hash = "sha256-2qGEIzgWkV8cke7m+brG2WcbDxKCxOoEw8YXWY9q7bE=";
    };
    vendorSha256 = "6brgs1GeC7h4I6iaws5jNxAcFOJuEQ7X0nFGIPZmnhE=";
    runVend = true;

    buildInputs = [ bls mcl pkgs.gmp6 pkgs.openssl ];

    doCheck = false;
    subPackages = [ "cmd" ];
    postInstall = "mv $out/bin/cmd $out/bin/hmy";
  };
in buildGoModule rec {
  pname = "harmony";
  version = "4.3.8";

  src = fetchFromGitHub {
    owner = "harmony-one";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-g5Xyws0/4T78CgaZDmlnllfQVi0/Of7db5gWxYqZ/Uk=";
  };
  vendorSha256 = "BYolvb+PhaTQvhqD5aQXHA5F0f4FqO+fhfeyAijsl60=";
  runVend = true;

  nativeBuildInputs = [ hmy ];
  buildInputs = [ bls mcl pkgs.gmp6 pkgs.openssl ];

  doCheck = false;
  subPackages = [ "cmd/harmony" "cmd/bootnode" ];
}
