require 'zip'

module Paco
module Env
  class Base
    attr_reader :project_path

    # constructor
    #
    # @raise RuntimeError
    def initialize
    end

    # install package
    #
    # @raise RuntimeError
    # @param [Paco::Specification]
    # @param [Array] パッケージに含まれるファイルのパス
    # @return [nil]
    def install(spec, files)
      raise 'error. not implemented.'
    end

    # uninstall package
    #
    # @param [Paco::Specification]
    # @return [nil]
    def uninstall(spec)
      FileUtils.remove(spec.files, {:verbose => true})
    end

    # build package
    #
    # @raise RuntimeError
    # @param [Paco::Specification]
    # @return [Array] パッケージに含めるファイルのパス
    def build(spec)
      raise 'error. not implemented.'
    end

    # test package
    #
    # @raise RuntimeError
    # @return [nil]
    def test
      raise 'error. not implemented.'
    end

    # cleanup PACO_TEST_PATH
    # @raise RuntimeError
    # @return [nil]
    def cleanup
      nil
    end

    # zip files
    # @param
    # @param
    # @return nil
    def zip(zipfile, files)
      FileUtils.remove(zipfile) if File.exist?(zipfile)

      Zip::File.open(zipfile, Zip::File::CREATE) do |zipfile|
        files.each do |filename|
          zipfile.add(filename, filename)
        end
      end

      nil
    end

    # unzip archive
    # @return [Array] files
    def unzip(file)
      spec  = nil
      file  = File.expand_path(file)
      files = []
      Zip::File.open(file) do |zipfile|
        zipfile.each do |entry|
          destfile = @project_path + '/' + entry.name

          FileUtils.remove(entry.name, {:verbose => true}) if File.exist?(entry.name)
          FileUtils.mkdir_p(File.dirname(destfile)) if !Dir.exist?(File.dirname(destfile))
          puts "Extract #{entry.name}"
          entry.extract(destfile) do |entry,destfile|
            puts sprintf("%s is already exist. overwrite? [y/N]", entry.name)
            ['y','Y'].include?($stdin.gets.chomp)
          end

          if File.extname(entry.name) == '.paco' then
            spec = eval File.read(destfile)
          end

          files.push entry.name
        end
      end

      files
    end

    def get_package_file(file, repository=nil)
      if !File.exist?(file) then
        match = file.match(/^(.+?)(?:-(\d+\.\d+\.\d+))?(?:.zip)?$/)
        if repository then
          found = repository.get(match[1], match[2])
          if found then
            file = found
          end
        end
      end

      raise 'error. not found' unless File.exist?(file)

      file
    end

    def resolve_dependency(specfile)
      spec = eval File.read(@project_path + '/' + specfile)
      spec.dependencies.each do |dependency|
        paco = "#{dependency[:name]}.paco"
        next if File.exist?(paco)

        file = get_package_file dependency[:name], Paco::Config.instance.repos
        Paco::Config.instance.env.install file
      end
    end
  end
end
end
