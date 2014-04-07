require 'etc'

Puppet::Type.type(:venv).provide(:virtualenv) do
  include Puppet::Util::POSIX

  desc "virtualenv provider for venv"
  has_feature :virtualenv

  commands :virtualenv => 'virtualenv'

  def exists?
    self.debug "Checking virtualenv existence"
    # The virtual environment should be a directory, and contain files
    # for activation, pip, and python.
    if File.directory?(@resource[:path])
      if Facter.value(:osfamily) == 'windows' then
        scripts = File.join(@resource[:path], 'Scripts')
        return (File.directory?(scripts) and
                File.file?(File.join(scripts, 'activate.bat')) and
                File.file?(File.join(scripts, 'pip.exe')) and
                File.file?(File.join(scripts, 'python.exe')))
      else
        bindir = File.join(@resource[:path], 'bin')
        return (File.directory?(bindir) and
                File.file?(File.join(bindir, 'activate')) and
                File.file?(File.join(bindir, 'pip')) and
                File.file?(File.join(bindir, 'python')))
      end
    else
      return false
    end
  end

  def create
    self.debug "Creating virtualenv"

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

    # If set, we want to include the system's site packages in environment.
    if @resource[:system_site_packages]
      options << '--system-site-packages'
    end

    # Calling `virtualenv` with the proper options.
    virtualenv *(options + [@resource[:path]])

    # Update the permissions after virtualenv creation.
    owner = @resource[:owner] || nil
    group = @resource[:group] || nil
    if owner or group
      update_permissions(owner, group)
    end
  end

  def destroy
    FileUtils.rm_rf(@resource[:path])
  end

  # Updates permissions, recursively, on the virtualenv.
  def update_permissions(user, group)
    unless Puppet.features.root?
      raise Puppet::Error, "Cannot change virtualenv permissions unless root"
    end

    begin
      self.debug "Updating permissions of virtualenv to #{user}:#{group}"
      FileUtils.chown_R(user, group, @resource[:path])
    rescue => detail
      raise Puppet::Error, "Failed to update virtualenv permisions to #{user}:#{group}"
    end
  end

  ## Owner permission.

  def owner
    return :absent unless stat = venv_stat
    currentvalue = stat.uid
    currentvalue
  end

  def owner=(should)
    update_permissions(should, nil)
  end

  ## Group permission.

  def group
    return :absent unless stat = venv_stat
    currentvalue = stat.gid
    currentvalue
  end

  def group=(should)
    update_permissions(nil, should)
  end

  ## Helper methods

  # UID and GID methods from 'lib/puppet/provider/file/posix.rb'.

  def uid2name(id)
    return id.to_s if id.is_a?(Symbol) or id.is_a?(String)
    return nil if id > Puppet[:maximum_uid].to_i

    begin
      user = Etc.getpwuid(id)
    rescue TypeError, ArgumentError
      return nil
    end

    if user.uid == ""
      return nil
    else
      return user.name
    end
  end

  def name2uid(value)
    Integer(value) rescue uid(value) || false
  end

  def gid2name(id)
    return id.to_s if id.is_a?(Symbol) or id.is_a?(String)
    return nil if id > Puppet[:maximum_uid].to_i

    begin
      group = Etc.getgrgid(id)
    rescue TypeError, ArgumentError
      return nil
    end

    if group.gid == ""
      return nil
    else
      return group.name
    end
  end

  def name2gid(value)
    Integer(value) rescue gid(value) || false
  end

  # Modified from `stat` method in 'lib/puppet/type/file.rb'.
  def venv_stat
    stat = begin
      File.stat(@resource[:path])
    rescue Errno::ENOENT => error
      nil
    rescue Errno::ENOTDIR => error
      nil
    rescue Errno::EACCES => error
      warning "Could not stat; permission denied"
      nil
    end
  end
end
