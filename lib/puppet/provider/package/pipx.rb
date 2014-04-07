# Extended Puppet package provider for Python's `pip` package management frontend.
# <http://pip.readthedocs.org/>

require 'puppet/provider/package'
require 'xmlrpc/client'

# So we can include the common PuppetX::Counsyl::Pip module methods.
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'counsyl', 'pip.rb'))

Puppet::Type.type(:package).provide :pipx,
  :parent => ::Puppet::Provider::Package do

  include PuppetX::Counsyl::Pip

  desc "Extended pip package provider for Python packages."

  has_feature :installable, :uninstallable, :upgradeable, :versionable, :install_options

  # Parse lines of output from `pip freeze`, which are structured as
  # _package_==_version_.
  def self.parse(line)
    if line.chomp =~ /^([^=]+)==([^=]+)$/
      {:ensure => $2, :name => $1, :provider => name}
    else
      nil
    end
  end

  # Return an array of structured information about every installed package
  # that's managed by `pip` or an empty array if `pip` is not available.
  def self.instances
    packages = []
    pip_cmd = which(cmd) or return []
    execpipe "#{pip_cmd} freeze" do |process|
      process.collect do |line|
        next unless options = parse(line)
        packages << new(options)
      end
    end
    packages
  end

  def self.cmd
    case Facter.value(:osfamily)
      when "RedHat"
        "pip-python"
      else
        "pip"
    end
  end

  # Return structured information about a particular package or `nil` if
  # it is not installed or `pip` itself is not available.
  def query
    self.class.instances.each do |provider_pip|
      return provider_pip.properties if @resource[:name].downcase == provider_pip.name.downcase
    end
    return nil
  end

  # Execute a `pip` command.  If Puppet doesn't yet know how to do so,
  # try to teach it and if even that fails, raise the error.
  private
  def lazy_pip(*args)
    pip *args
  rescue NoMethodError => e
    if pathname = which(self.class.cmd)
      self.class.commands :pip => pathname
      pip *args
    else
      raise e, 'Could not locate the pip command.'
    end
  end
end
