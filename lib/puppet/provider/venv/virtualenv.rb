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
    if @resource[:distribute]
      options << '--distribute'
    elsif @resource[:setuptools]
      options << '--setuptools'
    end

    if @resource[:unzip_setuptools]
      options << '--unzip-setuptools'
    end

    if @resource[:system_site_packages]
      options << '--system-site-packages'
    end
    puts @resource.to_s
    virtualenv *(options + [@resource[:path]])
  end

  def destroy
    FileUtils.rm_rf(@resource[:path])
  end
end
