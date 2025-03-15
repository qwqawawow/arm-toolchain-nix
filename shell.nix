with import <nixpkgs> { };
let
  gccForLibs = stdenv.cc.cc;
in

stdenv.mkDerivation {
  name = "llvm-env";
  buildInputs = [
    bashInteractive
    python3
    ninja
    cmake
    llvmPackages_20.llvm
    meson
    glibc_multi
  ];
  # cmake  -DFETCHCONTENT_SOURCE_DIR_PICOLIBC=./_deps/picolibc-src  $cmakeFlags .. -GNinja -DFETCHCONTENT_QUIET=OFF
  #
  #

  # FIXME: where to find libgcc
  #SOLVED: USING LD_LIBRARY_PATH
  # FIXME: https://github.com/llvm/llvm-project/issues/53561#issuecomment-1133752590
  # FIXME fix this issue abount 14.2.1
  # 官网的doc的版本是有问题的
  NIX_LDFLAGS = "-L${gccForLibs}/lib/gcc/${targetPlatform.config}/14.2.1";
  # teach clang about C startup file locations

  #NOTE: Libgcc.lib
  #NOTE: export LD_LIBRARY_PATH=/nix/store/2lhklm5aizx30qbw49acnrrzkj9lbmij-gcc-14-20241116-lib/lib/:$LD_LIBRARY_PATH
  #NOTE: Wroks On my machine
  CFLAGS = "-B${gccForLibs}/lib/gcc/${targetPlatform.config}/14.2.1 -B${stdenv.cc.libc}/lib ";
  #env.CCC_OVERRIDE_OPTIONS = "--gcc-toolchain=${gccForLibs}";
  #env.CCC_OVERRIDE_OPTIONS = "--gcc-install-dir=${gccForLibs}";
  #
  #
  shellHook = ''
    export CC=clang
    export CXX=clang++
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${libgcc.lib}/lib64/
    #libgcc.lib
    #
  '';
  cmakeFlags = [
    #"-DCCC_OVERRIDE_OPTIONS=--gcc-install-dir=${gccForLibs}"
    #"-DGCC_INSTALL_PREFIX=${gcc}"
    "-DLLVM_TABLEGEN_EXE=${llvmPackages_20.llvm.out}/bin/llvm-tblgen"
    "-DLLVM_TOOLS_BINARY_DIR=${llvmPackages_20.llvm.out}/bin"
    "-DC_INCLUDE_DIRS=${stdenv.cc.libc.dev}/include"
    "-GNinja"
    # Debug for debug builds
    "-DCMAKE_BUILD_TYPE=Release"
    # inst will be our installation prefix
    #"-DCMAKE_INSTALL_PREFIX=../inst"
    #"-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON"
    # change this to enable the projects you need
    #"-DLLVM_ENABLE_PROJECTS=clang"
    # enable libcxx* to come into play at runtimes
    # "-DLLVM_ENABLE_RUNTIMES=libcxx;libcxxabi"
    # this makes llvm only to produce code for the current platform, this saves CPU time, change it to what you need
    "-DLLVM_TARGETS_TO_BUILD='X86;ARM;AArch64'"
    "-DLLVM_BUILD_TESTS=OFF"
    #"-DLLVM_TARGETS_TO_BUILD=host"
  ];
}
