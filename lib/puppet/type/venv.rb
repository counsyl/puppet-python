Puppet::Type.newtype(:venv) do
  include Puppet::Util::Warnings

  desc "A resource type for managing a Python virtual environment."

  feature :virtualenv, "Uses `virtualenv` to manage environments."
  feature :pyvenv, "Uses `pyvenv` to manage environments (3.3+)."

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:path, :namevar => true) do
    desc "The path to the virtualenv to manage, must be fully qualified."

    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        fail Puppet::Error, "virtualenv path must be fully qualified, not '#{value}'"
      end
    end

    munge do |value|
      ::File.expand_path(value)
    end
  end

  ## Properties

  # Taken from 'lib/puppet/type/file/owner.rb'
  newproperty(:owner) do
    desc "The owner of the virtual environment."

    validate do |owner|
      if owner and owner != ""
        if Facter.value(:osfamily) == 'windows'
          raise(Puppet::Error, 'Cannot set venv owner on Windows')
        end
      end
    end

    def insync?(current)
      @should.map! do |val|
        provider.name2uid(val) or raise "Could not find user #{val}"
      end

      return true if @should.include?(current)

      unless Puppet.features.root?
        warnonce "Cannot manage ownership unless running as root"
        return true
      end

      false
    end

    # We want to print names, not numbers
    def is_to_s(currentvalue)
      provider.uid2name(currentvalue) || currentvalue
    end

    def should_to_s(newvalue)
      provider.uid2name(newvalue) || newvalue
    end
  end

  # Taken from 'lib/puppet/type/file/group.rb'
  newproperty(:group) do
    desc "The group of the virtual environment."

    validate do |group|
      if group and group != ""
        if Facter.value(:osfamily) == 'windows'
          raise(Puppet::Error, 'Cannot set group on Windows')
        end
      else
        raise(Puppet::Error, "Invalid group name '#{group.inspect}'")
      end
    end

    def insync?(current)
      @should.map! do |val|
        provider.name2gid(val) or raise "Could not find group #{val}"
      end

      @should.include?(current)
    end

    # We want to print names, not numbers
    def is_to_s(currentvalue)
      provider.gid2name(currentvalue) || currentvalue
    end

    def should_to_s(newvalue)
      provider.gid2name(newvalue) || newvalue
    end
  end

  ## Parameters

  newparam(:python, :required_features => :virtualenv) do
    desc "The Python interpreter to use."
  end

  newparam(:distribute, :boolean => true,
           :required_features => :virtualenv) do
    desc "Use distribute instead of setuptools."
  end

  newparam(:setuptools, :boolean => true,
           :required_features => :virtualenv) do
    desc "Use setuptools instead of distribute."
  end

  newparam(:unzip_setuptools, :boolean => true,
           :required_features => :virtualenv) do
    desc "Unzip Setuptools or Distribute when installing it."
  end

  newparam(:symlinks, :boolean => true,
           :required_features => :pyvenv) do
    desc "Try to use symlinks rather than copies when not platform default."
  end

  newparam(:system_site_packages, :boolean => false) do
    desc "Give access to the global site-packages dir to the venv."
  end

  ## Autorequires

  # Need to have access to virtualenv.
  autorequire(:class) do
    'python::virtualenv'
  end

  # Automatically require the group and owner if they are set.
  autorequire(:group) do
    self[:group] if self[:group]
  end

  autorequire(:user) do
    self[:owner] if self[:owner]
  end

  ## Methods

  def refresh
    # Makes it so this type is "refresh aware" and won't break chain of
    # event propagation.
  end
end
