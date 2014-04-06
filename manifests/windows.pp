# == Class: python::windows
#
# Performs the setup necessary (e.g., downloading the installation MSI) to
# install Python.  Also sets variables (like $site_packages, $interpreter)
# that have to be specially calculated on Windows.
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
# [*win_path*]
#  Whether or not to add Python directory to the Windows system %Path%,
#  defaults to true.
#
class python::windows(
  $allusers  = true,
  $arch      = $::architecture,
  $base_url  = undef,
  $source    = undef,
  $targetdir = undef,
  $version   = $python::params::full_version,
  $win_path  = true,
) inherits python::params {
  include ::windows

  # The basename of the MSI and the package's name depend on the architecture.
  if $arch == 'x64' {
    $basename = "python-${version}.amd64.msi"
    $package = "Python ${version} (64-bit)"
  } else {
    $basename = "python-${version}.msi"
    $package = "Python ${version}"
  }

  # Determining where the MSI is coming from for the package resource.
  if $source {
    $source_uri = $source
  } else {
    if $base_url {
      $source_uri = "${base_url}${basename}"
    } else {
      $source_uri = "http://www.python.org/ftp/python/${version}/${basename}"
    }
  }

  # If a non-UNC URL is used, download the MSI with sys::fetch.
  if $source_uri !~ /^[\\]+/ {
    $package_source = "${::windows::installers}\\${basename}"

    sys::fetch { 'download-windows-python':
      destination => $package_source,
      source      => $source_uri,
      require     => File[$::windows::installers],
    }
  } else {
    $package_source = $source_uri
  }

  if $allusers {
    $allusers_val = '1'
  } else {
    $allusers_val = '0'
  }

  # Determining Python's path.
  if $targetdir {
    $path = $targetdir
  } else {
    $path = inline_template(
      "<%= \"#{scope['::windows::system_root']}Python#{@version.split('.').join('')[0..1]}\" %>"
    )
  }

  # The install options for the MSI.
  $install_options = [{'TARGETDIR' => $path, 'ALLUSERS' => $allusers_val}]

  # Location of Python interpreter.
  $interpreter = "${path}\\python.exe"

  # Python scripts path.
  $scripts = "${path}\\Scripts"

  # Where site-packages lives.
  $site_packages = "${path}\\Lib\\site-packages"

  # If `$win_path` is set to true, ensure that Python is a component of
  # the Windows %PATH%.
  if $win_path {
    windows::path { 'python-path':
      directory => $path,
    }

    windows::path { 'python-scripts':
      directory => $scripts,
    }
  }
}
