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
    # Include python::windows, this downloads the MSI and sets path variables.
    include python::windows

    # Get install options, package name and source for Windows.
    $install_options = $python::windows::install_options
    $package_source = $python::windows::package_source
    $python_package = $python::windows::package

    # Set up variables that couldn't be set in python::params.
    $interpreter = $python::windows::interpreter
    $scripts = $python::windows::scripts
    $site_packages = $python::windows::site_packages

    # Ensure that python::windows comes before the package.
    Class['python::windows'] -> Package[$python_package]
  } else {
    $package_source = $source
    $python_package = $package
    $scripts = '/usr/local/bin'
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
  # Finally, an anchor is used to ensure the setuptools/pip classes
  # are contained within this class.
  include python::setuptools
  include python::pip
  Package[$python_package]    ->
  Class['python::setuptools'] ->
  Class['python::pip']        ->
  anchor { 'python': }

  # OpenBSD needs some extra links to complete the experience.
  if $::osfamily == 'OpenBSD' {
    include python::openbsd
    Class['python::pip'] -> Class['python::openbsd']
  }

  # Ensure this class comes before any package resources with a `pip` or `pipx`
  # provider, as well as any `venv` resources.
  Class['python'] -> Package<| provider == pip |>
  Class['python'] -> Package<| provider == pipx |>
}
