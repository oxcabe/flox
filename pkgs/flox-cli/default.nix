{
  self,
  lib,
  rustPlatform,
  hostPlatform,
  openssl,
  pkg-config,
  darwin,
  flox,
  nix,
  pandoc,
  cacert,
  glibcLocales,
  installShellFiles,
}: let
  cargoToml = lib.importTOML (self + "/crates/flox-cli/Cargo.toml");

  envs =
    {
      NIX_BIN = "${nix}/bin/nix";
      FLOX_SH = "${flox}/libexec/flox/flox";
      NIXPKGS_CACERT_BUNDLE_CRT = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    }
    // lib.optionalAttrs hostPlatform.isDarwin {
      NIX_COREFOUNDATION_RPATH = "${darwin.CF}/Library/Frameworks";
      PATH_LOCALE = "${darwin.locale}/share/locale";
    }
    // lib.optionalAttrs hostPlatform.isLinux {
      LOCALE_ARCHIVE = "${glibcLocales}/lib/locale/locale-archive";
    };
in
  rustPlatform.buildRustPackage ({
      pname = cargoToml.package.name;
      version = cargoToml.package.version;
      src = self;

      cargoLock = {
        lockFile = self + "/Cargo.lock";
      };

      buildAndTestSubdir = "crates/flox-cli";

      doCheck = false;

      postInstall = ''
        pandoc --standalone -t man ${self.inputs.floxpkgs.inputs.flox}/flox.1.md -o flox.1
        installManPage flox.1
      '';

      buildInputs =
        [
          openssl.dev
        ]
        ++ lib.optional hostPlatform.isDarwin [
          darwin.apple_sdk.frameworks.Security
        ];

      nativeBuildInputs = [
        pkg-config # for openssl
        pandoc
        installShellFiles
      ];

      passthru.envs = envs;
    }
    // envs)