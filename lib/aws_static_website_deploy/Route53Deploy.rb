require 'fog'
require 'Constants'

class Route53Deploy
  public
  def initialize(awsKey, awsSecret, bucketName)
    @awsKey = awsKey
    @awsSecret = awsSecret
    @bucketName = bucketName
    @route53Deploy = Fog::DNS::AWS.new(
        :aws_access_key_id => awsKey,
        :aws_secret_access_key => awsSecret)
  end

  public
  def createARecordPointingToWwwizer(zoneId)
    changeBatch = [{
        :action => 'CREATE',
        :name => getBucketNameWithoutWwwWithPeriodAtEnd(),
        :type => 'A',
        # 5 minutes, the aws web console default
        :ttl => 300,
        :resource_records => [ Constants::WWWIZER_IP_ADDRESS ]
    }]

    @route53Deploy.change_resource_record_sets(zoneId, changeBatch)
  end

  public
  def createCNameRecordPointingToOriginS3Bucket(zoneId)
    changeBatch = [{
                       :action => 'CREATE',
                       :name => getBucketNameWithPeriodAtEnd(),
                       :type => 'CNAME',
                       # 5 minutes, the aws web console default
                       :ttl => 300,
                       :resource_records => [ getBucketHostNameWithPeriodAtEnd() ]
                   }]

    @route53Deploy.change_resource_record_sets(zoneId, changeBatch)
  end

  public
  def createHostedZone()
    bucketNameWithoutWwwWithPeriodAtEnd = getBucketNameWithoutWwwWithPeriodAtEnd()
    hostedZoneCreationResponse = @route53Deploy.create_hosted_zone(bucketNameWithoutWwwWithPeriodAtEnd)

    nameservers = hostedZoneCreationResponse.body['NameServers']

    if(nameservers.length > 0) then
      puts ""
      puts "These are the four fully qualified domain names you need to enter into your domain registrar's nameserver settings for your domain:"
      puts ""

      nameservers.each do |nameServerHostname|
        puts nameServerHostname
      end
    end

    return hostedZoneCreationResponse
  end

  public
  def getHostedZoneIdWithNameMatchingBucketNameWithoutWwwDotPrefix()
    hostedZone = getHostedZoneWithNameMatchingBucketNameWithoutWwwDotPrefix()
    return hostedZone['Id']
  end

  public
  def getHostedZoneNameWithNameMatchingBucketNameWithoutWwwDotPrefix()
    hostedZone = getHostedZoneWithNameMatchingBucketNameWithoutWwwDotPrefix()
    return hostedZone['Name']
  end

  public
  def getHostedZoneWithNameMatchingBucketNameWithoutWwwDotPrefix()
    @route53Deploy.list_hosted_zones().body['HostedZones'].each do |hostedZone|
      if(hostedZone['Name'] == getBucketNameWithoutWwwWithPeriodAtEnd())
        return hostedZone
      end
    end

    return nil
  end

  public
  def hostedZoneWithNameMatchingBucketNameWithoutWwwDotPrefixExists()
    return getHostedZoneWithNameMatchingBucketNameWithoutWwwDotPrefix() != nil
  end

  public
  def getRoute53Facade()
    return @route53Deploy
  end

  public
  def getBucketHostNameWithPeriodAtEnd()
    return @bucketName + Constants::US_EAST_ONE_BUCKET_SUFFIX + '.'
  end

  public
  def getBucketNameWithPeriodAtEnd()
    return @bucketName + '.'
  end

  public
  def getBucketNameWithoutWwwWithPeriodAtEnd()
    # TODO: consider use cases outside of one zone apex with one www sudomain, ie: images.domain.com
    bucketNameWithoutWww = @bucketName.gsub(/www\./, '')
    bucketNameWithoutWwwWithPeriodAtEnd = bucketNameWithoutWww + '.'

    return bucketNameWithoutWwwWithPeriodAtEnd
  end

  public
  def getBucketNameWithPeriodAtEnd()
    return @bucketName + '.'
  end
end
