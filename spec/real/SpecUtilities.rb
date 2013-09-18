require 'S3Deploy'
require 'PendingCloudfrontInvalidationCache'
require 'CloudfrontDeploy'
require 'Route53Deploy'
require 'Constants'

public
class SpecUtilities
  TEST_WEBSITE_DIRECTORY = '../../test-website'
  TEST_DATA_DIRECTORY = '../../test-data'

  public
  def initialize()
    random32Letters = ('a'..'z').to_a.shuffle[0,32].join
    @bucketName = 'www.test-bucket-' + random32Letters + '.com'
    # add real credentials here to make integration tests (spec/real) )work.
    @awsKey =
    @awsSecret =
    @invalidationCache = PendingCloudfrontInvalidationCache.new(@awsKey, @awsSecret)
    @s3Deploy = S3Deploy.new(@awsKey, @awsSecret, @bucketName, TEST_WEBSITE_DIRECTORY, @invalidationCache)
    @cloudfrontDeploy = CloudfrontDeploy.new(@awsKey, @awsSecret, @bucketName, @invalidationCache)
    @route53Deploy = Route53Deploy.new(@awsKey, @awsSecret, @bucketName)
  end

  public
  def getS3Deploy()
    return @s3Deploy
  end

  public
  def getInvalidationCache()
    return @invalidationCache
  end

  public
  def getCloudfrontDeploy()
    return @cloudfrontDeploy
  end

  public
  def getRoute53Deploy()
    return @route53Deploy
  end

  public
  def getBucketName()
    return @bucketName
  end

  public
  def deleteWwwizerARecord(zoneId)
    changeBatch = [{
        :action => "DELETE",
        :name => @route53Deploy.getBucketNameWithoutWwwWithPeriodAtEnd(),
        :type => 'A',
        # 5 minutes, the aws web console default
        :ttl => 300,
        :resource_records => [ Constants::WWWIZER_IP_ADDRESS ]
    }]

    @route53Deploy.getRoute53Facade().change_resource_record_sets(zoneId, changeBatch)
  end

  public
  def deleteCNameRecordPointingToOriginS3Bucket(zoneId)
    changeBatch = [{
                       :action => "DELETE",
                       :name => @route53Deploy.getBucketNameWithPeriodAtEnd(),
                       :type => 'CNAME',
                       # 5 minutes, the aws web console default
                       :ttl => 300,
                       :resource_records => [ @route53Deploy.getBucketHostNameWithPeriodAtEnd() ]
                   }]

    @route53Deploy.getRoute53Facade().change_resource_record_sets(zoneId, changeBatch)
  end

  public
  def getResourceRecordSetForHostedZoneWithNameAsBucketNameWithoutWwwWithPeriodAtEnd()
    hostedZone = @route53Deploy.getHostedZoneWithNameMatchingBucketNameWithoutWwwDotPrefix()
    zoneId = hostedZone['Id']

    @route53Deploy.getRoute53Facade().list_resource_record_sets(zoneId).body['ResourceRecordSets'].each do |resourceRecordSet|
      if(resourceRecordSet['Name'] == @route53Deploy.getBucketNameWithoutWwwWithPeriodAtEnd()) then
        return resourceRecordSet
      end
    end

    raise 'could not find resource record set'
  end

  public
  def getResourceRecordSetForHostedZoneWithNameAsBucketNameWithWwwWithPeriodAtEnd()
    hostedZone = @route53Deploy.getHostedZoneWithNameMatchingBucketNameWithoutWwwDotPrefix()
    zoneId = hostedZone['Id']

    @route53Deploy.getRoute53Facade().list_resource_record_sets(zoneId).body['ResourceRecordSets'].each do |resourceRecordSet|
      if(resourceRecordSet['Name'] == @route53Deploy.getBucketNameWithPeriodAtEnd()) then
        return resourceRecordSet
      end
    end

    raise 'could not find resource record set'
  end

  public
  def deleteHostedZone(zoneId)
    @route53Deploy.getRoute53Facade().delete_hosted_zone(zoneId)
  end

  public
  def getBucketWebsiteConfiguration()
    s3 = @s3Deploy.getS3Facade()
    return s3.get_bucket_website(@bucketName)
  end

  public
  def deleteBucketAndAllFilesInsideIt()
    s3 = @s3Deploy.getS3Facade()
    bucketName = @s3Deploy.getBucketName()
    bucketFilesArray = @s3Deploy.listFilesInBucketAsHashKeyedByS3ObjectKeyAndEtagAsValue()

    bucketFilesArray.each do |key, value|
      s3.delete_object(bucketName, key)
    end

    s3.delete_bucket(bucketName)
  end

  public
  def listFilesInBucketAsHashKeyedByS3ObjectKeyWithValueOfS3Object()
    s3 = @s3Deploy.getS3Facade()
    s3ObjectHash = {}
    # aws rest api only exposes the content type via a head request on each file.  don't use this with large lists,
    # and/or without being mocked
    # head_object is faster, not having to access the object itself, but does not expose the Content-Encoding header
    s3BucketResponse = s3.get_bucket(@bucketName)
    s3BucketResponse.body['Contents'].each do |s3ObjectLimitedData|
      s3Key = s3ObjectLimitedData['Key']

      s3Object = s3.get_object(@bucketName, s3Key).headers

      s3ObjectHash[s3Key] = s3Object
    end

    return s3ObjectHash
  end

  public
  def disableCloudfrontDistributionWithS3BucketAsCName()
    cloudfront = @cloudfrontDeploy.getCloudfrontFacade()
    distribution = @cloudfrontDeploy.getDistributionDataWithS3BucketAsCName()
    distribution[:enabled] = false

    cloudfront.set_distribution_config(distribution[:aws_id], distribution)
    # the distribution can't be deleted until the disable completes, which takes around 15 minutes.  so skip that part.
    # there will be disabled cloudfront distributions in aws as a result.
  end

  public
  def getInvalidation(distributionId, invalidationId)
    cloudfront = @cloudfrontDeploy.getCloudfrontFacade()

    return cloudfront.get_invalidation(distributionId, invalidationId)
  end

  public
  def writeArrayToCloudfrontInvalidationCacheFile(listOfKeysToInvalidate)
    File.open(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH, 'w') do |cacheFile|
      listOfKeysToInvalidate.each do |key|
        cacheFile.puts(key)
      end
    end
  end
end
