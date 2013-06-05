Puppet::Type.newtype(:venv) do
  desc "A resource type for managing a Python virtual environment."

  feature :virtualenv, "Uses `virtualenv` to manage environments."
  feature :pyvenv, "Uses `pyvenv` to manage environments (3.3+)."

  ensurable

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

  newparam(:python, :required_features => :virtualenv) do
    desc "The Python interpreter to use."
  end

  newparam(:distribute, :required_features => :virtualenv) do
    desc "Use distribute instead of setuptools."
    newvalues(:true, :false)
  end

  newparam(:setuptools, :required_features => :virtualenv) do
    desc "Use setuptools instead of distribute."
    newvalues(:true, :false)
  end

  newparam(:unzip_setuptools, :required_features => :virtualenv) do
    desc "Unzip Setuptools or Distribute when installing it."
    newvalues(:true, :false)
  end

  newparam(:symlinks, :required_features => :pyvenv) do
    desc "Try to use symlinks rather than copies when not platform default."
    newvalues(:true, :false)
  end

  newparam(:system_site_packages) do
    desc "Give access to the global site-packages dir to the venv."
    newvalues(:true, :false)
  end

  def refresh
    # Makes it so this type is "refresh aware" and won't break chain of
    # event propagation.
  end
end
