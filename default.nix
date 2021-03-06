let
  # 2020-07-04
  overlayRev = "688ab439915132b99fa8b8b94d2ae432a9ba201e";
  emacs-overlay = import (builtins.fetchTarball {
    url =
      "https://github.com/nix-community/emacs-overlay/archive/${overlayRev}.tar.gz";
  });
in { pkgs ?
  import <nixpkgs> { overlays = [ emacs-overlay (import ./overlays) ]; } }:

let
  inherit (pkgs.lib) strings;

  # Additional programs to be injected into Emacs' environment.

  requiredPrograms = pkgs.symlinkJoin {
    name = "emacs-required-programs";
    paths = with pkgs; [
      (aspellWithDicts (ps: [ ps.en ]))
      graphviz
      htmlTidy
      multimarkdown
      nixfmt
      nodejs
      ripgrep
      shellcheck
      sqlite
      tectonic
    ];
  };

  languageServers = pkgs.callPackage ./language-servers { };

  # Build a custom Emacs version. It's pinned to a specific version and has a
  # few fixes to make it work better with yabai in macOS.
  emacs = pkgs.emacsGit.overrideAttrs (old: rec {
    name = "emacs-git-${version}";
    version = "20200329.0";
    withCsrc = true;

    src = pkgs.fetchFromGitHub {
      owner = "emacs-mirror";
      repo = "emacs";
      rev = "3273e2ace788a58bef77cef936021d151815ea94";
      sha256 = "04scsvfq5id3992apwawh7w54zfivgn60bkl6j6ph7viwk6pw0vk";
    };

    patches = [
      ./patches/emacs/tramp-detect-wrapped-gvfsd.patch
      ./patches/emacs/clean-env.patch
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

    emacsmirror = args: github (args // { owner = "emacsmirror"; });

    github = { name, repo ? name, rev, owner, sha256, buildInputs ? [ ]
      , patches ? [ ] }:
      pkgs.callPackage ./builder.nix {
        inherit emacs name buildInputs patches;
        src = pkgs.fetchFromGitHub { inherit sha256 repo rev owner; };
      };

    withPatches = pkg: patches: pkg.overrideAttrs (attrs: { inherit patches; });
  };

  builder = pkgs.emacsPackagesNgGen emacs;

  emacsWithPackages =
    (builder.overrideScope' packages.overrides).emacsWithPackages
    packages.packages;

  customPathEntries = strings.concatStringsSep ":" [
    "${languageServers}/bin"
    "${requiredPrograms}/bin"
    # Packaged by node2nix, cannot be symlink-joined into requiredPrograms or it
    # will clobber other entries.
    "${pkgs.prettier}/bin"
  ];
in pkgs.symlinkJoin {
  name = "emacs-wrapped";
  buildInputs = [ pkgs.makeWrapper ];
  paths = [ emacsWithPackages ];
  postBuild = ''
    for program in "$out/Applications/Emacs.app/Contents/MacOS/Emacs" "$out/bin/emacs"; do
      if [ -f "$program" ]; then
        wrapProgram "$program" \
          --prefix PATH ":" "${customPathEntries}" \
          --set NIX_EMACS_PATH_EXTRAS "${customPathEntries}" \
          --set NIX_EMACS_LSP_ESLINT_NODE_PATH "${pkgs.nodejs}/bin/node" \
          --set NIX_EMACS_MU_BINARY "${pkgs.mu}/bin/mu" \
          --set NIX_EMACS_EMMY_LUA_JAR "${languageServers}/lib/emmy-lua.jar" \
          --set NIX_EMACS_GROOVY_LANGUAGE_SERVER_JAR "${languageServers}/lib/groovy-language-server-all.jar" \
          --set JAVA_HOME "${pkgs.jdk}"
      fi
    done
  '';

}
