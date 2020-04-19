let
  overlayRev = "84591bc733bef95d69bb07895ac7f8d34cd6b8a3";
  emacs-overlay = import (builtins.fetchTarball {
    url = "https://github.com/nix-community/emacs-overlay/archive/${overlayRev}.tar.gz";
  });
in
{ pkgs ? import <nixpkgs> { overlays = [ emacs-overlay ]; } }:

let
  # Declare extra programs my Emacs config expects to be installed to function
  # properly.
  requiredPrograms = with pkgs; [
    (aspellWithDicts (ps: [ps.en]))
    autoconf
    clang
    cmake
    htmlTidy
    multimarkdown
    shellcheck
    sqlite
    tectonic
    texinfo
  ];

  # Language servers

  emmyLuaJar = pkgs.fetchurl rec {
    name = "emmy-lua.jar";
    url = "https://ci.appveyor.com/api/buildjobs/sq7l4h55stcyt4hy/artifacts/EmmyLua-LS%2Fbuild%2Flibs%2FEmmyLua-LS-all.jar";
    sha256 = "0pxnbrfb6n3y6a82c41f2ldnpb2r0b18z5d6c0azril5zfwjrk6l";
  };

  # Build a custom Emacs version. It has a few fixes to make it work better with
  # yabai in macOS.
  emacs = pkgs.emacsGit.overrideAttrs (old: {
    withCsrc = true;

    patches = old.patches ++ [
      ./patches/emacs/0001-optional-org-gnus.patch
      ./patches/emacs/0002-fix-window-role.patch
      ./patches/emacs/0003-no-frame-refocus.patch
      ./patches/emacs/0004-no-titlebar.patch
      ./patches/emacs/0005-dont-warn-on-archives.patch
      ./patches/emacs/0006-prettier-ibuffer.patch
    ];

    postPatch = ''
      ${old.postPatch}

      # Delete the built-in orgmode.
      rm -r test/lisp/org lisp/org etc/org etc/ORG-NEWS doc/misc/org.texi
    '';
  });

  packages = pkgs.callPackage ./packages.nix rec {

    emacsmirror = args:
      github (args // { owner = "emacsmirror"; });

    github = { name, repo ? name, rev, owner, sha256, buildInputs ? [], patches ? [] }:
      pkgs.callPackage ./builder.nix {
        inherit emacs name buildInputs patches;
        src = pkgs.fetchFromGitHub {
          inherit sha256 repo rev owner;
        };
      };

    withPatches = pkg: patches:
      pkg.overrideAttrs (attrs: { inherit patches; });
  };

  builder = pkgs.emacsPackagesNgGen emacs;

  emacsWithPackages = (builder.overrideScope' packages.overrides).emacsWithPackages packages.packages;
in
pkgs.symlinkJoin {
  name = "emacs-wrapped";
  buildInputs = [pkgs.makeWrapper];
  paths = [emacsWithPackages] ++ requiredPrograms;
  postBuild = ''
    wrapProgram "$out/bin/emacs" \
      --set NIX_EMACS_EMMY_LUA_JAR "${emmyLuaJar}" \
      --set JAVA_HOME "${pkgs.jdk}"
  '';

}
