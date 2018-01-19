#!/bin/sh
#
# Download and run the latest release version of the Certbot client.
#
# NOTE: THIS SCRIPT IS AUTO-GENERATED AND SELF-UPDATING
#
# IF YOU WANT TO EDIT IT LOCALLY, *ALWAYS* RUN YOUR COPY WITH THE
# "--no-self-upgrade" FLAG
#
# IF YOU WANT TO SEND PULL REQUESTS, THE REAL SOURCE FOR THIS FILE IS
# letsencrypt-auto-source/letsencrypt-auto.template AND
# letsencrypt-auto-source/pieces/bootstrappers/*

set -e  # Work even if somebody does "sh thisscript.sh".

# Note: you can set XDG_DATA_HOME or VENV_PATH before running this script,
# if you want to change where the virtual environment will be installed

# HOME might not be defined when being run through something like systemd
if [ -z "$HOME" ]; then
  HOME=~root
fi
if [ -z "$XDG_DATA_HOME" ]; then
  XDG_DATA_HOME=~/.local/share
fi
if [ -z "$VENV_PATH" ]; then
  # We export these values so they are preserved properly if this script is
  # rerun with sudo/su where $HOME/$XDG_DATA_HOME may have a different value.
  export OLD_VENV_PATH="$XDG_DATA_HOME/letsencrypt"
  export VENV_PATH="/opt/eff.org/certbot/venv"
fi
VENV_BIN="$VENV_PATH/bin"
BOOTSTRAP_VERSION_PATH="$VENV_PATH/certbot-auto-bootstrap-version.txt"
LE_AUTO_VERSION="0.21.0"
BASENAME=$(basename $0)
USAGE="Usage: $BASENAME [OPTIONS]
A self-updating wrapper script for the Certbot ACME client. When run, updates
to both this script and certbot will be downloaded and installed. After
ensuring you have the latest versions installed, certbot will be invoked with
all arguments you have provided.

Help for certbot itself cannot be provided until it is installed.

  --debug                                   attempt experimental installation
  -h, --help                                print this help
  -n, --non-interactive, --noninteractive   run without asking for user input
  --no-bootstrap                            do not install OS dependencies
  --no-self-upgrade                         do not download updates
  --os-packages-only                        install OS dependencies and exit
  -v, --verbose                             provide more output
  -q, --quiet                               provide only update/error output;
                                            implies --non-interactive

All arguments are accepted and forwarded to the Certbot client when run."
export CERTBOT_AUTO="$0"

for arg in "$@" ; do
  case "$arg" in
    --debug)
      DEBUG=1;;
    --os-packages-only)
      OS_PACKAGES_ONLY=1;;
    --no-self-upgrade)
      # Do not upgrade this script (also prevents client upgrades, because each
      # copy of the script pins a hash of the python client)
      NO_SELF_UPGRADE=1;;
    --no-bootstrap)
      NO_BOOTSTRAP=1;;
    --help)
      HELP=1;;
    --noninteractive|--non-interactive)
      NONINTERACTIVE=1;;
    --quiet)
      QUIET=1;;
    renew)
      ASSUME_YES=1;;
    --verbose)
      VERBOSE=1;;
    -[!-]*)
      OPTIND=1
      while getopts ":hnvq" short_arg $arg; do
        case "$short_arg" in
          h)
            HELP=1;;
          n)
            NONINTERACTIVE=1;;
          q)
            QUIET=1;;
          v)
            VERBOSE=1;;
        esac
      done;;
  esac
done

if [ $BASENAME = "letsencrypt-auto" ]; then
  # letsencrypt-auto does not respect --help or --yes for backwards compatibility
  NONINTERACTIVE=1
  HELP=0
fi

# Set ASSUME_YES to 1 if QUIET or NONINTERACTIVE
if [ "$QUIET" = 1 -o "$NONINTERACTIVE" = 1 ]; then
  ASSUME_YES=1
fi

say() {
    if [  "$QUIET" != 1 ]; then
        echo "$@"
    fi
}

error() {
    echo "$@"
}

# Support for busybox and others where there is no "command",
# but "which" instead
if command -v command > /dev/null 2>&1 ; then
  export EXISTS="command -v"
elif which which > /dev/null 2>&1 ; then
  export EXISTS="which"
else
  error "Cannot find command nor which... please install one!"
  exit 1
fi

# Certbot itself needs root access for almost all modes of operation.
# certbot-auto needs root access to bootstrap OS dependencies and install
# Certbot at a protected path so it can be safely run as root. To accomplish
# this, this script will attempt to run itself as root if it doesn't have the
# necessary privileges by using `sudo` or falling back to `su` if it is not
# available. The mechanism used to obtain root access can be set explicitly by
# setting the environment variable LE_AUTO_SUDO to 'sudo', 'su', 'su_sudo',
# 'SuSudo', or '' as used below.

# Because the parameters in `su -c` has to be a string,
# we need to properly escape it.
SuSudo() {
  args=""
  # This `while` loop iterates over all parameters given to this function.
  # For each parameter, all `'` will be replace by `'"'"'`, and the escaped string
  # will be wrapped in a pair of `'`, then appended to `$args` string
  # For example, `echo "It's only 1\$\!"` will be escaped to:
  #   'echo' 'It'"'"'s only 1$!'
  #     │       │└┼┘│
  #     │       │ │ └── `'s only 1$!'` the literal string
  #     │       │ └── `\"'\"` is a single quote (as a string)
  #     │       └── `'It'`, to be concatenated with the strings following it
  #     └── `echo` wrapped in a pair of `'`, it's totally fine for the shell command itself
  while [ $# -ne 0 ]; do
    args="$args'$(printf "%s" "$1" | sed -e "s/'/'\"'\"'/g")' "
    shift
  done
  su root -c "$args"
}

# Sets the environment variable SUDO to be the name of the program or function
# to call to get root access. If this script already has root privleges, SUDO
# is set to an empty string. The value in SUDO should be run with the command
# to called with root privileges as arguments.
SetRootAuthMechanism() {
  SUDO=""
  if [ -n "${LE_AUTO_SUDO+x}" ]; then
    case "$LE_AUTO_SUDO" in
      SuSudo|su_sudo|su)
        SUDO=SuSudo
        ;;
      sudo)
        SUDO="sudo -E"
        ;;
      '') ;; # Nothing to do for plain root method.
      *)
        error "Error: unknown root authorization mechanism '$LE_AUTO_SUDO'."
        exit 1
    esac
    say "Using preset root authorization mechanism '$LE_AUTO_SUDO'."
  else
    if test "`id -u`" -ne "0" ; then
      if $EXISTS sudo 1>/dev/null 2>&1; then
        SUDO="sudo -E"
      else
        say \"sudo\" is not available, will use \"su\" for installation steps...
        SUDO=SuSudo
      fi
    fi
  fi
}

if [ "$1" = "--cb-auto-has-root" ]; then
  shift 1
else
  SetRootAuthMechanism
  if [ -n "$SUDO" ]; then
    echo "Requesting to rerun $0 with root privileges..."
    $SUDO "$0" --cb-auto-has-root "$@"
    exit 0
  fi
fi

# Runs this script again with the given arguments. --cb-auto-has-root is added
# to the command line arguments to ensure we don't try to acquire root a
# second time. After the script is rerun, we exit the current script.
RerunWithArgs() {
    "$0" --cb-auto-has-root "$@"
    exit 0
}

BootstrapMessage() {
  # Arguments: Platform name
  say "Bootstrapping dependencies for $1... (you can skip this with --no-bootstrap)"
}

ExperimentalBootstrap() {
  # Arguments: Platform name, bootstrap function name
  if [ "$DEBUG" = 1 ]; then
    if [ "$2" != "" ]; then
      BootstrapMessage $1
      $2
    fi
  else
    error "FATAL: $1 support is very experimental at present..."
    error "if you would like to work on improving it, please ensure you have backups"
    error "and then run this script again with the --debug flag!"
    error "Alternatively, you can install OS dependencies yourself and run this script"
    error "again with --no-bootstrap."
    exit 1
  fi
}

DeprecationBootstrap() {
  # Arguments: Platform name, bootstrap function name
  if [ "$DEBUG" = 1 ]; then
    if [ "$2" != "" ]; then
      BootstrapMessage $1
      $2
    fi
  else
    error "WARNING: certbot-auto support for this $1 is DEPRECATED!"
    error "Please visit certbot.eff.org to learn how to download a version of"
    error "Certbot that is packaged for your system. While an existing version"
    error "of certbot-auto may work currently, we have stopped supporting updating"
    error "system packages for your system. Please switch to a packaged version"
    error "as soon as possible."
    exit 1
  fi
}

