class Univim < Formula
  desc "Vim-mode for macOS text fields, plus Vietnamese Telex/VNI input"
  homepage "https://github.com/flyznex/univim"
  head "https://github.com/flyznex/univim.git", branch: "master"
  depends_on :macos

  def install
    # lib/libvim.a and lib/libunikey.a are committed prebuilt (not rebuilt
    # from the libvim/libunikey submodule sources on every build) -- `make
    # lib` is a separate, occasional step for updating libvim.a from a newer
    # submodule commit, not part of a normal build. Calling it here isn't
    # just unnecessary: libvim's vendored vim-derived ./configure fails to
    # detect a usable ncurses under Homebrew's sandboxed build env even
    # though it's present, so running it breaks a build that would
    # otherwise just work with the checked-in .a files.
    system "make", "app"
    libexec.install "bin/UniVim.app"
    libexec.install "scripts/ensure_codesign_cert.sh"
    bin.install_symlink libexec/"UniVim.app/Contents/MacOS/univim"
  end

  def post_install
    # Deliberately not part of `install`: that runs inside Homebrew's build
    # sandbox, which blocks writing to the real login keychain entirely.
    # Signs with a stable per-machine identity instead of the linker's
    # default ad-hoc signature, so Accessibility permission survives
    # rebuilds/reinstalls instead of needing to be re-granted every time.
    system libexec/"ensure_codesign_cert.sh", "univim-cert"
    system "codesign", "--force", "--sign", "univim-cert", (libexec/"UniVim.app").to_s
  end

  service do
    run [opt_libexec/"UniVim.app/Contents/MacOS/univim"]
    keep_alive true
    process_type :interactive
    log_path var/"log/univim.log"
    error_log_path var/"log/univim.log"
  end

  test do
    assert_path_exists libexec/"UniVim.app/Contents/MacOS/univim"
  end
end
