require 'google_drive'

module Paco
  module Repository
    class GoogleDrive < Base
      attr_reader :access_token, :session, :collection

      def initialize(email, pem, collection_url)
        key    = Google::APIClient::KeyUtils.load_from_pkcs12(pem, 'notasecret')
        client = Google::APIClient.new(:application_name => 'Ruby')
        client.authorization = Signet::OAuth2::Client.new(
          :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
          :audience             => 'https://accounts.google.com/o/oauth2/token',
          :scope                => 'https://www.googleapis.com/auth/drive https://spreadsheets.google.com/feeds https://docs.google.com/feeds',
          :issuer               => email,
          :signing_key          => key,
        )

        client.authorization.fetch_access_token!

        @access_token = client.authorization.access_token
        @session      = ::GoogleDrive.login_with_oauth(@access_token)
        begin
          @collection   = @session.collection_by_url(collection_url)
        rescue => e
          raise 'error. can not access collection url.'
        end
      end

      def find(name, version=nil)
        @collection.files.each do |file|
          if match = file.title.match(/^(#{name})-(\d+\.\d+\.\d+.*)\.zip$/) then
            if version then
              if version == match[2] then
                return file
              end
            else
              return file
            end
          end
        end

        nil
      end

      def get(name, version=nil)
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