MIN_PYTHON_VERSION="2.6"
MIN_PYVER=$(echo "$MIN_PYTHON_VERSION" | sed 's/\.//')
# Sets LE_PYTHON to Python version string and PYVER to the first two
# digits of the python version
DeterminePythonVersion() {
  # Arguments: "NOCRASH" if we shouldn't crash if we don't find a good python
  #
  # If no Python is found, PYVER is set to 0.
  if [ "$USE_PYTHON_3" = 1 ]; then
    for LE_PYTHON in "$LE_PYTHON" python3; do
      # Break (while keeping the LE_PYTHON value) if found.
      $EXISTS "$LE_PYTHON" > /dev/null && break
    done
  else
    for LE_PYTHON in "$LE_PYTHON" python2.7 python27 python2 python; do
      # Break (while keeping the LE_PYTHON value) if found.
      $EXISTS "$LE_PYTHON" > /dev/null && break
    done
  fi
  if [ "$?" != "0" ]; then
    if [ "$1" != "NOCRASH" ]; then
      error "Cannot find any Pythons; please install one!"
      exit 1
    else
      PYVER=0
      return 0
    fi
  fi

  PYVER=`"$LE_PYTHON" -V 2>&1 | cut -d" " -f 2 | cut -d. -f1,2 | sed 's/\.//'`
  if [ "$PYVER" -lt "$MIN_PYVER" ]; then
    if [ "$1" != "NOCRASH" ]; then
      error "You have an ancient version of Python entombed in your operating system..."
      error "This isn't going to work; you'll need at least version $MIN_PYTHON_VERSION."
      exit 1
    fi
  fi
}

# If new packages are installed by BootstrapDebCommon below, this version
# number must be increased.
BOOTSTRAP_DEB_COMMON_VERSION=1

