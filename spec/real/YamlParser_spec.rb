require "rspec"
require 'YamlParser'
require 'SpecUtilities'

describe "YAMLParser" do
  before(:each) do

  end

  it "should load a url from a yaml file" do
    @yamlParser = YamlParser.new(SpecUtilities::TEST_DATA_DIRECTORY + '/config.yml')
    url = @yamlParser.getUrl()

    url.should == 'www.url.com'
  end

  it 'should throw an exception if the url does not begin with http://www' do
    @yamlParser = YamlParser.new(SpecUtilities::TEST_DATA_DIRECTORY + '/config_without_www_in_url.yml')
    expect { @yamlParser.getUrl() }.to raise_error
  end

  it 'should load the aws key from a yaml file' do
    @yamlParser = YamlParser.new(SpecUtilities::TEST_DATA_DIRECTORY + '/config.yml')
    awsKey = @yamlParser.getAwsKey()

    awsKey.should == 'aws_key_value'
  end

  it 'should load the aws secret from a yaml file' do
    @yamlParser = YamlParser.new(SpecUtilities::TEST_DATA_DIRECTORY + '/config.yml')
    url = @yamlParser.getAwsSecret()

    url.should == 'aws_secret_value'
  end
end
