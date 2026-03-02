{ pkgs, ... }: {
  # Let Nix manage packages for your environment.
  environment.systemPackages = [
    pkgs.openjdk11
    pkgs.clang
    pkgs.cmake
    pkgs.ninja
    pkgs.pkg-config
  ];

  # Set environment variables
  environment.variables = {
    JAVA_HOME = "${pkgs.openjdk11}/lib/openjdk";
  };
}
