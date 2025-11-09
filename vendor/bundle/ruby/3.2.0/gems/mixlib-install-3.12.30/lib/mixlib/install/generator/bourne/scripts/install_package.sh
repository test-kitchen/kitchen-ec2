# install_package.sh
############
# Installs a package and removed the temp directory.
#
# Inputs:
# $download_filename: Name of the file to be installed.
# $filetype: Type of the file to be installed.
# $version: The version requested. Used only for warning user if not set.
############

if test "x$version" = "x" -a "x$CI" != "xtrue"; then
  echo
  echo "WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING"
  echo
  echo "You are installing a package without a version pin.  If you are installing"
  echo "on production servers via an automated process this is DANGEROUS and you will"
  echo "be upgraded without warning on new releases, even to new major releases."
  echo "Letting the version float is only appropriate in test, development or"
  echo "CI/CD environments."
  echo
  echo "WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING"
  echo
fi

install_file $filetype "$download_filename"

if test "x$tmp_dir" != "x"; then
  rm -r "$tmp_dir"
fi

############
# end of install_package.sh
############
