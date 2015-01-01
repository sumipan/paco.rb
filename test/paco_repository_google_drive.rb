require 'minitest/autorun'
$LOAD_PATH.push('lib')

require 'paco'

describe Paco::Repository::GoogleDrive do
  it "must return google_drive repository" do
    proc {
      Paco::Repository.factory({})
    }.must_raise RuntimeError

    repository = Paco::Repository.factory({
      'type'  => Paco::Repository::Type::GOOGLE_DRIVE,
      'email' => ENV['PACO_TEST_GOOGLE_EMAIL'],
      'pem'   => ENV['PACO_TEST_GOOGLE_PEM'],
      'collection_url' => ENV['PACO_TEST_GOOGLE_COLLECTION_URL']
    })
    repository.must_be_instance_of Paco::Repository::GoogleDrive

    name = ENV['PACO_TEST_PACKAGE_NAME']
    repository.get(name, '0.1').must_equal nil
    repository.get(name, '0.1.0').must_equal sprintf('%s-0.1.0.zip', name)
    repository.get(name).must_equal sprintf('%s-0.1.0.zip',name)
  end
end
