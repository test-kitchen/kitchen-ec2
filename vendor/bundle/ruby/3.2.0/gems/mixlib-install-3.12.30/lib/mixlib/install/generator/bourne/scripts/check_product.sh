if test -d "/opt/$project" && test "x$install_strategy" = "xonce"; then
  echo "$project installation detected"
  echo "install_strategy set to 'once'"
  echo "Nothing to install"
  exit
fi
