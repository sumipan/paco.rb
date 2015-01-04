require 'rake'

module Paco
module Env
  class Unity < Base
    include Rake::FileUtilsExt

    attr_reader :unity_path, :project_path, :verbose

    def initialize
      super

      @verbose = (ENV['VERBOSE']) ? "-logFile" : ""

      raise 'error. check PACO_UNITY_PATH env.' \
        if !ENV['PACO_UNITY_PATH'] || !File.exist?(ENV['PACO_UNITY_PATH'])
      raise 'error. check PACO_UNITY_PROJECT_PATH env.' \
        if !ENV['PACO_UNITY_PROJECT_PATH'] || !File.exist?(ENV['PACO_UNITY_PROJECT_PATH'])
      raise 'erorr. check PACO_TEST_UNITY_TEST_TOOLS_PATH env.' \
        if !ENV['PACO_TEST_UNITY_TEST_TOOLS_PATH'] || !File.exist?(ENV['PACO_TEST_UNITY_TEST_TOOLS_PATH'])

      @unity_path   = ENV['PACO_UNITY_PATH'].strip.sub('/$','')
      @project_path = ENV['PACO_UNITY_PROJECT_PATH']
    end

    def build(spec)
      assets = spec.files.select{|f| f.match(/^Assets\//) }
      files  = spec.files - assets

      # Assets 以下を unitypackage にビルドする
      if assets.size > 0 then
        sh sprintf("'%s/Unity.app/Contents/MacOS/Unity' -batchmode -quit #{@verbose} -projectPath '%s' -exportPackage %s %s",
          @unity_path,
          @project_path,
          spec.files.select{|f| f.match(/^Assets\//) }.join(' '),
          spec.name + '.unitypackage'
        )

        files.push spec.name + '.unitypackage'
      end

      files
    end

    def install(file)
      files = unzip(file)
      specfile = files.select{|f| f.match(/^.+\.paco$/) }.first
      resolve_dependency(specfile)

      files.each do |file|
        if file.match(/\.unitypackage$/) then
          import_package(file)
        end
      end
    end

    def test
      setup_test

      begin
        execute_unity_method('UnityTest.Batch.RunIntegrationTests')
      rescue
        # ignore exit code
      end

      begin
        execute_unity_method('UnityTest.Batch.RunUnitTests')
      rescue
        # ignore exit code
      end
    end

    def create_empty_project
      sh sprintf("'%s/Unity.app/Contents/MacOS/Unity' -batchmode -quit #{@verbose} -createProject '%s'",
        @unity_path,
        @test_path
      )
    end

    def execute_unity_method(method)
      sh sprintf("'%s/Unity.app/Contents/MacOS/Unity' -batchmode #{@verbose} -projectPath '%s' -executeMethod %s -resultsFileDirectory='%s'",
        @unity_path,
        @test_path,
        method,
        @test_path
      )
    end

    def import_package(package_path)
      sh sprintf("'%s/Unity.app/Contents/MacOS/Unity' -batchmode -quit #{@verbose} -projectPath '%s' -importPackage '%s'",
        @unity_path,
        @project_path,
        package_path
      )
    end

    def setup_test
      FileUtils.mkdir_p(@test_path) unless Dir.exist?(@test_path)

      create_empty_project

      # import UnityTestTools package
      import_package(ENV['PACO_TEST_UNITY_TEST_TOOLS_PATH'])

      # @TODO refactor later
      Rake::Task[:install].invoke
    end
  end
end
end
