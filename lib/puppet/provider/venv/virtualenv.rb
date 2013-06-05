Puppet::Type.type(:venv).provide(:virtualenv) do
  desc "virtualenv provider for venv"
  has_feature :virtualenv

  commands :virtualenv => 'virtualenv'

  def exists?
    # The virtual environment should be a directory, and contain a
    # `bin` subfolder with an `activate` script.
    activate = File.join(@resource[:path], 'bin', 'activate')
    File.directory?(@resource[:path]) and File.file?(activate)
  end

  def create
    options = []

    # Set the python interpreter, if requested.
    if @resource[:python]
      options << '--python' << "#{@resource[:python]}"
    end

    # The --distrubte and --setuptools flags are mutually exclusive,
    # don't set and leave default up to
    if @resource[:distribute] == :true
      options << '--distribute'
    elsif @resource[:setuptools] == :true
      options << '--setuptools'
    end

    if @resource[:unzip_setuptools] == :true
      options << '--unzip-setuptools'
    end

    # If set, we want to include the system's site packages in environment.
    if @resource[:system_site_packages] == :true
      options << '--system-site-packages'
    end

    # Calling `virtualenv` with the proper options.
    virtualenv *(options + [@resource[:path]])

    # If `owner` or `group` parameters passed in, change the permissions
    # on the virtualenv accordingly.
    owner = @resource.value(:owner) || nil
    group = @resource.value(:group) || nil
    if owner or group
      self.debug "Updating virtualenv permissions"
      FileUtils.chown_R(owner, group, @resource.value(:path))
    end
  end

  def destroy
    FileUtils.rm_rf(@resource[:path])
  end
end
