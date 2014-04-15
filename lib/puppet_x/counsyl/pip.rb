module PuppetX
  module Counsyl
    module Pip
      # Ask the PyPI API for the latest version number.  There is no local
      # cache of PyPI's package list so this operation will always have to
      # ask the web service.
      def latest
        pypkg = @resource[:name].split('@')[0]
        if @resource.class.validattr?(:pypi)
          # Setting PyPI URL parameter (supported only on `venv_package`).
          pypi_url = @resource[:pypi]
        else
          # TODO: Support trying to use `--index-url` from install_options.
          pypi_url = 'https://pypi.python.org/pypi'
        end
        client = XMLRPC::Client.new2(pypi_url)
        client.http_header_extra = {'Content-Type' => 'text/xml'}
        client.timeout = 10
        self.debug "Querying latest for '#{pypkg}' from '#{pypi_url}'"
        result = client.call('package_releases', pypkg)
        result.first
      rescue Timeout::Error => detail
        raise Puppet::Error, "Timeout while contacting PyPI: #{detail}";
      end

      # Install a package.  The ensure parameter may specify installed,
      # latest, a version number, or, in conjunction with the source
      # parameter, an SCM revision.  In that case, the source parameter
      # gives the fully-qualified URL to the repository.
      def install
        # Getting the python package name, regardless of whether we
        # are in a virtualenv.
        pypkg = @resource[:name].split('@')[0]
        args = %w{install -q}

        # Adding any install options
        opts = install_options
        if opts
          args << opts
        end
        if @resource[:source]
          if String === @resource[:ensure]
            # If there's a SCM revision specified, ensure a `--upgrade`
            # is specified to ensure package is actually installed.
            self.class.instances.each do |pip_package|
              if pip_package.name == pypkg
                args << '--upgrade'
                break
              end
            end
            args << "#{@resource[:source]}@#{@resource[:ensure]}#egg=#{pypkg}"
          else
            args << "#{@resource[:source]}#egg=#{pypkg}"
          end
        else
          case @resource[:ensure]
          when String
            args << "#{pypkg}==#{@resource[:ensure]}"
          when :latest
            args << '--upgrade' << pypkg
          else
            args << pypkg
          end
        end
        lazy_pip *args
      end

      # Uninstall a package.  Uninstall won't work reliably on Debian/Ubuntu
      # unless this issue gets fixed.
      # <http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=562544>
      def uninstall
        lazy_pip 'uninstall', '-y', '-q', @resource[:name]
      end

      def update
        install
      end

      def install_options
        join_options(resource[:install_options])
      end

      def join_options(options)
        return unless options

        options.collect do |val|
          case val
          when Hash
            val.keys.sort.collect do |k|
              "#{k}=#{val[k]}"
            end.join(' ')
          else
            val
          end
        end
      end
    end
  end
end
