require 'aws_static_website_deploy/YamlParser'
require 'aws_static_website_deploy/S3Deploy'
require 'aws_static_website_deploy/PendingCloudfrontInvalidationCache'
require 'aws_static_website_deploy/CloudfrontDeploy'
require 'aws_static_website_deploy/Route53Deploy'

class AwsStaticWebsiteDeploy
  public
  def initialize(configFilePath)
    yamlParser = YamlParser.new(configFilePath)
    awsKey = yamlParser.getAwsKey()
    awsSecret = yamlParser.getAwsSecret()

    @url = yamlParser.getUrl()
    @invalidationCache = PendingCloudfrontInvalidationCache.new(awsKey, awsSecret)
    @cloudfrontDeploy = CloudfrontDeploy.new(awsKey, awsSecret, @url, @invalidationCache)
    @route53Deploy = Route53Deploy.new(awsKey, awsSecret, @url)
  end

  public
  def deployDirectoryToS3(directory)
    s3Deploy = S3Deploy.new(awsKey, awsSecret, @url, directory, @invalidationCache)

    if(!s3Deploy.bucketExists()) then
      s3Deploy.createBucket()
      s3Deploy.configureBucketAsWebsite()
    end

    s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()
  end

  public
  def deployBucketToCloudfront()
    if(!@route53Deploy.hostedZoneWithNameMatchingBucketNameWithoutWwwDotPrefixExists()) then
      @route53Deploy.createHostedZone()

      zoneId = @route53Deploy.getHostedZoneIdWithNameMatchingBucketNameWithoutWwwDotPrefix()

      @route53Deploy.createARecordPointingToWwwizer(zoneId)
      @route53Deploy.createCNameRecordPointingToOriginS3Bucket(zoneId)
      @cloudfrontDeploy.createCloudfrontDistributionWithS3BucketAsCNameAndS3BucketAsCustomOrigin()

      distributionId = @cloudfrontDeploy.getDistributionIdWithS3BucketAsCName()

      @cloudfrontDeploy.waitForDistributionCreationToFinish(distributionId)
    end

    @cloudfrontDeploy.invalidateListOfS3ObjectKeys(distributionId)
    distributionId = @cloudfrontDeploy.getDistributionIdWithS3BucketAsCName()

    @cloudfrontDeploy.waitForDistributionInvalidationToFinish(distributionId)
  end
end
