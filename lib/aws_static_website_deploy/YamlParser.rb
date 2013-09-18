require 'uri'

class YamlParser
  public
  def initialize(configFilePath)
    File.open(configFilePath) do |configFile|
      @config = YAML::load(configFile)
    end
  end

  public
  def getUrl()
    url = @config['url']

    uri = URI.parse(url)
    host = uri.host

    if !host.match(/^www\./)
      raise 'url in _config.yml must start with www.'
    end

    return host
  end

  public
  def getAwsKey()
    return @config['aws_key']
  end

  public
  def getAwsSecret()
    return @config['aws_secret']
  end
end