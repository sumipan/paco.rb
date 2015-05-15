require 'google/api_client'
require 'google_drive'

module Paco
  module Repository
    class GoogleDrive < Base
      attr_reader :access_token, :session, :collection

      def initialize(email, pem, collection_url)
        @collection_url = collection_url
      end

      def setup
        client = Google::APIClient.new(
          :application_name => 'Paco Repository Browser',
          :application_version => VERSION
        )
        client_secrets = Google::APIClient::ClientSecrets.load

        auth               = client.authorization
        auth.client_id     = client_secrets.client_id
        auth.client_secret = client_secrets.client_secret

        @access_token = ENV['PACO_GOOGLE_ACCESS_TOKEN']
        if !@access_token then
          auth.scope         = 'https://www.googleapis.com/auth/drive https://spreadsheets.google.com/feeds https://docs.google.com/feeds'
          auth.redirect_uri  = "https://localhost/"
          print("1. Open url:\n%s\n\n" % auth.authorization_uri)
          print("2. Enter code in url: ")
          auth.code = $stdin.gets.chomp
          auth.fetch_access_token!
          @access_token = auth.access_token
          puts ""
          puts ("3. Set PACO_GOOGLE_ACCESS_TOKEN below token:")
          puts ""
          puts "export PACO_GOOGLE_ACCESS_TOKEN=#{@access_token}"
          puts ""
        end

        @session      = ::GoogleDrive.login_with_oauth(@access_token)
        begin
          @collection   = @session.collection_by_url(@collection_url)
        rescue => e
          raise 'error. can not access collection url. set valid PACO_GOOGLE_ACCESS_TOKEN'
        end
      end

      def find(name, version=nil)
        setup unless @collection

        versions = []
        @collection.files.each do |file|
          if match = file.title.match(/^(#{name})-(\d+\.\d+\.\d+.*)\.zip$/) then
            if version then
              if version == match[2] then
                return file
              end
            end

            versions.push({:file => file, :match => match})
          end
        end

        if versions.size == 0 || version != nil then
          nil
        else
          versions.sort{|a,b| b[:match][2] <=> a[:match][2] }.first[:file]
        end
      end

      def get(name, version=nil)
        setup unless @collection

        file = find(name, version)
        if file then
          file.download_to_file(file.title)
          return file.title
        end

        nil
      end
    end
  end
end
