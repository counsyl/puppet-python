# == Class: python::darwin
#
# Performs the setup necessary (e.g., downloading the installation MSI) to
# install Python.  Also sets variables (like $site_packages, $interpreter)
# that have to be specially calculated on Darwin.
#
# === Parameters
#
# [*arch*]
#  The architecture of Python to install, defaults to the architecture of
#  the system (e.g., 'x64' on 64-bit system).
#
# [*allusers*]
#  Whether to install Python for all users, defaults to true.
#
# [*base_url*]
#  The base url to use when downloading Python, undefined by default.
#
# [*source*]
#  The HTTP or UNC source to the Python package, undefined by default.
#
# [*targetdir*]
#  The target installation directory to use for the Python package,
#  undefined by default.
#
# [*version*]
#  The version of Python to install, defaults to '2.7.6'.
#
# [*darwin_path*]
#  Whether or not to add Python directory to the Darwin system %Path%,
#  defaults to true.
#
class python::darwin(
  $allusers  = true,
  $arch      = $::architecture,
  $base_url  = undef,
  $source    = undef,
  $targetdir = undef,
  $version   = $python::params::full_version,
  $darwin_path  = true,
) inherits python::params {

  $basename = "python-${version}-macosx10.6.pkg"

  $package = "python-${version}-macosx10.6"

  if $base_url {
      $source_uri = "${base_url}${basename}"
    } else {
      $source_uri = "http://www.python.org/ftp/python/${version}/${basename}"
    }

  $package_source = $source_uri

  if $allusers {
    $allusers_val = '1'
  } else {
    $allusers_val = '0'
  }

  # Determining Python's path.
}
