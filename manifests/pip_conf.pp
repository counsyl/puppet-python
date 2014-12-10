# == Resource: python::pip_conf
#
# Template for defining a standard pip configuration for a user. This sets up
# index URLS and caching directives for downloaded packages and wheels.
#
# === Parameters
#
# [*user*]
#  The user to install the configuration file for. Defaults to the name of the
#  resource.
#
# [*conf_dir*]
#  Directory to place the pip configuration file in. Defaults to the `.pip` dir
#  in the user's home directory.
#
# [*index_url*]
#  Location of the primary PyPi index to use.
#
# [*extra_index_url*]
#  Location of an extra fallback PyPi index to use.
#
define python::pip_conf(
  $user            = $name,
  $conf_dir        = "/home/${name}/.pip",
  $index_url       = undef,
  $extra_index_url = undef,
) {
  $pip_config     = "${conf_dir}/pip.conf"
  $download_cache = "${conf_dir}/downloads"
  $wheel_cache    = "${conf_dir}/wheels"

  file { $conf_dir:
    ensure => directory,
    owner  => $user,
    mode   => '0644',
  }

  $cache_dirs = [$download_cache, $wheel_cache]
  file { $cache_dirs:
    ensure => directory,
    owner  => $user,
    mode   => '0644',
  }

  file { $pip_config:
    ensure  => file,
    owner   => $user,
    mode    => '0644',
    content => template('python/pip.conf.erb'),
    require => File[$conf_dir, $cache_dirs],
  }
}
