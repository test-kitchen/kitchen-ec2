# platform_detection.sh
############
# This section makes platform detection compatible with omnitruck on the system
#   it runs.
#
# Outputs:
# $platform: Name of the platform.
# $platform_version: Version of the platform.
# $machine: System's architecture.
############

#
# Platform and Platform Version detection
#
# NOTE: This logic should match ohai platform and platform_version matching.
# do not invent new platform and platform_version schemas, just make this behave
# like what ohai returns as platform and platform_version for the system.
#
# ALSO NOTE: Do not mangle platform or platform_version here.  It is less error
# prone and more future-proof to do that in the server, and then all omnitruck clients
# will 'inherit' the changes (install.sh is not the only client of the omnitruck
# endpoint out there).
#

machine=`uname -m`
os=`uname -s`

if test -f "/etc/lsb-release" && grep DISTRIB_ID /etc/lsb-release >/dev/null && ! grep wrlinux /etc/lsb-release >/dev/null; then
  platform=`grep DISTRIB_ID /etc/lsb-release | cut -d "=" -f 2 | tr '[A-Z]' '[a-z]'`
  platform_version=`grep DISTRIB_RELEASE /etc/lsb-release | cut -d "=" -f 2`

  if test "$platform" = "\"cumulus linux\""; then
    platform="cumulus_linux"
  elif test "$platform" = "\"cumulus networks\""; then
    platform="cumulus_networks"
  fi

elif test -f "/etc/debian_version"; then
  platform="debian"
  platform_version=`cat /etc/debian_version`
elif test -f "/etc/Eos-release"; then
  # EOS may also contain /etc/redhat-release so this check must come first.
  platform=arista_eos
  platform_version=`awk '{print $4}' /etc/Eos-release`
  machine="i386"
elif test -f "/etc/redhat-release"; then
  platform=`sed 's/^\(.\+\) release.*/\1/' /etc/redhat-release | tr '[A-Z]' '[a-z]'`
  platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release`
  
  if test "$platform" = "rocky linux"; then
  	source /etc/os-release
 	os="${REDHAT_SUPPORT_PRODUCT}"
  	platform_version="${ROCKY_SUPPORT_PRODUCT_VERSION}"
        platform=$ID

  elif test "$platform" = "xenserver"; then
    # Current XenServer 6.2 is based on CentOS 5, platform is not reset to "el" server should handle response
    platform="xenserver"
  else
    # FIXME: use "redhat"
    platform="el"
  fi

elif test -f "/etc/system-release"; then
  platform=`sed 's/^\(.\+\) release.\+/\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
  platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
  case $platform in amazon*) # sh compat method of checking for a substring
    . /etc/os-release
    platform_version=$VERSION_ID

    case $platform_version in
      "2022"|"2023")
        platform="amazon"
        platform_version=$platform_version
      ;;
      "2")
        platform="el"
        platform_version="7"
        ;;
      *)
        platform="el"

        # VERSION_ID will match YYYY.MM for Amazon Linux AMIs
        platform_version="6"
        ;;
    esac
  esac


# Apple macOS
elif test -f "/usr/bin/sw_vers"; then
  platform="mac_os_x"
  # Matching the tab-space with sed is error-prone
  platform_version=`sw_vers | awk '/^ProductVersion:/ { print $2 }' | cut -d. -f1,2`
elif test -f "/etc/release"; then
  machine=`/usr/bin/uname -p`
  if grep SmartOS /etc/release >/dev/null; then
    platform="smartos"
    platform_version=`grep ^Image /etc/product | awk '{ print $3 }'`
  else
    platform="solaris2"
    platform_version=`/usr/bin/uname -r`
  fi
elif test -f "/etc/SuSE-release"; then
  if grep 'Enterprise' /etc/SuSE-release >/dev/null;
  then
      platform="sles"
      platform_version=`awk '/^VERSION/ {V = $3}; /^PATCHLEVEL/ {P = $3}; END {print V "." P}' /etc/SuSE-release`
  else # opensuse 43 only. 15 ships with /etc/os-release only
      platform="opensuseleap"
      platform_version=`awk '/^VERSION =/ { print $3 }' /etc/SuSE-release`
  fi
elif test "x$os" = "xFreeBSD"; then
  platform="freebsd"
  platform_version=`uname -r | sed 's/-.*//'`
elif test "x$os" = "xAIX"; then
  platform="aix"
  platform_version="`uname -v`.`uname -r`"
  machine="powerpc"
elif test -f "/etc/os-release"; then
  . /etc/os-release
  if test "x$CISCO_RELEASE_INFO" != "x"; then
    . $CISCO_RELEASE_INFO
  fi

  platform=$ID

  # VERSION_ID is always the preferred variable to use, but not
  # every distro has it so fallback to VERSION
  if test "x$VERSION_ID" != "x"; then
    platform_version=$VERSION_ID
  else
    platform_version=$VERSION
  fi
fi

if test "x$platform" = "x"; then
  echo "Unable to determine platform version!"
  report_bug
  exit 1
fi

#
# NOTE: platform mangling in the install.sh is DEPRECATED
#
# - install.sh should be true to ohai and should not remap
#   platform or platform versions.
#
# - remapping platform and mangling platform version numbers is
#   now the complete responsibility of the server-side endpoints
#

major_version=`echo $platform_version | cut -d. -f1`
case $platform in
  # FIXME: should remove this case statement completely
  "el")
    # FIXME:  "el" is deprecated, should use "redhat"
    platform_version=$major_version
    ;;
  "debian")
    if test "x$major_version" = "x5"; then
      # This is here for potential back-compat.
      # We do not have 5 in versions we publish for anymore but we
      # might have it for earlier versions.
      platform_version="6"
    else
      platform_version=$major_version
    fi
    ;;
  "freebsd")
    platform_version=$major_version
    ;;
  "sles")
    platform_version=$major_version
    ;;
  "opensuseleap")
    platform_version=$major_version
    ;;
esac

# normalize the architecture we detected
case $machine in
  "arm64"|"aarch64")
    machine="aarch64"
    ;;
  "x86_64"|"amd64"|"x64")
    machine="x86_64"
    ;;
  "i386"|"i86pc"|"x86"|"i686")
    machine="i386"
    ;;
  "sparc"|"sun4u"|"sun4v")
    machine="sparc"
    ;;
esac

if test "x$platform_version" = "x"; then
  echo "Unable to determine platform version!"
  report_bug
  exit 1
fi

if test "x$platform" = "xsolaris2"; then
  # hack up the path on Solaris to find wget, pkgadd
  PATH=/usr/sfw/bin:/usr/sbin:$PATH
  export PATH
fi

echo "$platform $platform_version $machine"

############
# end of platform_detection.sh
############
