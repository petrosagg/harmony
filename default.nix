with import <nixpkgs> {};

let
  bls = stdenv.mkDerivation rec {
    name = "bls";

    srcs = [
      (fetchFromGitHub {
        owner = "harmony-one";
        repo = name;
        rev = "2b7e49894c0f15f5c40cf74046505b7f74946e52";
        hash = "sha256-lItcbhqHqX0gOoquZCB38AZ8qa+cJhaL+faV3AH1nUQ=";
        name = name;
      })
      (fetchFromGitHub {
        owner = "harmony-one";
        repo = "mcl";
        rev = "99e9aa76e84415e753956c618cbc662b2f373df1";
        hash = "sha256-ee++ddQi7hneDIimTbK/MDNmSaYcQ8+9iRkaMPOwag4=";
        name = "mcl";
      })
    ];

    sourceRoot = name;

    dontUseCmakeConfigure = true;

    buildInputs = [ pkgs.gmp6 pkgs.openssl ];

    makeFlags = [ "-j8" "PREFIX=$(out)" ];

    preBuild = "chmod -R u+w ../mcl";
    postInstall = "make -C ../mcl install 'PREFIX=$(out)'";
  };

  hmy = buildGoModule rec {
    pname = "hmy";
    version = "v1-e59f6c2";

    src = fetchFromGitHub {
      owner = "harmony-one";
      repo = "go-sdk";
      rev = "e59f6c2304c7753623e10a675ef3929854237cff";
      hash = "sha256-2qGEIzgWkV8cke7m+brG2WcbDxKCxOoEw8YXWY9q7bE=";
    };
    vendorSha256 = "sha256-6brgs1GeC7h4I6iaws5jNxAcFOJuEQ7X0nFGIPZmnhE=";
    runVend = true;

    buildInputs = [ bls pkgs.gmp6 pkgs.openssl ];

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
  buildInputs = [ bls pkgs.gmp6 pkgs.openssl ];

  doCheck = false;
  subPackages = [ "cmd/harmony" "cmd/bootnode" ];
}
