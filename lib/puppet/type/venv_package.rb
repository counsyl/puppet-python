require 'uri'
require 'puppet/parameter/package_options'

Puppet::Type.newtype(:venv_package) do
  desc "Installs Python packages within a virtual environment."

  # It's difficult to subclass types in Puppet -- especially one as complex
  # as `package`.  Thus, a lot of boilerplate code needs to be copied from
  # `lib/puppet/type/provider`.
  feature :installable, "The provider can install packages."
  feature :uninstallable, "The provider can uninstall packages."
  feature :upgradeable, "The provider can upgrade to the latest version of a
        package.  This feature is used by specifying `latest` as the
        desired value for the package."
  feature :versionable, "The provider is capable of interrogating the
        package database for installed version(s), and can select
        which out of a set of available versions of a package to
        install if asked."
  feature :holdable, "The provider is capable of placing packages on hold
        such that they are not automatically upgraded as a result of
        other package dependencies unless explicit action is taken by
        a user or another package. Held is considered a superset of
        installed."
  feature :install_options, "The provider accepts options to be
      passed to the installer command."

  ensurable do
    attr_accessor :latest

    newvalue(:present, :event => :package_installed) do
      provider.install
    end

    newvalue(:absent, :event => :package_removed) do
      provider.uninstall
    end

    aliasvalue(:installed, :present)

    newvalue(:latest, :required_features => :upgradeable) do
      # to compare against later.
      current = self.retrieve
      begin
        provider.update
      rescue => detail
        self.fail "Could not update: #{detail}"
      end

      if current == :absent
        :package_installed
      else
        :package_changed
        end
    end

    newvalue(/./, :required_features => :versionable) do
      begin
        provider.install
      rescue => detail
        self.fail "Could not update: #{detail}"
      end

      if self.retrieve == :absent
        :package_installed
      else
        :package_changed
      end
    end
    defaultto :installed

    # Override the parent method, because we've got all kinds of
    # funky definitions of 'in sync'.
    def insync?(is)

      @lateststamp ||= (Time.now.to_i - 1000)
      # Iterate across all of the should values, and see how they
      # turn out.

      @should.each { |should|
        case should
        when :present
          return true unless [:absent, :held].include?(is)
        when :latest
          # Short-circuit packages that are not present
          return false if is == :absent

          # Don't run 'latest' more than about every 5 minutes
          if @latest and ((Time.now.to_i - @lateststamp) / 60) < 5
            #self.debug "Skipping latest check"
          else
            begin
              @latest = provider.latest
              @lateststamp = Time.now.to_i
            rescue => detail
              error = Puppet::Error.new("Could not get latest version: #{detail}")
              error.set_backtrace(detail.backtrace)
              raise error
            end
          end

          case
          when is.is_a?(Array) && is.include?(@latest)
            return true
          when is == @latest
            return true
          when is == :present
            return true
          else
            self.debug "#{@resource.name} #{is.inspect} is installed, latest is #{@latest.inspect}"
          end


        when :absent
          return true if is == :absent
          # this handles version number matches and
          # supports providers that can have multiple versions installed
        when *Array(is)
          return true
        end
      }

      false
    end

    # Get the package's current status.
    def retrieve
      if pypkg = provider.query
        pypkg[:ensure]
      else
        :absent
      end
    end

    # Provide a bit more information when logging upgrades.
    def should_to_s(newvalue = @should)
      if @latest
        @latest.to_s
      else
        super(newvalue)
      end
    end
  end

  newparam(:name, :namevar => true) do
    desc "The name of the package to install"

    validate do |value|
      m = /^([\w\-\.\[\]]+)@(.+)$/.match(value)
      unless m
        fail Puppet::Error, "Invalid name -- must take form '<package>@<venv>'."
      end

      package, venv = m[1..-1] # m[1:] in Python

      unless Puppet::Util.absolute_path?(venv)
        fail Puppet::Error, "virtualenv path must be fully qualified, not '#{venv}'"
      end
    end
  end

  newparam(:source) do
    desc "Where to find the actual pip package.  This must be a local file
        (or on a network file system) or a URL that pip understands."
    validate do |value|
      provider.validate_source(value)
    end
  end

  newparam(:pypi) do
    desc "The URL to use for Python Packaging Index (PyPI) to query for latest packages.
       Defaults to https://pypi.python.org/pypi"
    defaultto "https://pypi.python.org/pypi"
    validate do |value|
      unless value =~ URI::regexp
        fail Puppet::Error, "Invalid PyPI URL provided."
      end
    end
  end

  newparam(:install_options, :parent => Puppet::Parameter::PackageOptions, :required_features => :install_options) do
    desc <<-EOT
        An array of additional options to pass when installing a Python
        package with pip.  For example, to use an internal PyPI url:

            venv_package { 'requests@/path/to/venv':
              ensure          => installed,
              install_options => [ { '--index-url' => 'https://pypi.mycorp.com' } ],
            }
      EOT
  end

  # Automatically require the `venv` resource that this package will be
  # installed to.
  autorequire(:venv) do
    @parameters[:name].value.split('@')[1]
  end

  ## Instance Methods

  def refresh
    # Makes it so this type is "refresh aware" and won't break chain of
    # event propagation.
  end
end
