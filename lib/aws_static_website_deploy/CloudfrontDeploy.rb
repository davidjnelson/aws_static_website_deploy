#fog's cloudfront support is broken and the offical aws sdk doesn't have any support at all
require 'right_aws'
require 'Constants'

class CloudfrontDeploy

  public
  def initialize(awsKey, awsSecret, bucketName, cloudfrontInvalidationCache)
    @bucketName = bucketName
    @cloudfront = createCloudfrontFacade(awsKey, awsSecret)
    @cloudfrontInvalidationCache = cloudfrontInvalidationCache
  end

  public
  def getBucketName()
    return @bucketName
  end

  public
  def getCloudfrontFacade()
    return @cloudfront
  end

  public
  def invalidateListOfS3ObjectKeys(distributionId)
    listOfKeysToInvalidate = @cloudfrontInvalidationCache.readInvalidationPathsCacheFileIntoArray()
    @cloudfrontInvalidationCache.deleteCacheFile()
    return @cloudfront.create_invalidation(distributionId, :path => listOfKeysToInvalidate)
  end

  public
  def getCustomOriginDnsName
    return @bucketName + Constants::US_EAST_ONE_BUCKET_SUFFIX
  end

  # override / redefine this if you want the output to go somewhere else
  public
  def reportStatus(message)
    puts message
  end

  public
  def createCloudfrontDistributionWithS3BucketAsCNameAndS3BucketAsCustomOrigin()
    config = {
        :enabled => true,
        :cnames => [@bucketName],
        :custom_origin => {
            :dns_name => getCustomOriginDnsName(),
            :origin_protocol_policy => 'match-viewer'
        }
    }

    @cloudfront.create_distribution(config)
  end

  public
  def waitForDistributionCreationToFinish(distributionId)
    waitForCloudfrontOperationToFinish(distributionId, 60, 30, 'create')
  end

  public
  def waitForDistributionInvalidationToFinish(distributionId)
    waitForCloudfrontOperationToFinish(distributionId, 60, 30, 'invalidate')
  end

  public
  def waitForDistributionCreationToFinishCustomWait(distributionId, secondsPerCompletionWait, maxCompletionWaits)
    waitForCloudfrontOperationToFinish(distributionId, secondsPerCompletionWait, maxCompletionWaits, 'create')
  end

  public
  def waitForDistributionInvalidationToFinishCustomWait(distributionId, secondsPerCompletionWait, maxCompletionWaits)
    waitForCloudfrontOperationToFinish(distributionId, secondsPerCompletionWait, maxCompletionWaits, 'invalidate')
  end

  public
  def waitForCloudfrontOperationToFinish(distributionId, secondsPerCompletionWait, maxCompletionWaits, operationName)
    maxCompletionWaits.times { |completionsWaited|
      reportStatus "Waiting for CloudFront distribution to be #{operationName}d.  This can take up to 30 minutes to complete.  Will check again in #{secondsPerCompletionWait} seconds..."

      if(completionsWaited == maxCompletionWaits) then
        return
      end

      # this is not covered by the tests, as it takes 15 minutes to run.  hmm..
      # TODO: circle back and add tests for this after I or someone else adds mocks to fog's cloudfront class
      if(@cloudfront.get_distribution(distributionId)[:status] == 'InProgress') then
        sleep secondsPerCompletionWait
      end
    }
  end

  public
  def getDistributionIdWithS3BucketAsCName()
    distributions = @cloudfront.list_distributions()

    distributions.each { |distribution|
      if (distribution[:cnames] != nil && distribution[:cnames].include?(@bucketName)) then
        # the aws rest api doesn't return an etag when listing distributions
        # you have to make a second call to get it
        return distribution[:aws_id]
      end
    }

    raise "distribution with cname #{@bucketName} not found"
  end

  public
  def getDistributionDataWithS3BucketAsCName()
    distributions = @cloudfront.list_distributions()

    distributions.each { |distribution|
      if (distribution[:cnames] != nil && distribution[:cnames].include?(@bucketName)) then
        # the aws rest api doesn't return an etag when listing distributions
        # you have to make a second call to get it
        return @cloudfront.get_distribution(distribution[:aws_id])
      end
    }

    raise "distribution with cname #{@bucketName} not found"
  end

  private
  def createCloudfrontFacade(awsKey, awsSecret)
    logger = Logger.new(STDOUT)
    logger.level = Logger::WARN

    cloudfront = RightAws::AcfInterface.new(awsKey, awsSecret, :logger => logger)

    return cloudfront
  end
end
