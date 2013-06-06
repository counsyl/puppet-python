require 'xmlrpc/client'
require 'puppet/provider/package'

Puppet::Type.type(:venv_package).provide :pip,
  :parent => ::Puppet::Provider::Package do

  desc "pip provider for venv_package"

  has_feature :installable, :uninstallable, :upgradeable, :versionable

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

  def query
    packages = []
    venv = @resource[:name].split('@')[1]
    pip_cmd = which(File.join(venv, 'bin', 'pip')) or return []
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

  # Ask the PyPI API for the latest version number.  There is no local
  # cache of PyPI's package list so this operation will always have to
  # ask the web service.
  def latest
    client = XMLRPC::Client.new2("http://pypi.python.org/pypi")
    client.http_header_extra = {"Content-Type" => "text/xml"}
    client.timeout = 10
    result = client.call("package_releases", @resource[:name].split('@')[0])
    result.first
  rescue Timeout::Error => detail
    raise Puppet::Error, "Timeout while contacting pypi.python.org: #{detail}";
  end

  # Install a package.  The ensure parameter may specify installed,
  # latest, a version number, or, in conjunction with the source
  # parameter, an SCM revision.  In that case, the source parameter
  # gives the fully-qualified URL to the repository.
  def install
    pypkg = @resource[:name].split('@')[0]

    args = %w{install -q}
    if @resource[:source]
      if String === @resource[:ensure]
        args << "#{@resource[:source]}@#{@resource[:ensure]}#egg=#{pypkg}"
      else
        args << "#{@resource[:source]}#egg=#{pypkg}"
      end
    else
      case @resource[:ensure]
      when String
        args << "#{pypkg}==#{@resource[:ensure]}"
      when :latest
        args << "--upgrade" << pypkg
      else
        args << pypkg
      end
    end
    lazy_pip *args
  end

  def uninstall
    lazy_pip "uninstall", "-y", "-q", @resource[:name].split('@')[0]
  end

  def update
    install
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

    if pathname = which(File.join(venv, 'bin', 'pip'))
      self.class.commands :pip => pathname
      pip *args
    else
      raise e, 'Could not locate the pip command.'
    end
  end
end
