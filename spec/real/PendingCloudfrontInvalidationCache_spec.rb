require 'rspec'
require 'fog'
require File.expand_path('../../../lib/PendingCloudfrontInvalidationCache', __FILE__)
require File.expand_path('../../../lib/Constants', __FILE__)
require File.expand_path('../../../lib/SpecUtilities', __FILE__)

describe PendingCloudfrontInvalidationCache do
  before(:each) do
    @specUtilities = SpecUtilities.new()
    @s3Deploy = @specUtilities.getS3Deploy()
    @invalidationCache = @specUtilities.getInvalidationCache()
  end

  it 'should delete the invalidation cache file when asked' do
    File.open(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH, 'w') do |file|
    end

    @invalidationCache.deleteCacheFile()

    File.exists?(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH).should == false
  end

  it 'should write the recursive list of files in a directory when uploaded to an s3 bucket where a file with that md5 does not exist' do
    begin
      @invalidationCache.deleteCacheFile()
      @s3Deploy.createBucket()
      listOfS3Keys = @s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()

      s3KeysInCacheFile = IO.read(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH).split("\n")

      listOfS3Keys.sort.should == s3KeysInCacheFile.sort
    ensure
      @specUtilities.deleteBucketAndAllFilesInsideIt()
      @invalidationCache.deleteCacheFile()
    end
  end

  it 'should not write to the cache file if the s3 keys already exist there' do
    begin
      @invalidationCache.deleteCacheFile()
      @s3Deploy.createBucket()
      @s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()
      @s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()

      s3KeysInCacheFile = IO.read(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH).split("\n")

      s3KeysInCacheFile.length.should == 3
    ensure
      @specUtilities.deleteBucketAndAllFilesInsideIt()
      @invalidationCache.deleteCacheFile()
    end
  end

  it 'should add only one new (local but not in s3 with same md5 hash) file if only one new file is present' do
    begin
      @invalidationCache.deleteCacheFile()
      @s3Deploy.createBucket()
      @s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()

      File.open(SpecUtilities::TEST_WEBSITE_DIRECTORY + '/newFile.txt', 'w') do |file|
        file.write('new file')
      end

      @s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()

      s3KeysInCacheFile = IO.read(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH).split("\n")

      s3KeysInCacheFile.length.should == 4
    ensure
      @specUtilities.deleteBucketAndAllFilesInsideIt()
      File.delete(SpecUtilities::TEST_WEBSITE_DIRECTORY + '/newFile.txt')
      @invalidationCache.deleteCacheFile()
    end
  end
end
