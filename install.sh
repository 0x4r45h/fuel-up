#!/bin/sh
set -e

FUELUP_DIR=${FUELUP_DIR-"$HOME/.fuelup"}

main() {
  need_cmd git
  need_cmd curl
  need_cmd chmod
  need_cmd mkdir
  need_cmd rm
  need_cmd rmdir

  check_cargo_bin forc
  check_cargo_bin forc-fmt
  check_cargo_bin forc-lsp
  check_cargo_bin fuel-core

  get_architecture || return 1
  local _arch="$RETVAL"
  assert_nz "$_arch" "arch"

  mkdir -p "$FUELUP_DIR/bin"

  local _fuelup_version
  local _published_fuelup_version_url="https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/fuelup-version"
  _fuelup_version="$(curl -s $_published_fuelup_version_url)"

  if echo "$_fuelup_version" | grep -q -E '404|400'; then
    warn "fuelup-version not found on fuelup gh-pages; falling back to GitHub API."
    _fuelup_version="$(curl -s https://api.github.com/repos/FuelLabs/fuelup/releases/latest | grep "tag_name" | cut -d "\"" -f4 | cut -c 2-)"
  fi

  local _fuelup_url="https://github.com/FuelLabs/fuelup/releases/download/v${_fuelup_version}/fuelup-${_fuelup_version}-${_arch}.tar.gz"
  local _dir
  _dir="$(ensure mktemp -d)"
  local _file="${_dir}/fuelup.tar.gz"

  local _ansi_escapes_are_valid=false
  if [ -t 2 ] && [ "${TERM+set}" = "set" ]; then
    case "$TERM" in
      xterm* | rxvt* | urxvt* | linux* | vt*)
        _ansi_escapes_are_valid=true
        ;;
    esac
  fi

  local prompt_modify="yes"
  local skip_toolchain_installation="no"

  for arg in "$@"; do
    case "$arg" in
      --no-modify-path)
        prompt_modify="no"
        ;;
      --skip-toolchain-installation)
        skip_toolchain_installation="yes"
        ;;
      *)
        ;;
    esac
  done

  if [ "$prompt_modify" = "yes" ]; then
    case $SHELL in
      */bash)
        SHELL_PROFILE="$HOME/.bashrc"
        ;;
      */zsh)
        SHELL_PROFILE="$HOME/.zshrc"
        ;;
      */fish)
        SHELL_PROFILE="$HOME/.config/fish/config.fish"
        ;;
      *)
        warn "Failed to detect shell; please add ${FUELUP_DIR}/bin to your PATH manually."
        ;;
    esac
  fi

  printf 'info: downloading fuelup %s\n' "$_fuelup_version" 1>&2
  ensure downloader "$_fuelup_url" "$_file" "$_arch"
  ignore tar -xf "$_file" -C "$_dir"
  ensure mv "$_dir/fuelup-${_fuelup_version}-${_arch}/fuelup" "$FUELUP_DIR/bin/fuelup"
  ensure chmod u+x "$FUELUP_DIR/bin/fuelup"

  if [ ! -x "$FUELUP_DIR/bin/fuelup" ]; then
    printf '%s\n' "Cannot execute $FUELUP_DIR/bin/fuelup." 1>&2
    printf '%s\n' "Please copy the file to a location where you can execute binaries and run ./fuelup." 1>&2
    exit 1
  fi

  if [ "$skip_toolchain_installation" = "no" ]; then
    ignore "$FUELUP_DIR/bin/fuelup" "toolchain" "install" "latest"
  fi

  local _retval=$?
  ignore rm "$_file"
  ignore rmdir "$_dir/fuelup-${_fuelup_version}-${_arch}"
  ignore rmdir "$_dir"

  printf '\n'
  printf '%s\n' "fuelup ${_fuelup_version} has been installed in $FUELUP_DIR/bin."
  printf '%s\n' "Run 'fuelup toolchain install latest' to fetch the latest toolchain."
  printf '%s\n' "To generate completions for your shell, run 'fuelup completions --shell=SHELL'."

  if [ "$prompt_modify" = "yes" ]; then
    if echo "$PATH" | grep -q "$FUELUP_DIR/bin"; then
      printf "\n%s/bin already exists in your PATH.\n" "$FUELUP_DIR"
    else
      echo "export PATH=\"\$HOME/.fuelup/bin:\$PATH\"" >>"$SHELL_PROFILE"
      printf "\n%s added to PATH. Run 'source %s' or start a new terminal session to use fuelup.\n" "$FUELUP_DIR" "$SHELL_PROFILE"
    fi
  else
    add_path_message
  fi

  return "$_retval"
}

preinstall_confirmation() {
  cat <<EOF 1>&2
Would you like fuelup-init to modify your PATH variable for you? (N/y)
EOF
}

add_path_message() {
  warn "Please manually add $FUELUP_DIR/bin to your PATH."
}

assert_nz() {
  if [ -z "$1" ]; then
    err "assert_nz $2"
  fi
}

say() {
  printf 'fuelup: %s\n' "$1"
}

need_cmd() {
  if ! check_cmd "$1"; then
    err "need '$1' (command not found)"
  fi
}

check_cmd() {
  command -v "$1" >/dev/null 2>&1
}

ensure() {
  if ! "$@"; then
    err "command failed: $*"
  fi
}

downloader() {
  # Implementation here...
}

err() {
  say "$1" >&2
  exit 1
}

warn() {
  say "warning: $1" >&2
}

main "$@" || exit 1



fuel-core run \
--enable-relayer \
--service-name fuel-mainnet-node \
--keypair {P2P_PRIVATE_KEY} \
--relayer {ETHEREUM_RPC_ENDPOINT} \
--ip=0.0.0.0 --port 4000 --peering-port 30333 \
--db-path ~/.fuel-mainnet \
--snapshot ./your/path/to/chain_config_folder \
--utxo-validation --poa-instant false --enable-p2p \
--bootstrap-nodes /dnsaddr/mainnet.fuel.network \
--sync-header-batch-size 100 \
--relayer-v2-listening-contracts=0xAEB0c00D0125A8a788956ade4f4F12Ead9f65DDf \
--relayer-da-deploy-height=20620434 \
--relayer-log-page-size=100 \
--sync-block-stream-buffer-size 30

Icon ClipboardText
