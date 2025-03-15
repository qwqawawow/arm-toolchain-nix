{
  fetchFromGitHub,
  clangStdenv,
  meson,
  cmake,
  libffi,
  ncurses,
  zlib,
  python3,
  git,
  ninja,
  llvmPackages_20,
  applyPatches,
  breakpointHook,
}:
let
  arm-toolchain = fetchFromGitHub {
    owner = "arm";
    repo = "arm-toolchain";
    rev = "6d70ed16afe13e31cdf4e3fab2788432521045d0";
    hash = "sha256-KGpSAcBklDjO95s77nWTPCCf8KtLLly8gB34Xh5GAYs=";
  };
  picolibc = fetchFromGitHub {
    owner = "picolibc";
    repo = "picolibc";
    rev = "fb36d6cebb7b5abd7a9497ddda9b7627b7cd0624";
    hash = "sha256-HeTjHnSdgvxKXrM/ZjpNJimEC6oIUK/qJfJtJo6HAI8=";
  };
  picolibc-patched = applyPatches {
    src = picolibc;
    patches = [
      "${arm-toolchain}/arm-software/embedded/patches/picolibc/0001-Enable-libcxx-builds.patch"
      "${arm-toolchain}/arm-software/embedded/patches/picolibc/0002-Define-picocrt_machines-for-AArch32-builds-as-well-a.patch"
      "${arm-toolchain}/arm-software/embedded/patches/picolibc/0003-Add-support-for-strict-align-no-unaligned-access-in-.patch"
    ];
  };
  revs = ''
    arm-toolchain: ${arm-toolchain.rev}
    picolibc: ${picolibc.rev}
  '';
  llvm = llvmPackages_20.llvm;
in

clangStdenv.mkDerivation rec {
  pname = "arm-toolchain";
  version = "";
  src = arm-toolchain;

  #++ lib.optional (!isDarwin) "-DBUILD_SHARED_LIBS=ON";
  sourceRoot = "./source/arm-software/embedded";
  nativeBuildInputs = [
    meson
    python3
    git
    ninja
    llvm
    meson
    cmake
    # breakpointHook
  ];
  buildInputs = [
    libffi
    ncurses
    zlib
  ];

  prePatch = ''
    echo "" > cmake/generate_version_txt.cmake 
  '';

  dontUseNinjaBuild = true;
  dontUseMesonConfigure = true;
  buildPhase = ''
    echo "${revs}" >> /build/source/arm-software/embedded/build/VERSION.txt
    cmake .. -GNinja #-DFETCHCONTENT_SOURCE_DIR_PICOLIBC=../repos/picolibc
    ninja -v llvm-toolchain
  '';
  outputs = [
    "out"
    "doc"
    "samples"
  ];
  installPhase = ''
    runHook preInstall

    cmake . --install-prefix $out
    ninja install-llvm-toolchain
    mv $out/docs $doc
    mv $out/samples $samples

    runHook postInstall
  '';

  # stripExclude = [
  #   "CHANGELOG.md"
  #   "README.md"
  #   "THIRD-PARTY-LICENSES.txt"
  #   "docs/*"
  #   "include/*"
  #   "lib/*"
  #   "samples/*"
  #   "third-party-licenses/*"
  #   "version.txt"
  # ];
  cmakeFlags = [
    "-DLLVM_TABLEGEN_EXE=${llvm.out}/bin/llvm-tblgen"
    "-DLLVM_TOOLS_BINARY_DIR=${llvm.out}/bin"
    "-DLLVM_BINARY_DIR=${llvm.out}"
    "-DLLVM_CONFIG=${llvm.dev}/bin/llvm-config"
    "-DLLVM_LIBRARY_DIR=${llvm.lib}/lib"
    "-DLLVM_MAIN_INCLUDE_DIR=${llvm.dev}/include"
    "-Darmtoolchain_COMMIT=${arm-toolchain.rev}" # NOT WORKING
    "-Dpicolibc_COMMIT=${picolibc.rev}" # NOT WORKING
    #"-DLLVM_BUILD_TOOLS=Off"
    #"-DC_INCLUDE_DIRS=${clangStdenv.cc.libc.dev}/include"
    "-GNinja"
    "-DCMAKE_BUILD_TYPE=Release"
    # "-DLLVM_ENABLE_RUNTIMES=libcxx;libcxxabi"
    "-DLLVM_TARGETS_TO_BUILD='X86;ARM;AArch64'"
    "-DLLVM_BUILD_TESTS=OFF"
    "-DENABLE_QEMU_TESTING=OFF"
    "-DFETCHCONTENT_SOURCE_DIR_PICOLIBC=${picolibc-patched}"
    #"-DLLVM_TARGETS_TO_BUILD=host"
  ];

}
