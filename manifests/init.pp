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
# [*ez_setup*]
#  Use `ez_setup.py` to bootstrap the installation of setuptools, and then
#  pip.  Useful on platforms with extremely dated system packages of both.
#  Defaults to false.
#
# [*ez_base_url*]
#  The base url to download the setuptools package from when using
#  `ez_setup.py`.  Defaults to:
#    'https://pypi.python.org/packages/source/s/setuptools/'
#
# [*ez_version*]
#  The version of setuptools to install with `ez_setup.py`, defaults to
#  '3.4.4'
#
# [*package*]
#  The name of the Python package to install, uses the platform default.
#
# [*provider*]
#  The provider for the Python packages, uses the platform default.
#
# [*pip_ensure*]
#  The ensure value for the pip package, 'installed' by default.
#
# [*pip_package*]
#  The name of the pip package to install, uses the platform default.
#  If not set, then `easy_install` will be used to install pip.
#
# [*setuptools_ensure*]
#  The ensure value for the setuptools package, 'installed' by default.
#
# [*setuptools_package*]
#  The name of the setuptools package to install, uses platform default.
#  If not set, then `ez_setup.py` will be used to install setuptools.
#
# [*source*]
#  The source used for the Python packages -- only used on OpenBSD platforms
#  at the moment.  For windows, customize using `python::windows::source`.
#
class python (
  $ensure             = $python::params::ensure,
  $ez_setup           = false,
  $ez_base_url        = $python::params::ez_base_url,
  $ez_version         = $python::params::ez_version,
  $package            = $python::params::package,
  $provider           = $python::params::provider,
  $pip_ensure         = 'installed',
  $pip_package        = $python::params::pip,
  $setuptools_ensure  = 'installed',
  $setuptools_package = $python::params::setuptools,
  $source             = $python::params::source,
) inherits python::params {

  ## variables and initial setup (if necessary)

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
    $install_options = undef
    $package_source = $source
    $python_package = $package
    $scripts = '/usr/local/bin'
  }

  ## python

  # The resource for the Python package.
  package { $python_package:
    ensure          => $ensure,
    provider        => $provider,
    source          => $package_source,
    install_options => $install_options,
  }

  ## setuptools

  if ! $ez_setup and $setuptools_package {
    package { $setuptools_package:
      ensure   => $setuptools_ensure,
      provider => $provider,
      source   => $source,
      require  => Package[$python_package],
    }

    # Set up path to easy_install, in case there's no `pip` package
    # specified.
    if $::osfamily == 'OpenBSD' {
      $easy_install = "/usr/local/bin/easy_install-${version}"
    } else {
      $easy_install = '/usr/bin/easy_install'
    }

    $setuptools_require = Package[$setuptools_package]
  } elsif $setuptools_ensure in ['installed', 'present'] {
    # When there's no package, then use ez_setup.py.
    if $::osfamily == 'windows' {
      # Have to place ez_setup.py in same directory as interpreter as
      # the `Scripts` folder doesn't exist yet.
      $ez_setup_py = "${python::windows::path}\\ez_setup.py"
      $easy_install = "${scripts}\\easy_install.exe"
    } else {
      $ez_setup_py = "${scripts}/ez_setup.py"
      $easy_install = "${scripts}/easy_install"
    }

    # Create the `ez_setup.py` from template (which allows customization of
    # the setuptools verion and URL to download from).  The owner, group, and
    # mode of this file are inherited from python::params (and left undefined
    # on Windows).
    file { $ez_setup_py:
      ensure  => file,
      owner   => $ez_setup_owner,
      group   => $ez_setup_group,
      mode    => $ez_setup_mode,
      content => template('python/ez_setup.py.erb'),
      require => Package[$python_package],
    }

    # Install setuptools by running ez_setup.py.
    exec { 'setuptools-install':
      command => "${interpreter} ${ez_setup_py}",
      creates => $easy_install,
      require => File[$ez_setup_py],
    }

    $setuptools_require = Exec['setuptools-install']
  }

  ## pip

  if ! $ez_setup and $pip_package {
    if $::osfamily == 'RedHat' {
      # RedHat needs EPEL for pip package.
      include sys::redhat::epel
      Class['sys::redhat::epel'] -> Package[$pip_package]
    }

    package { $pip_package:
      ensure   => $pip_ensure,
      provider => $provider,
      source   => $source,
      require  => $setuptools_require,
    }
  } elsif $pip_ensure in ['installed', 'present'] {
    # Use setuptools to bootstrap pip if we aren't using a package.
    if $::osfamily == 'windows' {
      $pip_script = "${scripts}\\pip.exe"
    } else {
      $pip_script = "${scripts}/pip"
    }

    exec { 'pip-install':
      command => "${easy_install} pip",
      creates => $pip_script,
      require => $setuptools_require,
    }
  }

  if $::osfamily == 'OpenBSD' {
    # OpenBSD needs some extra links to complete the experience, and so
    # that `pip` is in path for pip/pipx package providers.
    class { 'python::openbsd':
      ez_setup => $ez_setup,
    }
    if $ez_setup {
      Exec['pip-install'] -> Class['python::openbsd']
    } else {
      Package[$pip_package] -> Class['python::openbsd']
    }
    Class['python::openbsd'] -> Package<| provider == pip |>
    Class['python::openbsd'] -> Package<| provider == pipx |>
  }

  # Ensure this class comes before any package resources with a
  # `pip` or `pipx` provider.
  Class['python'] -> Package<| provider == pip |>
  Class['python'] -> Package<| provider == pipx |>
}
