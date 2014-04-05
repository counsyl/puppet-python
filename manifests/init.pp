# == Class: python
#
# Installs the Python language runtime.  Defaults to the most stable version
# for the platform, preferring version 2 (no 3 support at this time).
#
# === Parameters
#
# [*ensure*]
#  The ensure value for the Python package, uses the default for the platform
#  (typically this is just 'installed' unless running on OpenBSD).
#
# [*package*]
#  The name of the Python package to install, uses platform default.
#
# [*provider*]
#  The provider for the Python package, uses platform default.
#
# [*source*]
#  The source used for the Python package -- only used on OpenBSD platforms
#  at the moment.  For windows, customize using `python::windows::source`.
#
class python (
  $ensure   = $python::params::ensure,
  $package  = $python::params::package,
  $provider = $python::params::provider,
  $source   = $python::params::source,
) inherits python::params {

  if $::osfamily == 'windows' {
    # Include python::windows, this downloads the MSI and calculates paths.
    include python::windows

    # Get package name, install options and source for Windows.
    $install_options = $python::windows::install_options
    $package_source = $python::windows::source
    $python_package = $python::windows::package
    
    # Set interpreter and site_packages variable.
    $interpreter = $python::windows::interpreter
    $site_packages = $python::windows::site_packages

    # Ensure that python::windows comes before the package.
    Class['python::windows'] -> Package[$package]
  } else {
    $package_source = $source
    $python_package = $package
  }

  # The resource for the Python package.
  package { $python_package:
    ensure          => $ensure,
    provider        => $provider,
    source          => $package_source,
    install_options => $install_options,
  }

  # Include setuptools and pip for packaging.  Ensure relationships are
  # setup between the Python package and the setuptools/pip classes.
  case $ensure {
    'uninstalled', 'absent': {
      class { 'python::pip':
        ensure => absent,
      } ->
      class { 'python::setuptools':
        ensure => absent,
      } ->
      Package[$python_package]
    }
    default: {
      include python::setuptools
      include python::pip
      Package[$python_package] -> Class['python::setuptools'] -> Class['python::pip']

      # Ensure this class comes before any package resources with a `pip` or `pipx`
      # provider, as well as any `venv` resources.
      Class['python'] -> Package<| provider == pip |>
      Class['python'] -> Package<| provider == pipx |>
      Class['python'] -> Venv<| |>
    }
  }

  # OpenBSD needs some extra links to complete the experience.
  if $::osfamily == 'OpenBSD' {
    class { 'python::openbsd':
      ensure  => $ensure,
      require => Package[$python_package],
    }
  }
}
