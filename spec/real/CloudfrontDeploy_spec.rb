require 'rspec'
require File.expand_path('../../lib/PendingCloudfrontInvalidationCache', __FILE__)
require File.expand_path('../../lib/CloudfrontDeploy', __FILE__)
require File.expand_path('../../lib/S3Deploy', __FILE__)
require File.expand_path('../../lib/Constants', __FILE__)
require File.expand_path('../../lib/SpecUtilities', __FILE__)

describe "CloudfrontDeploy" do
  before(:each) do
    # bummer, no mocks implemented for cloudfront
    # consider implementing them and updating this to use them once they are in the official gem
    @specUtilities = SpecUtilities.new()
    @cloudfrontDeploy = @specUtilities.getCloudfrontDeploy()
  end

  it "creates a cloudfront distribution with the s3 bucket as a cname and the s3 bucket as a custom origin" do
    begin
      @cloudfrontDeploy.createCloudfrontDistributionWithS3BucketAsCNameAndS3BucketAsCustomOrigin()

      distribution = @cloudfrontDeploy.getDistributionDataWithS3BucketAsCName()

      distribution[:custom_origin][:dns_name].should == @cloudfrontDeploy.getCustomOriginDnsName()
    ensure
      @specUtilities.disableCloudfrontDistributionWithS3BucketAsCName()
    end
  end

  it 'invalidates a list of s3 object keys in a cloudfront distribution' do
    begin
      listOfKeysToInvalidate = ['/key1.txt', '/directory/key2.txt']

      @cloudfrontDeploy.createCloudfrontDistributionWithS3BucketAsCNameAndS3BucketAsCustomOrigin()
      distributionId = @cloudfrontDeploy.getDistributionIdWithS3BucketAsCName()

      @specUtilities.writeArrayToCloudfrontInvalidationCacheFile(listOfKeysToInvalidate)

      createInvalidationResponse = @cloudfrontDeploy.invalidateListOfS3ObjectKeys(distributionId)

      invalidationId = createInvalidationResponse[:aws_id]

      invalidationHash = @specUtilities.getInvalidation(distributionId, invalidationId)
      invalidationBatchHash = invalidationHash[:invalidation_batch][:path]

      invalidationBatchHash.sort.should == listOfKeysToInvalidate.sort

      File.exists?(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH).should == false
    ensure
      @specUtilities.disableCloudfrontDistributionWithS3BucketAsCName()
    end
  end

  it 'should output to the console while waiting for the cloudfront distribution to be created' do
    begin
      waitSeconds = 0.001

      @cloudfrontDeploy.createCloudfrontDistributionWithS3BucketAsCNameAndS3BucketAsCustomOrigin()

      distributionId = @cloudfrontDeploy.getDistributionIdWithS3BucketAsCName

      @cloudfrontDeploy.should_receive(:puts).with("Waiting for CloudFront distribution to be created.  This can take up to 30 minutes to complete.  Will check again in #{waitSeconds} seconds...")
      @cloudfrontDeploy.should_receive(:puts).with("Waiting for CloudFront distribution to be created.  This can take up to 30 minutes to complete.  Will check again in #{waitSeconds} seconds...")

      @cloudfrontDeploy.waitForDistributionCreationToFinishCustomWait(distributionId, waitSeconds, 2)
    ensure
      @specUtilities.disableCloudfrontDistributionWithS3BucketAsCName()
    end
  end

  it 'should output to the console while waiting for the cloudfront distribution to be invalidated' do
    begin
      waitSeconds = 0.001
      listOfKeysToInvalidate = ['/key1.txt', '/directory/key2.txt']

      @cloudfrontDeploy.createCloudfrontDistributionWithS3BucketAsCNameAndS3BucketAsCustomOrigin()

      distributionId = @cloudfrontDeploy.getDistributionIdWithS3BucketAsCName()

      @specUtilities.writeArrayToCloudfrontInvalidationCacheFile(listOfKeysToInvalidate)

      @cloudfrontDeploy.invalidateListOfS3ObjectKeys(distributionId)

      @cloudfrontDeploy.should_receive(:puts).with("Waiting for CloudFront distribution to be invalidated.  This can take up to 30 minutes to complete.  Will check again in #{waitSeconds} seconds...")
      @cloudfrontDeploy.should_receive(:puts).with("Waiting for CloudFront distribution to be invalidated.  This can take up to 30 minutes to complete.  Will check again in #{waitSeconds} seconds...")

      @cloudfrontDeploy.waitForDistributionInvalidationToFinishCustomWait(distributionId, waitSeconds, 2)
    ensure
      @specUtilities.disableCloudfrontDistributionWithS3BucketAsCName()
    end
  end
end