BootstrapDebCommon() {
  # Current version tested with:
  #
  # - Ubuntu
  #     - 14.04 (x64)
  #     - 15.04 (x64)
  # - Debian
  #     - 7.9 "wheezy" (x64)
  #     - sid (2015-10-21) (x64)

  # Past versions tested with:
  #
  # - Debian 8.0 "jessie" (x64)
  # - Raspbian 7.8 (armhf)

  # Believed not to work:
  #
  # - Debian 6.0.10 "squeeze" (x64)

  if [ "$QUIET" = 1 ]; then
    QUIET_FLAG='-qq'
  fi

  apt-get $QUIET_FLAG update || error apt-get update hit problems but continuing anyway...

  # virtualenv binary can be found in different packages depending on
  # distro version (#346)

  virtualenv=
  # virtual env is known to apt and is installable
  if apt-cache show virtualenv > /dev/null 2>&1 ; then
    if ! LC_ALL=C apt-cache --quiet=0 show virtualenv 2>&1 | grep -q 'No packages found'; then
      virtualenv="virtualenv"
    fi
  fi

  if apt-cache show python-virtualenv > /dev/null 2>&1; then
    virtualenv="$virtualenv python-virtualenv"
  fi

  augeas_pkg="libaugeas0 augeas-lenses"
  AUGVERSION=`LC_ALL=C apt-cache show --no-all-versions libaugeas0 | grep ^Version: | cut -d" " -f2`

  if [ "$ASSUME_YES" = 1 ]; then
    YES_FLAG="-y"
  fi

  AddBackportRepo() {
    # ARGS:
    BACKPORT_NAME="$1"
    BACKPORT_SOURCELINE="$2"
    say "To use the Apache Certbot plugin, augeas needs to be installed from $BACKPORT_NAME."
    if ! grep -v -e ' *#' /etc/apt/sources.list | grep -q "$BACKPORT_NAME" ; then
      # This can theoretically error if sources.list.d is empty, but in that case we don't care.
      if ! grep -v -e ' *#' /etc/apt/sources.list.d/* 2>/dev/null | grep -q "$BACKPORT_NAME"; then
        if [ "$ASSUME_YES" = 1 ]; then
          /bin/echo -n "Installing augeas from $BACKPORT_NAME in 3 seconds..."
          sleep 1s
          /bin/echo -ne "\e[0K\rInstalling augeas from $BACKPORT_NAME in 2 seconds..."
          sleep 1s
          /bin/echo -e "\e[0K\rInstalling augeas from $BACKPORT_NAME in 1 second ..."
          sleep 1s
          add_backports=1
        else
          read -p "Would you like to enable the $BACKPORT_NAME repository [Y/n]? " response
          case $response in
            [yY][eE][sS]|[yY]|"")
              add_backports=1;;
            *)
              add_backports=0;;
          esac
        fi
        if [ "$add_backports" = 1 ]; then
          sh -c "echo $BACKPORT_SOURCELINE >> /etc/apt/sources.list.d/$BACKPORT_NAME.list"
          apt-get $QUIET_FLAG update
        fi
      fi
    fi
    if [ "$add_backports" != 0 ]; then
      apt-get install $QUIET_FLAG $YES_FLAG --no-install-recommends -t "$BACKPORT_NAME" $augeas_pkg
      augeas_pkg=
    fi
  }


  if dpkg --compare-versions 1.0 gt "$AUGVERSION" ; then
    if lsb_release -a | grep -q wheezy ; then
      AddBackportRepo wheezy-backports "deb http://http.debian.net/debian wheezy-backports main"
    elif lsb_release -a | grep -q precise ; then
      # XXX add ARM case
      AddBackportRepo precise-backports "deb http://archive.ubuntu.com/ubuntu precise-backports main restricted universe multiverse"
    else
      echo "No libaugeas0 version is available that's new enough to run the"
      echo "Certbot apache plugin..."
    fi
    # XXX add a case for ubuntu PPAs
  fi

  apt-get install $QUIET_FLAG $YES_FLAG --no-install-recommends \
    python \
    python-dev \
    $virtualenv \
    gcc \
    $augeas_pkg \
    libssl-dev \
    openssl \
    libffi-dev \
    ca-certificates \


  if ! $EXISTS virtualenv > /dev/null ; then
    error Failed to install a working \"virtualenv\" command, exiting
    exit 1
  fi
}

# If new packages are installed by BootstrapRpmCommonBase below, version
# numbers in rpm_common.sh and rpm_python3.sh must be increased.

# Sets TOOL to the name of the package manager
# Sets appropriate values for YES_FLAG and QUIET_FLAG based on $ASSUME_YES and $QUIET_FLAG.
# Enables EPEL if applicable and possible.
InitializeRPMCommonBase() {
  if type dnf 2>/dev/null
  then
    TOOL=dnf
  elif type yum 2>/dev/null
  then
    TOOL=yum

  else
    error "Neither yum nor dnf found. Aborting bootstrap!"
    exit 1
  fi

  if [ "$ASSUME_YES" = 1 ]; then
    YES_FLAG="-y"
  fi
  if [ "$QUIET" = 1 ]; then
    QUIET_FLAG='--quiet'
  fi

  if ! $TOOL list *virtualenv >/dev/null 2>&1; then
    echo "To use Certbot, packages from the EPEL repository need to be installed."
    if ! $TOOL list epel-release >/dev/null 2>&1; then
      error "Enable the EPEL repository and try running Certbot again."
      exit 1
    fi
    if [ "$ASSUME_YES" = 1 ]; then
      /bin/echo -n "Enabling the EPEL repository in 3 seconds..."
      sleep 1s
      /bin/echo -ne "\e[0K\rEnabling the EPEL repository in 2 seconds..."
      sleep 1s
      /bin/echo -e "\e[0K\rEnabling the EPEL repository in 1 second..."
      sleep 1s
    fi
    if ! $TOOL install $YES_FLAG $QUIET_FLAG epel-release; then
      error "Could not enable EPEL. Aborting bootstrap!"
      exit 1
    fi
  fi
}

BootstrapRpmCommonBase() {
  # Arguments: whitespace-delimited python packages to install

  InitializeRPMCommonBase # This call is superfluous in practice

  pkgs="
    gcc
    augeas-libs
    openssl
    openssl-devel
    libffi-devel
    redhat-rpm-config
    ca-certificates
  "

  # Add the python packages
  pkgs="$pkgs
    $1
  "

  if $TOOL list installed "httpd" >/dev/null 2>&1; then
    pkgs="$pkgs
      mod_ssl
    "
  fi

  if ! $TOOL install $YES_FLAG $QUIET_FLAG $pkgs; then
    error "Could not install OS dependencies. Aborting bootstrap!"
    exit 1
  fi
}

# If new packages are installed by BootstrapRpmCommon below, this version
# number must be increased.
BOOTSTRAP_RPM_COMMON_VERSION=1

BootstrapRpmCommon() {
  # Tested with:
  #   - Fedora 20, 21, 22, 23 (x64)
  #   - Centos 7 (x64: on DigitalOcean droplet)
  #   - CentOS 7 Minimal install in a Hyper-V VM
  #   - CentOS 6

  InitializeRPMCommonBase

  # Most RPM distros use the "python" or "python-" naming convention.  Let's try that first.
  if $TOOL list python >/dev/null 2>&1; then
    python_pkgs="$python
      python-devel
      python-virtualenv
      python-tools
      python-pip
    "
  # Fedora 26 starts to use the prefix python2 for python2 based packages.
  # this elseif is theoretically for any Fedora over version 26:
  elif $TOOL list python2 >/dev/null 2>&1; then
    python_pkgs="$python2
      python2-libs
      python2-setuptools
      python2-devel
      python2-virtualenv
      python2-tools
      python2-pip
    "
  # Some distros and older versions of current distros use a "python27"
  # instead of the "python" or "python-" naming convention.
  else
    python_pkgs="$python27
      python27-devel
      python27-virtualenv
      python27-tools
      python27-pip
    "
  fi

  BootstrapRpmCommonBase "$python_pkgs"
}

# If new packages are installed by BootstrapRpmPython3 below, this version
# number must be increased.
BOOTSTRAP_RPM_PYTHON3_VERSION=1

BootstrapRpmPython3() {
  # Tested with:
  #   - CentOS 6

  InitializeRPMCommonBase

  # EPEL uses python34
  if $TOOL list python34 >/dev/null 2>&1; then
    python_pkgs="python34
      python34-devel
      python34-tools
    "
  else
    error "No supported Python package available to install. Aborting bootstrap!"
    exit 1
  fi

  BootstrapRpmCommonBase "$python_pkgs"
}

# If new packages are installed by BootstrapSuseCommon below, this version
# number must be increased.
BOOTSTRAP_SUSE_COMMON_VERSION=1

BootstrapSuseCommon() {
  # SLE12 don't have python-virtualenv

  if [ "$ASSUME_YES" = 1 ]; then
    zypper_flags="-nq"
    install_flags="-l"
  fi

  if [ "$QUIET" = 1 ]; then
    QUIET_FLAG='-qq'
  fi

  zypper $QUIET_FLAG $zypper_flags in $install_flags \
    python \
    python-devel \
    python-virtualenv \
    gcc \
    augeas-lenses \
    libopenssl-devel \
    libffi-devel \
    ca-certificates
}

# If new packages are installed by BootstrapArchCommon below, this version
# number must be increased.
BOOTSTRAP_ARCH_COMMON_VERSION=1

BootstrapArchCommon() {
  # Tested with:
  #   - ArchLinux (x86_64)
  #
  # "python-virtualenv" is Python3, but "python2-virtualenv" provides
  # only "virtualenv2" binary, not "virtualenv" necessary in
  # ./tools/_venv_common.sh

  deps="
    python2
    python-virtualenv
    gcc
    augeas
    openssl
    libffi
    ca-certificates
    pkg-config
  "

  # pacman -T exits with 127 if there are missing dependencies
  missing=$(pacman -T $deps) || true

  if [ "$ASSUME_YES" = 1 ]; then
    noconfirm="--noconfirm"
  fi

  if [ "$missing" ]; then
    if [ "$QUIET" = 1 ]; then
      pacman -S --needed $missing $noconfirm > /dev/null
    else
      pacman -S --needed $missing $noconfirm
    fi
  fi
}

# If new packages are installed by BootstrapGentooCommon below, this version
# number must be increased.
BOOTSTRAP_GENTOO_COMMON_VERSION=1

BootstrapGentooCommon() {
  PACKAGES="
    dev-lang/python:2.7
    dev-python/virtualenv
    app-admin/augeas
    dev-libs/openssl
    dev-libs/libffi
    app-misc/ca-certificates
    virtual/pkgconfig"

  ASK_OPTION="--ask"
  if [ "$ASSUME_YES" = 1 ]; then
    ASK_OPTION=""
  fi

  case "$PACKAGE_MANAGER" in
    (paludis)
      cave resolve --preserve-world --keep-targets if-possible $PACKAGES -x
      ;;
    (pkgcore)
      pmerge --noreplace --oneshot $ASK_OPTION $PACKAGES
      ;;
    (portage|*)
      emerge --noreplace --oneshot $ASK_OPTION $PACKAGES
      ;;
  esac
}

# If new packages are installed by BootstrapFreeBsd below, this version number
# must be increased.
BOOTSTRAP_FREEBSD_VERSION=1

BootstrapFreeBsd() {
  if [ "$QUIET" = 1 ]; then
    QUIET_FLAG="--quiet"
  fi

  pkg install -Ay $QUIET_FLAG \
    python \
    py27-virtualenv \
    augeas \
    libffi
}

# If new packages are installed by BootstrapMac below, this version number must
# be increased.
BOOTSTRAP_MAC_VERSION=1

BootstrapMac() {
  if hash brew 2>/dev/null; then
    say "Using Homebrew to install dependencies..."
    pkgman=brew
    pkgcmd="brew install"
  elif hash port 2>/dev/null; then
    say "Using MacPorts to install dependencies..."
    pkgman=port
    pkgcmd="port install"
  else
    say "No Homebrew/MacPorts; installing Homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    pkgman=brew
    pkgcmd="brew install"
  fi

  $pkgcmd augeas
  if [ "$(which python)" = "/System/Library/Frameworks/Python.framework/Versions/2.7/bin/python" \
      -o "$(which python)" = "/usr/bin/python" ]; then
    # We want to avoid using the system Python because it requires root to use pip.
    # python.org, MacPorts or HomeBrew Python installations should all be OK.
    say "Installing python..."
    $pkgcmd python
  fi

  # Workaround for _dlopen not finding augeas on macOS
  if [ "$pkgman" = "port" ] && ! [ -e "/usr/local/lib/libaugeas.dylib" ] && [ -e "/opt/local/lib/libaugeas.dylib" ]; then
    say "Applying augeas workaround"
    mkdir -p /usr/local/lib/
    ln -s /opt/local/lib/libaugeas.dylib /usr/local/lib/
  fi

  if ! hash pip 2>/dev/null; then
    say "pip not installed"
    say "Installing pip..."
    curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | python
  fi

  if ! hash virtualenv 2>/dev/null; then
    say "virtualenv not installed."
    say "Installing with pip..."
    pip install virtualenv
  fi
}

# If new packages are installed by BootstrapSmartOS below, this version number
# must be increased.
BOOTSTRAP_SMARTOS_VERSION=1

BootstrapSmartOS() {
  pkgin update
  pkgin -y install 'gcc49' 'py27-augeas' 'py27-virtualenv'
}

# If new packages are installed by BootstrapMageiaCommon below, this version
# number must be increased.
BOOTSTRAP_MAGEIA_COMMON_VERSION=1

BootstrapMageiaCommon() {
  if [ "$QUIET" = 1 ]; then
    QUIET_FLAG='--quiet'
  fi

  if ! urpmi --force $QUIET_FLAG \
      python \
      libpython-devel \
      python-virtualenv
    then
      error "Could not install Python dependencies. Aborting bootstrap!"
      exit 1
  fi

  if ! urpmi --force $QUIET_FLAG \
      git \
      gcc \
      python-augeas \
      libopenssl-devel \
      libffi-devel \
      rootcerts
    then
      error "Could not install additional dependencies. Aborting bootstrap!"
      exit 1
    fi
}


# Set Bootstrap to the function that installs OS dependencies on this system
# and BOOTSTRAP_VERSION to the unique identifier for the current version of
# that function. If Bootstrap is set to a function that doesn't install any
# packages (either because --no-bootstrap was included on the command line or
# we don't know how to bootstrap on this system), BOOTSTRAP_VERSION is not set.
if [ "$NO_BOOTSTRAP" = 1 ]; then
  Bootstrap() {
    :
  }
elif [ -f /etc/debian_version ]; then
  Bootstrap() {
    BootstrapMessage "Debian-based OSes"
    BootstrapDebCommon
  }
  BOOTSTRAP_VERSION="BootstrapDebCommon $BOOTSTRAP_DEB_COMMON_VERSION"
elif [ -f /etc/mageia-release ]; then
  # Mageia has both /etc/mageia-release and /etc/redhat-release
  Bootstrap() {
    ExperimentalBootstrap "Mageia" BootstrapMageiaCommon
  }
  BOOTSTRAP_VERSION="BootstrapMageiaCommon $BOOTSTRAP_MAGEIA_COMMON_VERSION"
elif [ -f /etc/redhat-release ]; then
  # Run DeterminePythonVersion to decide on the basis of available Python versions
  # whether to use 2.x or 3.x on RedHat-like systems.
  # Then, revert LE_PYTHON to its previous state.
  prev_le_python="$LE_PYTHON"
  unset LE_PYTHON
  DeterminePythonVersion "NOCRASH"
  if [ "$PYVER" -eq 26 ]; then
    Bootstrap() {
      BootstrapMessage "RedHat-based OSes that will use Python3"
      BootstrapRpmPython3
    }
    USE_PYTHON_3=1
    BOOTSTRAP_VERSION="BootstrapRpmPython3 $BOOTSTRAP_RPM_PYTHON3_VERSION"
  else
    Bootstrap() {
      BootstrapMessage "RedHat-based OSes"
      BootstrapRpmCommon
    }
    BOOTSTRAP_VERSION="BootstrapRpmCommon $BOOTSTRAP_RPM_COMMON_VERSION"
  fi
  LE_PYTHON="$prev_le_python"
elif [ -f /etc/os-release ] && `grep -q openSUSE /etc/os-release` ; then
  Bootstrap() {
    BootstrapMessage "openSUSE-based OSes"
    BootstrapSuseCommon
  }
  BOOTSTRAP_VERSION="BootstrapSuseCommon $BOOTSTRAP_SUSE_COMMON_VERSION"
elif [ -f /etc/arch-release ]; then
  Bootstrap() {
    if [ "$DEBUG" = 1 ]; then
      BootstrapMessage "Archlinux"
      BootstrapArchCommon
    else
      error "Please use pacman to install letsencrypt packages:"
      error "# pacman -S certbot certbot-apache"
      error
      error "If you would like to use the virtualenv way, please run the script again with the"
      error "--debug flag."
      exit 1
    fi
  }
  BOOTSTRAP_VERSION="BootstrapArchCommon $BOOTSTRAP_ARCH_COMMON_VERSION"
elif [ -f /etc/manjaro-release ]; then
  Bootstrap() {
    ExperimentalBootstrap "Manjaro Linux" BootstrapArchCommon
  }
  BOOTSTRAP_VERSION="BootstrapArchCommon $BOOTSTRAP_ARCH_COMMON_VERSION"
elif [ -f /etc/gentoo-release ]; then
  Bootstrap() {
    DeprecationBootstrap "Gentoo" BootstrapGentooCommon
  }
  BOOTSTRAP_VERSION="BootstrapGentooCommon $BOOTSTRAP_GENTOO_COMMON_VERSION"
elif uname | grep -iq FreeBSD ; then
  Bootstrap() {
    DeprecationBootstrap "FreeBSD" BootstrapFreeBsd
  }
  BOOTSTRAP_VERSION="BootstrapFreeBsd $BOOTSTRAP_FREEBSD_VERSION"
elif uname | grep -iq Darwin ; then
  Bootstrap() {
    DeprecationBootstrap "macOS" BootstrapMac
  }
  BOOTSTRAP_VERSION="BootstrapMac $BOOTSTRAP_MAC_VERSION"
elif [ -f /etc/issue ] && grep -iq "Amazon Linux" /etc/issue ; then
  Bootstrap() {
    ExperimentalBootstrap "Amazon Linux" BootstrapRpmCommon
  }
  BOOTSTRAP_VERSION="BootstrapRpmCommon $BOOTSTRAP_RPM_COMMON_VERSION"
elif [ -f /etc/product ] && grep -q "Joyent Instance" /etc/product ; then
  Bootstrap() {
    ExperimentalBootstrap "Joyent SmartOS Zone" BootstrapSmartOS
  }
  BOOTSTRAP_VERSION="BootstrapSmartOS $BOOTSTRAP_SMARTOS_VERSION"
else
  Bootstrap() {
    error "Sorry, I don't know how to bootstrap Certbot on your operating system!"
    error
    error "You will need to install OS dependencies, configure virtualenv, and run pip install manually."
    error "Please see https://letsencrypt.readthedocs.org/en/latest/contributing.html#prerequisites"
    error "for more info."
    exit 1
  }
fi

# Sets PREV_BOOTSTRAP_VERSION to the identifier for the bootstrap script used
# to install OS dependencies on this system. PREV_BOOTSTRAP_VERSION isn't set
# if it is unknown how OS dependencies were installed on this system.
SetPrevBootstrapVersion() {
  if [ -f $BOOTSTRAP_VERSION_PATH ]; then
    PREV_BOOTSTRAP_VERSION=$(cat "$BOOTSTRAP_VERSION_PATH")
  # The list below only contains bootstrap version strings that existed before
  # we started writing them to disk.
  #
  # DO NOT MODIFY THIS LIST UNLESS YOU KNOW WHAT YOU'RE DOING!
  elif grep -Fqx "$BOOTSTRAP_VERSION" << "UNLIKELY_EOF"
BootstrapDebCommon 1
BootstrapMageiaCommon 1
BootstrapRpmCommon 1
BootstrapSuseCommon 1
BootstrapArchCommon 1
BootstrapGentooCommon 1
BootstrapFreeBsd 1
BootstrapMac 1
BootstrapSmartOS 1
UNLIKELY_EOF
  then
    # If there's no bootstrap version saved to disk, but the currently selected
    # bootstrap script is from before we started saving the version number,
    # return the currently selected version to prevent us from rebootstrapping
    # unnecessarily.
    PREV_BOOTSTRAP_VERSION="$BOOTSTRAP_VERSION"
  fi
}

TempDir() {
  mktemp -d 2>/dev/null || mktemp -d -t 'le'  # Linux || macOS
}

# Returns 0 if a letsencrypt installation exists at $OLD_VENV_PATH, otherwise,
# returns a non-zero number.
OldVenvExists() {
    [ -n "$OLD_VENV_PATH" -a -f "$OLD_VENV_PATH/bin/letsencrypt" ]
}

if [ "$1" = "--le-auto-phase2" ]; then
  # Phase 2: Create venv, install LE, and run.

  shift 1  # the --le-auto-phase2 arg
  SetPrevBootstrapVersion

  if [ -z "$PHASE_1_VERSION" -a "$USE_PYTHON_3" = 1 ]; then
    unset LE_PYTHON
  fi

  INSTALLED_VERSION="none"
  if [ -d "$VENV_PATH" ] || OldVenvExists; then
    # If the selected Bootstrap function isn't a noop and it differs from the
    # previously used version
    if [ -n "$BOOTSTRAP_VERSION" -a "$BOOTSTRAP_VERSION" != "$PREV_BOOTSTRAP_VERSION" ]; then
      # if non-interactive mode or stdin and stdout are connected to a terminal
      if [ \( "$NONINTERACTIVE" = 1 \) -o \( \( -t 0 \) -a \( -t 1 \) \) ]; then
        if [ -d "$VENV_PATH" ]; then
          rm -rf "$VENV_PATH"
        fi
        # In the case the old venv was just a symlink to the new one,
        # OldVenvExists is now false because we deleted the venv at VENV_PATH.
        if OldVenvExists; then
          rm -rf "$OLD_VENV_PATH"
          ln -s "$VENV_PATH" "$OLD_VENV_PATH"
        fi
        RerunWithArgs "$@"
      else
        error "Skipping upgrade because new OS dependencies may need to be installed."
        error
        error "To upgrade to a newer version, please run this script again manually so you can"
        error "approve changes or with --non-interactive on the command line to automatically"
        error "install any required packages."
        # Set INSTALLED_VERSION to be the same so we don't update the venv
        INSTALLED_VERSION="$LE_AUTO_VERSION"
        # Continue to use OLD_VENV_PATH if the new venv doesn't exist
        if [ ! -d "$VENV_PATH" ]; then
          VENV_BIN="$OLD_VENV_PATH/bin"
        fi
      fi
    elif [ -f "$VENV_BIN/letsencrypt" ]; then
      # --version output ran through grep due to python-cryptography DeprecationWarnings
      # grep for both certbot and letsencrypt until certbot and shim packages have been released
      INSTALLED_VERSION=$("$VENV_BIN/letsencrypt" --version 2>&1 | grep "^certbot\|^letsencrypt" | cut -d " " -f 2)
      if [ -z "$INSTALLED_VERSION" ]; then
          error "Error: couldn't get currently installed version for $VENV_BIN/letsencrypt: " 1>&2
          "$VENV_BIN/letsencrypt" --version
          exit 1
      fi
    fi
  fi

  if [ "$LE_AUTO_VERSION" != "$INSTALLED_VERSION" ]; then
    say "Creating virtual environment..."
    DeterminePythonVersion
    rm -rf "$VENV_PATH"
    if [ "$PYVER" -le 27 ]; then
      if [ "$VERBOSE" = 1 ]; then
        virtualenv --no-site-packages --python "$LE_PYTHON" "$VENV_PATH"
      else
        virtualenv --no-site-packages --python "$LE_PYTHON" "$VENV_PATH" > /dev/null
      fi
    else
      if [ "$VERBOSE" = 1 ]; then
        "$LE_PYTHON" -m venv "$VENV_PATH"
      else
        "$LE_PYTHON" -m venv "$VENV_PATH" > /dev/null
      fi
    fi

    if [ -n "$BOOTSTRAP_VERSION" ]; then
      echo "$BOOTSTRAP_VERSION" > "$BOOTSTRAP_VERSION_PATH"
    elif [ -n "$PREV_BOOTSTRAP_VERSION" ]; then
      echo "$PREV_BOOTSTRAP_VERSION" > "$BOOTSTRAP_VERSION_PATH"
    fi

    say "Installing Python packages..."
    TEMP_DIR=$(TempDir)
    trap 'rm -rf "$TEMP_DIR"' EXIT
    # There is no $ interpolation due to quotes on starting heredoc delimiter.
    # -------------------------------------------------------------------------
    cat << "UNLIKELY_EOF" > "$TEMP_DIR/letsencrypt-auto-requirements.txt"
# This is the flattened list of packages certbot-auto installs. To generate
# this, do
# `pip install --no-cache-dir -e acme -e . -e certbot-apache -e certbot-nginx`,
# and then use `hashin` or a more secure method to gather the hashes.

# Hashin example:
# pip install hashin
# hashin -r dependency-requirements.txt cryptography==1.5.2
# sets the new certbot-auto pinned version of cryptography to 1.5.2

argparse==1.4.0 \
    --hash=sha256:c31647edb69fd3d465a847ea3157d37bed1f95f19760b11a47aa91c04b666314 \
    --hash=sha256:62b089a55be1d8949cd2bc7e0df0bddb9e028faefc8c32038cc84862aefdd6e4

# This comes before cffi because cffi will otherwise install an unchecked
# version via setup_requires.
pycparser==2.14 \
    --hash=sha256:7959b4a74abdc27b312fed1c21e6caf9309ce0b29ea86b591fd2e99ecdf27f73 \
    --no-binary pycparser

asn1crypto==0.22.0 \
    --hash=sha256:d232509fefcfcdb9a331f37e9c9dc20441019ad927c7d2176cf18ed5da0ba097 \
    --hash=sha256:cbbadd640d3165ab24b06ef25d1dca09a3441611ac15f6a6b452474fdf0aed1a
cffi==1.10.0 \
    --hash=sha256:446699c10f3c390633d0722bc19edbc7ac4b94761918a4a4f7908a24e86ebbd0 \
    --hash=sha256:562326fc7f55a59ef3fef5e82908fe938cdc4bbda32d734c424c7cd9ed73e93a \
    --hash=sha256:7f732ad4a30db0b39400c3f7011249f7d0701007d511bf09604729aea222871f \
    --hash=sha256:94fb8410c6c4fc48e7ea759d3d1d9ca561171a88d00faddd4aa0306f698ad6a0 \
    --hash=sha256:587a5043df4b00a2130e09fed42da02a4ed3c688bd9bf07a3ac89d2271f4fb07 \
    --hash=sha256:ec08b88bef627ec1cea210e1608c85d3cf44893bcde74e41b7f7dbdfd2c1bad6 \
    --hash=sha256:a41406f6d62abcdf3eef9fd998d8dcff04fd2a7746644143045feeebd76352d1 \
    --hash=sha256:b560916546b2f209d74b82bdbc3223cee9a165b0242fa00a06dfc48a2054864a \
    --hash=sha256:e74896774e437f4715c57edeb5cf3d3a40d7727f541c2c12156617b5a15d1829 \
    --hash=sha256:9a31c18ba4881a116e448c52f3f5d3e14401cf7a9c43cc88f06f2a7f5428da0e \
    --hash=sha256:80796ea68e11624a0279d3b802f88a7fe7214122b97a15a6c97189934a2cc776 \
    --hash=sha256:f4019826a2dec066c909a1f483ef0dcf9325d6740cc0bd15308942b28b0930f7 \
    --hash=sha256:7248506981eeba23888b4140a69a53c4c0c0a386abcdca61ed8dd790a73e64b9 \
    --hash=sha256:a8955265d146e86fe2ce116394be4eaf0cb40314a79b19f11c4fa574cd639572 \
    --hash=sha256:c49187260043bd4c1d6a52186f9774f17d9b1da0a406798ebf4bfc12da166ade \
    --hash=sha256:c1d8b3d8dcb5c23ac1a8bf56422036f3f305a3c5a8bc8c354256579a1e2aa2c1 \
    --hash=sha256:9e389615bcecb8c782a87939d752340bb0a3a097e90bae54d7f0915bc12f45bd \
    --hash=sha256:d09ff358f75a874f69fa7d1c2b4acecf4282a950293fcfcf89aa606da8a9a500 \
    --hash=sha256:b69b4557aae7de18b7c174a917fe19873529d927ac592762d9771661875bbd40 \
    --hash=sha256:5de52b081a2775e76b971de9d997d85c4457fc0a09079e12d66849548ae60981 \
    --hash=sha256:e7d88fecb7b6250a1fd432e6dc64890342c372fce13dbfe4bb6f16348ad00c14 \
    --hash=sha256:1426e67e855ef7f5030c9184f4f1a9f4bfa020c31c962cd41fd129ec5aef4a6a \
    --hash=sha256:267dd2c66a5760c5f4d47e2ebcf8eeac7ef01e1ae6ae7a6d0d241a290068bc38 \
    --hash=sha256:e553eb489511cacf19eda6e52bc9e151316f0d721724997dda2c4d3079b778db \
    --hash=sha256:98b89b2c57f97ce2db7aeba60db173c84871d73b40e41a11ea95de1500ddc57e \
    --hash=sha256:e2b7e090188833bc58b2ae03fb864c22688654ebd2096bcf38bc860c4f38a3d8 \
    --hash=sha256:afa7d8b8d38ad40db8713ee053d41b36d87d6ae5ec5ad36f9210b548a18dc214 \
    --hash=sha256:4fc9c2ff7924b3a1fa326e1799e5dd58cac585d7fb25fe53ccaa1333b0453d65 \
    --hash=sha256:937db39a1ec5af3003b16357b2042bba67c88d43bc11aaa203fa8a5924524209 \
    --hash=sha256:ab22285797631df3b513b2cd3ecdc51cd8e3d36788e3991d93d0759d6883b027 \
    --hash=sha256:96e599b924ef009aa867f725b3249ee51d76489f484d3a45b4bd219c5ec6ed59 \
    --hash=sha256:bea842a0512be6a8007e585790bccd5d530520fc025ce63b03e139be373b0063 \
    --hash=sha256:e7175287f7fe7b1cc203bb958b17db40abd732690c1e18e700f10e0843a58598 \
    --hash=sha256:285ab352552f52f1398c912556d4d36d4ea9b8450e5c65d03809bf9886755533 \
    --hash=sha256:5576644b859197da7bbd8f8c7c2fb5dcc6cd505cadb42992d5f104c013f8a214 \
    --hash=sha256:b3b02911eb1f6ada203b0763ba924234629b51586f72a21faacc638269f4ced5
ConfigArgParse==0.12.0 \
    --hash=sha256:28cd7d67669651f2a4518367838c49539457504584a139709b2b8f6c208ef339
configobj==5.0.6 \
    --hash=sha256:a2f5650770e1c87fb335af19a9b7eb73fc05ccf22144eb68db7d00cd2bcb0902
cryptography==2.0.2 \
    --hash=sha256:187ae17358436d2c760f28c2aeb02fefa3f37647a9c5b6f7f7c3e83cd1c5a972 \
    --hash=sha256:19e43a13bbf52028dd1e810c803f2ad8880d0692d772f98d42e1eaf34bdee3d6 \
    --hash=sha256:da9291502cbc87dc0284a20c56876e4d2e68deac61cc43df4aec934e44ca97b1 \
    --hash=sha256:0954f8813095f581669330e0a2d5e726c33ac7f450c1458fac58bab54595e516 \
    --hash=sha256:d68b0cc40a8432ed3fc84876c519de704d6001800ec22b136e75ae841910c45b \
    --hash=sha256:2f8ad9580ab4da645cfea52a91d2da99a49a1e76616d8be68441a986fad652b0 \
    --hash=sha256:cc00b4511294f5f6b65c4e77a1a9c62f52490a63d2c120f3872176b40a82351e \
    --hash=sha256:cf896020f6a9f095a547b3d672c8db1ef2ed71fca11250731fa1d4a4cb8b1590 \
    --hash=sha256:e0fdb8322206fa02aa38f71519ff75dce2eb481b7e1110e2936795cb376bb6ee \
    --hash=sha256:277538466657ca5d6637f80be100242f9831d75138b788d718edd3aab34621f8 \
    --hash=sha256:2c77eb0560f54ce654ab82d6b2a64327a71ee969b29022bf9746ca311c9f5069 \
    --hash=sha256:755a7853b679e79d0a799351c092a9b0271f95ff54c8dd8823d8b527a2926a86 \
    --hash=sha256:77197a2d525e761cdd4c771180b4bd0d80703654c6385e4311cbbbe2beb56fa1 \
    --hash=sha256:eb8bb79d0ab00c931c8333b745f06fec481a51c52d70acd4ee95d6093ba5c386 \
    --hash=sha256:131f61de82ef28f3e20beb4bfc24f9692d28cecfd704e20e6c7f070f7793013a \
    --hash=sha256:ac35435974b2e27cd4520f29c191d7da36f4189aa3264e52c4c6c6d089ab6142 \
    --hash=sha256:04b6ea99daa2a8460728794213d76d45ad58ea247dc7e7ff148d7dd726e87863 \
    --hash=sha256:2b9442f8b4c3d575f6cc3db0e856034e0f5a9d55ecd636f52d8c496795b26952 \
    --hash=sha256:b3d3b3ecba1fe1bdb6f180770a137f877c8f07571f7b2934bb269475bcf0e5e8 \
    --hash=sha256:670a58c0d75cb0e78e73dd003bd96d4440bbb1f2bc041dcf7b81767ca4fb0ce9 \
    --hash=sha256:5af84d23bdb86b5e90aca263df1424b43f1748480bfcde3ac2a3cbe622612468 \
    --hash=sha256:ba22e8eefabdd7aca37d0c0c00d2274000d2cebb5cce9e5a710cb55bf8797b31 \
    --hash=sha256:b798b22fa7e92b439547323b8b719d217f1e1b7677585cfeeedf3b55c70bb7fb \
    --hash=sha256:59cff28af8cce96cb7e94a459726e1d88f6f5fa75097f9dcbebd99118d64ea4c \
    --hash=sha256:fe859e445abc9ba9e97950ddafb904e23234c4ecb76b0fae6c86e80592ce464a \
    --hash=sha256:655f3c474067f1e277430f23cc0549f0b1dc99b82aec6e53f80b9b2db7f76f11 \
    --hash=sha256:0ebc2be053c9a03a2f3e20a466e87bf12a51586b3c79bd2a22171b073a805346 \
    --hash=sha256:01e6e60654df64cca53733cda39446d67100c819c181d403afb120e0d2a71e1b \
    --hash=sha256:d46f4e5d455cb5563685c52ef212696f0a6cc1ea627603218eabbd8a095291d8 \
    --hash=sha256:3780b2663ee7ebb37cb83263326e3cd7f8b2ea439c448539d4b87de12c8d06ab
enum34==1.1.2 \
    --hash=sha256:2475d7fcddf5951e92ff546972758802de5260bf409319a9f1934e6bbc8b1dc7 \
    --hash=sha256:35907defb0f992b75ab7788f65fedc1cf20ffa22688e0e6f6f12afc06b3ea501
funcsigs==1.0.2 \
    --hash=sha256:330cc27ccbf7f1e992e69fef78261dc7c6569012cf397db8d3de0234e6c937ca \
    --hash=sha256:a7bb0f2cf3a3fd1ab2732cb49eba4252c2af4240442415b4abce3b87022a8f50
idna==2.5 \
    --hash=sha256:cc19709fd6d0cbfed39ea875d29ba6d4e22c0cebc510a76d6302a28385e8bb70 \
    --hash=sha256:3cb5ce08046c4e3a560fc02f138d0ac63e00f8ce5901a56b32ec8b7994082aab
ipaddress==1.0.16 \
    --hash=sha256:935712800ce4760701d89ad677666cd52691fd2f6f0b340c8b4239a3c17988a5 \
    --hash=sha256:5a3182b322a706525c46282ca6f064d27a02cffbd449f9f47416f1dc96aa71b0
josepy==1.0.1 \
    --hash=sha256:354a3513038a38bbcd27c97b7c68a8f3dfaff0a135b20a92c6db4cc4ea72915e \
    --hash=sha256:9f48b88ca37f0244238b1cc77723989f7c54f7b90b2eee6294390bacfe870acc
linecache2==1.0.0 \
    --hash=sha256:e78be9c0a0dfcbac712fe04fbf92b96cddae80b1b842f24248214c8496f006ef \
    --hash=sha256:4b26ff4e7110db76eeb6f5a7b64a82623839d595c2038eeda662f2a2db78e97c
# Using an older version of mock here prevents regressions of #5276.
mock==1.3.0 \
    --hash=sha256:3f573a18be94de886d1191f27c168427ef693e8dcfcecf95b170577b2eb69cbb \
    --hash=sha256:1e247dbecc6ce057299eb7ee019ad68314bb93152e81d9a6110d35f4d5eca0f6
ordereddict==1.1 \
    --hash=sha256:1c35b4ac206cef2d24816c89f89cf289dd3d38cf7c449bb3fab7bf6d43f01b1f
packaging==16.8 \
    --hash=sha256:99276dc6e3a7851f32027a68f1095cd3f77c148091b092ea867a351811cfe388 \
    --hash=sha256:5d50835fdf0a7edf0b55e311b7c887786504efea1177abd7e69329a8e5ea619e
parsedatetime==2.1 \
    --hash=sha256:ce9d422165cf6e963905cd5f74f274ebf7cc98c941916169178ef93f0e557838 \
    --hash=sha256:17c578775520c99131634e09cfca5a05ea9e1bd2a05cd06967ebece10df7af2d
pbr==1.8.1 \
    --hash=sha256:46c8db75ae75a056bd1cc07fa21734fe2e603d11a07833ecc1eeb74c35c72e0c \
    --hash=sha256:e2127626a91e6c885db89668976db31020f0af2da728924b56480fc7ccf09649
pyOpenSSL==16.2.0 \
    --hash=sha256:26ca380ddf272f7556e48064bbcd5bd71f83dfc144f3583501c7ddbd9434ee17 \
    --hash=sha256:7779a3bbb74e79db234af6a08775568c6769b5821faecf6e2f4143edb227516e
pyparsing==2.1.8 \
    --hash=sha256:2f0f5ceb14eccd5aef809d6382e87df22ca1da583c79f6db01675ce7d7f49c18 \
    --hash=sha256:03a4869b9f3493807ee1f1cb405e6d576a1a2ca4d81a982677c0c1ad6177c56b \
    --hash=sha256:ab09aee814c0241ff0c503cff30018219fe1fc14501d89f406f4664a0ec9fbcd \
    --hash=sha256:6e9a7f052f8e26bcf749e4033e3115b6dc7e3c85aafcb794b9a88c9d9ef13c97 \
    --hash=sha256:9f463a6bcc4eeb6c08f1ed84439b17818e2085937c0dee0d7674ac127c67c12b \
    --hash=sha256:3626b4d81cfb300dad57f52f2f791caaf7b06c09b368c0aa7b868e53a5775424 \
    --hash=sha256:367b90cc877b46af56d4580cd0ae278062903f02b8204ab631f5a2c0f50adfd0 \
    --hash=sha256:9f1ea360086cd68681e7f4ca8f1f38df47bf81942a0d76a9673c2d23eff35b13
pyRFC3339==1.0 \
    --hash=sha256:eea31835c56e2096af4363a5745a784878a61d043e247d3a6d6a0a32a9741f56 \
    --hash=sha256:8dfbc6c458b8daba1c0f3620a8c78008b323a268b27b7359e92a4ae41325f535
python-augeas==0.5.0 \
    --hash=sha256:67d59d66cdba8d624e0389b87b2a83a176f21f16a87553b50f5703b23f29bac2
pytz==2015.7 \
    --hash=sha256:3abe6a6d3fc2fbbe4c60144211f45da2edbe3182a6f6511af6bbba0598b1f992 \
    --hash=sha256:939ef9c1e1224d980405689a97ffcf7828c56d1517b31d73464356c1f2b7769e \
    --hash=sha256:ead4aefa7007249e05e51b01095719d5a8dd95760089f5730aac5698b1932918 \
    --hash=sha256:3cca0df08bd0ed98432390494ce3ded003f5e661aa460be7a734bffe35983605 \
    --hash=sha256:3ede470d3d17ba3c07638dfa0d10452bc1b6e5ad326127a65ba77e6aaeb11bec \
    --hash=sha256:68c47964f7186eec306b13629627722b9079cd4447ed9e5ecaecd4eac84ca734 \
    --hash=sha256:dd5d3991950aae40a6c81de1578942e73d629808cefc51d12cd157980e6cfc18 \
    --hash=sha256:a77c52062c07eb7c7b30545dbc73e32995b7e117eea750317b5cb5c7a4618f14 \
    --hash=sha256:81af9aec4bc960a9a0127c488f18772dae4634689233f06f65443e7b11ebeb51 \
    --hash=sha256:e079b1dadc5c06246cc1bb6fe1b23a50b1d1173f2edd5104efd40bb73a28f406 \
    --hash=sha256:fbd26746772c24cb93c8b97cbdad5cb9e46c86bbdb1b9d8a743ee00e2fb1fc5d \
    --hash=sha256:99266ef30a37e43932deec2b7ca73e83c8dbc3b9ff703ec73eca6b1dae6befea \
    --hash=sha256:8b6ce1c993909783bc96e0b4f34ea223bff7a4df2c90bdb9c4e0f1ac928689e3
requests==2.12.1 \
    --hash=sha256:3f3f27a9d0f9092935efc78054ef324eb9f8166718270aefe036dfa1e4f68e1e \
    --hash=sha256:2109ecea94df90980be040490ff1d879971b024861539abb00054062388b612e
six==1.10.0 \
    --hash=sha256:0ff78c403d9bccf5a425a6d31a12aa6b47f1c21ca4dc2573a7e2f32a97335eb1 \
    --hash=sha256:105f8d68616f8248e24bf0e9372ef04d3cc10104f1980f54d57b2ce73a5ad56a
traceback2==1.4.0 \
    --hash=sha256:8253cebec4b19094d67cc5ed5af99bf1dba1285292226e98a31929f87a5d6b23 \
    --hash=sha256:05acc67a09980c2ecfedd3423f7ae0104839eccb55fc645773e1caa0951c3030
unittest2==1.1.0 \
    --hash=sha256:13f77d0875db6d9b435e1d4f41e74ad4cc2eb6e1d5c824996092b3430f088bb8 \
    --hash=sha256:22882a0e418c284e1f718a822b3b022944d53d2d908e1690b319a9d3eb2c0579
zope.component==4.2.2 \
    --hash=sha256:282c112b55dd8e3c869a3571f86767c150ab1284a9ace2bdec226c592acaf81a
zope.event==4.1.0 \
    --hash=sha256:dc7a59a2fd91730d3793131a5d261b29e93ec4e2a97f1bc487ce8defee2fe786
zope.interface==4.1.3 \
    --hash=sha256:f07b631f7a601cd8cbd3332d54f43142c7088a83299f859356f08d1d4d4259b3 \
    --hash=sha256:de5cca083b9439d8002fb76bbe6b4998c5a5a721fab25b84298967f002df4c94 \
    --hash=sha256:6788416f7ea7f5b8a97be94825377aa25e8bdc73463e07baaf9858b29e737077 \
    --hash=sha256:6f3230f7254518201e5a3708cbb2de98c848304f06e3ded8bfb39e5825cba2e1 \
    --hash=sha256:5fa575a5240f04200c3088427d0d4b7b737f6e9018818a51d8d0f927a6a2517a \
    --hash=sha256:522194ad6a545735edd75c8a83f48d65d1af064e432a7d320d64f56bafc12e99 \
    --hash=sha256:e8c7b2d40943f71c99148c97f66caa7f5134147f57423f8db5b4825099ce9a09 \
    --hash=sha256:279024f0208601c3caa907c53876e37ad88625f7eaf1cb3842dbe360b2287017 \
    --hash=sha256:2e221a9eec7ccc58889a278ea13dcfed5ef939d80b07819a9a8b3cb1c681484f \
    --hash=sha256:69118965410ec86d44dc6b9017ee3ddbd582e0c0abeef62b3a19dbf6c8ad132b \
    --hash=sha256:d04df8686ec864d0cade8cf199f7f83aecd416109a20834d568f8310ded12dea \
    --hash=sha256:e75a947e15ee97e7e71e02ea302feb2fc62d3a2bb4668bf9dfbed43a506ac7e7 \
    --hash=sha256:4e45d22fb883222a5ab9f282a116fec5ee2e8d1a568ccff6a2d75bbd0eb6bcfc \
    --hash=sha256:bce9339bb3c7a55e0803b63d21c5839e8e479bc85c4adf42ae415b72f94facb2 \
    --hash=sha256:928138365245a0e8869a5999fbcc2a45475a0a6ed52a494d60dbdc540335fedd \
    --hash=sha256:0d841ba1bb840eea0e6489dc5ecafa6125554971f53b5acb87764441e61bceba \
    --hash=sha256:b09c8c1d47b3531c400e0195697f1414a63221de6ef478598a4f1460f7d9a392

# Contains the requirements for the letsencrypt package.
#
# Since the letsencrypt package depends on certbot and using pip with hashes
# requires that all installed packages have hashes listed, this allows
# dependency-requirements.txt to be used without requiring a hash for a
# (potentially unreleased) Certbot package.

letsencrypt==0.7.0 \
    --hash=sha256:105a5fb107e45bcd0722eb89696986dcf5f08a86a321d6aef25a0c7c63375ade \
    --hash=sha256:c36e532c486a7e92155ee09da54b436a3c420813ec1c590b98f635d924720de9

certbot==0.21.0 \
    --hash=sha256:b6fc9cf80e8e2925827c61ca92c32faa935bbadaf14448e2d7f40e1f8f2cccdb \
    --hash=sha256:07ca3246d3462fe73418113cc5c1036545f4b2312831024da923054de3a85857
acme==0.21.0 \
    --hash=sha256:4ef91a62c30b9d6bd1dd0b5ac3a8c7e70203e08e5269d3d26311dd6648aaacda \
    --hash=sha256:d64eae267c0bb21c98fa889b4e0be4c473ca8e80488d3de057e803d6d167544d
certbot-apache==0.21.0 \
    --hash=sha256:026c23fec4def727f88acd15f66b5641f7ba1f767f0728fd56798cf3500be0c5 \
    --hash=sha256:185dae50c680fa3c09646907a6256c6b4ddf8525723d3b13b9b33d1a3118663b
certbot-nginx==0.21.0 \
    --hash=sha256:e5ac3a203871f13e7e72d4922e401364342f2999d130c959f90949305c33d2bc \
    --hash=sha256:88be95916935980edc4c6ec3f39031ac47f5b73d6e43dfa3694b927226432642

UNLIKELY_EOF
    # -------------------------------------------------------------------------
    cat << "UNLIKELY_EOF" > "$TEMP_DIR/pipstrap.py"
#!/usr/bin/env python
"""A small script that can act as a trust root for installing pip 8

Embed this in your project, and your VCS checkout is all you have to trust. In
a post-peep era, this lets you claw your way to a hash-checking version of pip,
with which you can install the rest of your dependencies safely. All it assumes
is Python 2.6 or better and *some* version of pip already installed. If
anything goes wrong, it will exit with a non-zero status code.

"""
# This is here so embedded copies are MIT-compliant:
# Copyright (c) 2016 Erik Rose
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
from __future__ import print_function
from distutils.version import StrictVersion
from hashlib import sha256
from os.path import join
from pipes import quote
from shutil import rmtree
try:
    from subprocess import check_output
except ImportError:
    from subprocess import CalledProcessError, PIPE, Popen

    def check_output(*popenargs, **kwargs):
        if 'stdout' in kwargs:
            raise ValueError('stdout argument not allowed, it will be '
                             'overridden.')
        process = Popen(stdout=PIPE, *popenargs, **kwargs)
        output, unused_err = process.communicate()
        retcode = process.poll()
        if retcode:
            cmd = kwargs.get("args")
            if cmd is None:
                cmd = popenargs[0]
            raise CalledProcessError(retcode, cmd)
        return output
from sys import exit, version_info
from tempfile import mkdtemp
try:
    from urllib2 import build_opener, HTTPHandler, HTTPSHandler
except ImportError:
    from urllib.request import build_opener, HTTPHandler, HTTPSHandler
try:
    from urlparse import urlparse
except ImportError:
    from urllib.parse import urlparse  # 3.4


__version__ = 1, 3, 0
PIP_VERSION = '9.0.1'


# wheel has a conditional dependency on argparse:
maybe_argparse = (
    [('https://pypi.python.org/packages/18/dd/'
      'e617cfc3f6210ae183374cd9f6a26b20514bbb5a792af97949c5aacddf0f/'
      'argparse-1.4.0.tar.gz',
      '62b089a55be1d8949cd2bc7e0df0bddb9e028faefc8c32038cc84862aefdd6e4')]
    if version_info < (2, 7, 0) else [])


PACKAGES = maybe_argparse + [
    # Pip has no dependencies, as it vendors everything:
    ('https://pypi.python.org/packages/11/b6/'
     'abcb525026a4be042b486df43905d6893fb04f05aac21c32c638e939e447/'
     'pip-{0}.tar.gz'
     .format(PIP_VERSION),
     '09f243e1a7b461f654c26a725fa373211bb7ff17a9300058b205c61658ca940d'),
    # This version of setuptools has only optional dependencies:
    ('https://pypi.python.org/packages/69/65/'
     '4c544cde88d4d876cdf5cbc5f3f15d02646477756d89547e9a7ecd6afa76/'
     'setuptools-20.2.2.tar.gz',
     '24fcfc15364a9fe09a220f37d2dcedc849795e3de3e4b393ee988e66a9cbd85a'),
    ('https://pypi.python.org/packages/c9/1d/'
     'bd19e691fd4cfe908c76c429fe6e4436c9e83583c4414b54f6c85471954a/'
     'wheel-0.29.0.tar.gz',
     '1ebb8ad7e26b448e9caa4773d2357849bf80ff9e313964bcaf79cbf0201a1648')
]


class HashError(Exception):
    def __str__(self):
        url, path, actual, expected = self.args
        return ('{url} did not match the expected hash {expected}. Instead, '
                'it was {actual}. The file (left at {path}) may have been '
                'tampered with.'.format(**locals()))


def hashed_download(url, temp, digest):
    """Download ``url`` to ``temp``, make sure it has the SHA-256 ``digest``,
    and return its path."""
    # Based on pip 1.4.1's URLOpener but with cert verification removed. Python
    # >=2.7.9 verifies HTTPS certs itself, and, in any case, the cert
    # authenticity has only privacy (not arbitrary code execution)
    # implications, since we're checking hashes.
    def opener():
        opener = build_opener(HTTPSHandler())
        # Strip out HTTPHandler to prevent MITM spoof:
        for handler in opener.handlers:
            if isinstance(handler, HTTPHandler):
                opener.handlers.remove(handler)
        return opener

    def read_chunks(response, chunk_size):
        while True:
            chunk = response.read(chunk_size)
            if not chunk:
                break
            yield chunk

    response = opener().open(url)
    path = join(temp, urlparse(url).path.split('/')[-1])
    actual_hash = sha256()
    with open(path, 'wb') as file:
        for chunk in read_chunks(response, 4096):
            file.write(chunk)
            actual_hash.update(chunk)

    actual_digest = actual_hash.hexdigest()
    if actual_digest != digest:
        raise HashError(url, path, actual_digest, digest)
    return path


def main():
    pip_version = StrictVersion(check_output(['pip', '--version'])
                                .decode('utf-8').split()[1])
    min_pip_version = StrictVersion(PIP_VERSION)
    if pip_version >= min_pip_version:
        return 0
    has_pip_cache = pip_version >= StrictVersion('6.0')

    temp = mkdtemp(prefix='pipstrap-')
    try:
        downloads = [hashed_download(url, temp, digest)
                     for url, digest in PACKAGES]
        check_output('pip install --no-index --no-deps -U ' +
                     # Disable cache since we're not using it and it otherwise
                     # sometimes throws permission warnings:
                     ('--no-cache-dir ' if has_pip_cache else '') +
                     ' '.join(quote(d) for d in downloads),
                     shell=True)
    except HashError as exc:
        print(exc)
    except Exception:
        rmtree(temp)
        raise
    else:
        rmtree(temp)
        return 0
    return 1


if __name__ == '__main__':
    exit(main())

UNLIKELY_EOF
    # -------------------------------------------------------------------------
    # Set PATH so pipstrap upgrades the right (v)env:
    PATH="$VENV_BIN:$PATH" "$VENV_BIN/python" "$TEMP_DIR/pipstrap.py"
    set +e
    if [ "$VERBOSE" = 1 ]; then
      "$VENV_BIN/pip" install --disable-pip-version-check --no-cache-dir --require-hashes -r "$TEMP_DIR/letsencrypt-auto-requirements.txt"
    else
      PIP_OUT=`"$VENV_BIN/pip" install --disable-pip-version-check --no-cache-dir --require-hashes -r "$TEMP_DIR/letsencrypt-auto-requirements.txt" 2>&1`
    fi
    PIP_STATUS=$?
    set -e
    if [ "$PIP_STATUS" != 0 ]; then
      # Report error. (Otherwise, be quiet.)
      error "Had a problem while installing Python packages."
      if [ "$VERBOSE" != 1 ]; then
        error
        error "pip prints the following errors: "
        error "====================================================="
        error "$PIP_OUT"
        error "====================================================="
        error
        error "Certbot has problem setting up the virtual environment."

        if `echo $PIP_OUT | grep -q Killed` || `echo $PIP_OUT | grep -q "allocate memory"` ; then
          error
          error "Based on your pip output, the problem can likely be fixed by "
          error "increasing the available memory."
        else
          error
          error "We were not be able to guess the right solution from your pip "
          error "output."
        fi

        error
        error "Consult https://certbot.eff.org/docs/install.html#problems-with-python-virtual-environment"
        error "for possible solutions."
        error "You may also find some support resources at https://certbot.eff.org/support/ ."
      fi
      rm -rf "$VENV_PATH"
      exit 1
    fi

    if [ -d "$OLD_VENV_PATH" -a ! -L "$OLD_VENV_PATH" ]; then
      rm -rf "$OLD_VENV_PATH"
      ln -s "$VENV_PATH" "$OLD_VENV_PATH"
    fi

    say "Installation succeeded."
  fi
  "$VENV_BIN/letsencrypt" "$@"

else
  # Phase 1: Upgrade certbot-auto if necessary, then self-invoke.
  #
  # Each phase checks the version of only the thing it is responsible for
  # upgrading. Phase 1 checks the version of the latest release of
  # certbot-auto (which is always the same as that of the certbot
  # package). Phase 2 checks the version of the locally installed certbot.
  export PHASE_1_VERSION="$LE_AUTO_VERSION"

  if [ ! -f "$VENV_BIN/letsencrypt" ]; then
    if ! OldVenvExists; then
      if [ "$HELP" = 1 ]; then
        echo "$USAGE"
        exit 0
      fi
      # If it looks like we've never bootstrapped before, bootstrap:
      Bootstrap
    fi
  fi
  if [ "$OS_PACKAGES_ONLY" = 1 ]; then
    say "OS packages installed."
    exit 0
  fi

  if [ "$NO_SELF_UPGRADE" != 1 ]; then
    TEMP_DIR=$(TempDir)
    trap 'rm -rf "$TEMP_DIR"' EXIT
    # ---------------------------------------------------------------------------
    cat << "UNLIKELY_EOF" > "$TEMP_DIR/fetch.py"
"""Do downloading and JSON parsing without additional dependencies. ::

    # Print latest released version of LE to stdout:
    python fetch.py --latest-version

    # Download letsencrypt-auto script from git tag v1.2.3 into the folder I'm
    # in, and make sure its signature verifies:
    python fetch.py --le-auto-script v1.2.3

On failure, return non-zero.

"""

from __future__ import print_function, unicode_literals

from distutils.version import LooseVersion
from json import loads
from os import devnull, environ
from os.path import dirname, join
import re
import ssl
from subprocess import check_call, CalledProcessError
from sys import argv, exit
try:
    from urllib2 import build_opener, HTTPHandler, HTTPSHandler
    from urllib2 import HTTPError, URLError
except ImportError:
    from urllib.request import build_opener, HTTPHandler, HTTPSHandler
    from urllib.error import HTTPError, URLError

PUBLIC_KEY = environ.get('LE_AUTO_PUBLIC_KEY', """-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6MR8W/galdxnpGqBsYbq
OzQb2eyW15YFjDDEMI0ZOzt8f504obNs920lDnpPD2/KqgsfjOgw2K7xWDJIj/18
xUvWPk3LDkrnokNiRkA3KOx3W6fHycKL+zID7zy+xZYBuh2fLyQtWV1VGQ45iNRp
9+Zo7rH86cdfgkdnWTlNSHyTLW9NbXvyv/E12bppPcEvgCTAQXgnDVJ0/sqmeiij
n9tTFh03aM+R2V/21h8aTraAS24qiPCz6gkmYGC8yr6mglcnNoYbsLNYZ69zF1XH
cXPduCPdPdfLlzVlKK1/U7hkA28eG3BIAMh6uJYBRJTpiGgaGdPd7YekUB8S6cy+
CQIDAQAB
-----END PUBLIC KEY-----
""")

class ExpectedError(Exception):
    """A novice-readable exception that also carries the original exception for
    debugging"""


class HttpsGetter(object):
    def __init__(self):
        """Build an HTTPS opener."""
        # Based on pip 1.4.1's URLOpener
        # This verifies certs on only Python >=2.7.9, and when NO_CERT_VERIFY isn't set.
        if environ.get('NO_CERT_VERIFY') == '1' and hasattr(ssl, 'SSLContext'):
            self._opener = build_opener(HTTPSHandler(context=cert_none_context()))
        else:
            self._opener = build_opener(HTTPSHandler())
        # Strip out HTTPHandler to prevent MITM spoof:
        for handler in self._opener.handlers:
            if isinstance(handler, HTTPHandler):
                self._opener.handlers.remove(handler)

    def get(self, url):
        """Return the document contents pointed to by an HTTPS URL.

        If something goes wrong (404, timeout, etc.), raise ExpectedError.

        """
        try:
            # socket module docs say default timeout is None: that is, no
            # timeout
            return self._opener.open(url, timeout=30).read()
        except (HTTPError, IOError) as exc:
            raise ExpectedError("Couldn't download %s." % url, exc)


def write(contents, dir, filename):
    """Write something to a file in a certain directory."""
    with open(join(dir, filename), 'wb') as file:
        file.write(contents)


def latest_stable_version(get):
    """Return the latest stable release of letsencrypt."""
    metadata = loads(get(
        environ.get('LE_AUTO_JSON_URL',
                    'https://pypi.python.org/pypi/certbot/json')).decode('UTF-8'))
    # metadata['info']['version'] actually returns the latest of any kind of
    # release release, contrary to https://wiki.python.org/moin/PyPIJSON.
    # The regex is a sufficient regex for picking out prereleases for most
    # packages, LE included.
    return str(max(LooseVersion(r) for r
                   in metadata['releases'].keys()
                   if re.match('^[0-9.]+$', r)))


def verified_new_le_auto(get, tag, temp_dir):
    """Return the path to a verified, up-to-date letsencrypt-auto script.

    If the download's signature does not verify or something else goes wrong
    with the verification process, raise ExpectedError.

    """
    le_auto_dir = environ.get(
        'LE_AUTO_DIR_TEMPLATE',
        'https://raw.githubusercontent.com/certbot/certbot/%s/'
        'letsencrypt-auto-source/') % tag
    write(get(le_auto_dir + 'letsencrypt-auto'), temp_dir, 'letsencrypt-auto')
    write(get(le_auto_dir + 'letsencrypt-auto.sig'), temp_dir, 'letsencrypt-auto.sig')
    write(PUBLIC_KEY.encode('UTF-8'), temp_dir, 'public_key.pem')
    try:
        with open(devnull, 'w') as dev_null:
            check_call(['openssl', 'dgst', '-sha256', '-verify',
                        join(temp_dir, 'public_key.pem'),
                        '-signature',
                        join(temp_dir, 'letsencrypt-auto.sig'),
                        join(temp_dir, 'letsencrypt-auto')],
                       stdout=dev_null,
                       stderr=dev_null)
    except CalledProcessError as exc:
        raise ExpectedError("Couldn't verify signature of downloaded "
                            "certbot-auto.", exc)


def cert_none_context():
    """Create a SSLContext object to not check hostname."""
    # PROTOCOL_TLS isn't available before 2.7.13 but this code is for 2.7.9+, so use this.
    context = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
    context.verify_mode = ssl.CERT_NONE
    return context


def main():
    get = HttpsGetter().get
    flag = argv[1]
    try:
        if flag == '--latest-version':
            print(latest_stable_version(get))
        elif flag == '--le-auto-script':
            tag = argv[2]
            verified_new_le_auto(get, tag, dirname(argv[0]))
    except ExpectedError as exc:
        print(exc.args[0], exc.args[1])
        return 1
    else:
        return 0


if __name__ == '__main__':
    exit(main())

UNLIKELY_EOF
    # ---------------------------------------------------------------------------
    DeterminePythonVersion "NOCRASH"
    if [ "$PYVER" -lt "$MIN_PYVER" ]; then
      error "WARNING: couldn't find Python $MIN_PYTHON_VERSION+ to check for updates."
    elif ! REMOTE_VERSION=`"$LE_PYTHON" "$TEMP_DIR/fetch.py" --latest-version` ; then
      error "WARNING: unable to check for updates."
    elif [ "$LE_AUTO_VERSION" != "$REMOTE_VERSION" ]; then
      say "Upgrading certbot-auto $LE_AUTO_VERSION to $REMOTE_VERSION..."

      # Now we drop into Python so we don't have to install even more
      # dependencies (curl, etc.), for better flow control, and for the option of
      # future Windows compatibility.
      "$LE_PYTHON" "$TEMP_DIR/fetch.py" --le-auto-script "v$REMOTE_VERSION"

      # Install new copy of certbot-auto.
      # TODO: Deal with quotes in pathnames.
      say "Replacing certbot-auto..."
      # Clone permissions with cp. chmod and chown don't have a --reference
      # option on macOS or BSD, and stat -c on Linux is stat -f on macOS and BSD:
      cp -p "$0" "$TEMP_DIR/letsencrypt-auto.permission-clone"
      cp "$TEMP_DIR/letsencrypt-auto" "$TEMP_DIR/letsencrypt-auto.permission-clone"
      # Using mv rather than cp leaves the old file descriptor pointing to the
      # original copy so the shell can continue to read it unmolested. mv across
      # filesystems is non-atomic, doing `rm dest, cp src dest, rm src`, but the
      # cp is unlikely to fail if the rm doesn't.
      mv -f "$TEMP_DIR/letsencrypt-auto.permission-clone" "$0"
    fi  # A newer version is available.
  fi  # Self-upgrading is allowed.

  RerunWithArgs --le-auto-phase2 "$@"
fi
