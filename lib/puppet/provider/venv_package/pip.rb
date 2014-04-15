require 'etc'
require 'xmlrpc/client'
require 'puppet/provider/package'

# So we can include the common PuppetX::Counsyl::Pip module methods.
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'counsyl', 'pip.rb'))

Puppet::Type.type(:venv_package).provide :pip,
  :parent => ::Puppet::Provider::Package do

  include PuppetX::Counsyl::Pip

  desc "pip provider for venv_package"

  has_feature :installable, :uninstallable, :upgradeable, :versionable, :install_options

  ## Class Methods

  def self.instances
    return []
  end

  ## Instance Methods

  # Parse lines of output from `pip freeze`, which are structured as
  # _package_==_version_.
  def parse(line, venv)
    if line.chomp =~ /^([^=]+)==([^=]+)$/
      {:ensure => $2, :name => [$1, venv].join('@'), :provider => name}
    else
      nil
    end
  end

  # Returns the path to pip command for given path to the virtualenv.
  def pip_cmd(venv)
    if Facter.value(:osfamily) == 'windows' then
      return File.join(venv, 'Scripts', 'pip.exe')
    else
      return File.join(venv, 'bin', 'pip')
    end
  end

  def query
    packages = []
    venv = @resource[:name].split('@')[1]
    pip_cmd = which(pip_cmd(venv)) or return []
    execpipe "#{pip_cmd} freeze" do |process|
      process.collect do |line|
        next unless options = parse(line, venv)
        packages << self.class.new(options)
      end
    end
    packages.each do |provider_pip|
      return provider_pip.properties if @resource[:name] == provider_pip.name
    end
    return nil
  end

  # Execute a `pip` command.  If Puppet doesn't yet know how to do so,
  # try to teach it and if even that fails, raise the error.
  private
  def lazy_pip(*args)
    begin
      package, venv = @resource[:name].split('@')
    rescue => detail
      self.fail "Could not determine package and venv: #{detail}"
    end

    if pathname = which(pip_cmd(venv))
      # Does the virtualenv have the `owner` property set?  If so,
      # we'll want to run pip in the same context as them by wrapping
      # the virtualenv pip in a `su` call.
      venv_resource = @resource.catalog.resource('Venv', venv)
      venv_owner = venv_resource.parameters[:owner]

      if venv_owner
        # Set up pip command for virtualenv, and su command.
        # TODO: Use `execute()` method instead of `su` command when
        #       installing package as different user/group.
        self.class.commands :pip => pathname, :su => 'su'

        # Depending on when this is invoked, the parent's property
        # may have already been converted to an integer -- thus,
        # convert it to a username for use with `su`.
        begin
          uid = Integer(venv_owner.value)
          owner = Etc.getpwuid(uid).name
        rescue TypeError, ArgumentError
          owner = venv_owner.value
        end
        # Call pip as the virtualenv owner.
        su *['-l', owner, '-c', ([pathname] + args).join(' ')]
      else
        # Set up pip command for virtualenv.
        self.class.commands :pip => pathname

        # Call pip normally.
        pip *args
      end
    else
      raise e, 'Could not locate the pip command.'
    end
  end
end
