require 'rspec'
require 'fog'
require 'S3Deploy'
require 'SpecUtilities'

describe S3Deploy do
  before(:each) do
    @specUtilities = SpecUtilities.new
    @s3Deploy = @specUtilities.getS3Deploy()
    @invalidationCache = @specUtilities.getInvalidationCache()
  end

  it 'should create an s3 bucket with a given string as the name' do
    begin
      @s3Deploy.createBucket()

      @s3Deploy.bucketExists().should == true
    ensure
      @specUtilities.deleteBucketAndAllFilesInsideIt()
      @invalidationCache.deleteCacheFile()
    end
  end

  it 'should configure an existing s3 bucket to function as a website' do
    # no mock for this.  calling unmock! doesn't turn mocks off as expected, so less elegant solution used is catching that specific exception instead.

    begin
      @s3Deploy.createBucket()

      @s3Deploy.configureBucketAsWebsite()

      websiteConfiguration = @specUtilities.getBucketWebsiteConfiguration().body

      websiteConfiguration['IndexDocument']['Suffix'].should == 'index.html'
      websiteConfiguration['ErrorDocument']['Key'].should == '404.html'
    rescue Fog::Errors::MockNotImplemented
      # ignore missing mocks.  this test will only run as a real / integration test until / if mocks get implemented.
    ensure
      if(!Fog.mocking?) then
        @specUtilities.deleteBucketAndAllFilesInsideIt()
        @invalidationCache.deleteCacheFile()
      end
    end
  end

  it 'should deploy one binary file and one text file in root directory, and one text file in subdirectory to s3, ' +
    'setting the text files to text/html and text/plain with charset utf-8 and the binary file to image/gif' do
    begin
      @s3Deploy.createBucket()
      @s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()

      listOfFilesInBucket = @specUtilities.listFilesInBucketAsHashKeyedByS3ObjectKeyWithValueOfS3Object()

      listOfFilesInBucket['directory1/file2.txt']['Content-Type'].should == 'text/plain; charset=utf-8'
      listOfFilesInBucket['file1.html']['Content-Type'].should == 'text/html; charset=utf-8'
      listOfFilesInBucket['ruby.gif']['Content-Type'].should == 'image/gif'
    ensure
      @specUtilities.deleteBucketAndAllFilesInsideIt()
      @invalidationCache.deleteCacheFile()
    end
  end

  it 'should not deploy files if their md5 hash on disk and s3 are identical' do
    begin
      @s3Deploy.createBucket()
      @s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()
      filesUploaded = @s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()

      filesUploaded.length.should == 0
    ensure
      @specUtilities.deleteBucketAndAllFilesInsideIt()
      @invalidationCache.deleteCacheFile()
    end
  end

  it 'should know if an s3 bucket exists' do
    @s3Deploy.bucketExists().should == false

    @s3Deploy.createBucket()

    @s3Deploy.bucketExists().should == true
  end

  it 'should set http headers with Content-Encoding: gzip for files with mime type beginning with: text, and not for binary files' do
    begin
      @s3Deploy.createBucket()
      @s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()

      listOfFilesInBucket = @specUtilities.listFilesInBucketAsHashKeyedByS3ObjectKeyWithValueOfS3Object()

      listOfFilesInBucket['directory1/file2.txt']['Content-Encoding'].should == 'gzip'
      listOfFilesInBucket['file1.html']['Content-Encoding'].should == 'gzip'
      listOfFilesInBucket['ruby.gif']['Content-Encoding'].should == ''
    ensure
      @specUtilities.deleteBucketAndAllFilesInsideIt()
      @invalidationCache.deleteCacheFile()
    end
  end

  it 'should gzip files with mime type beginning with: text, and not binary files' do
    begin
      @s3Deploy.createBucket()
      @s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()

      File.size(SpecUtilities::TEST_WEBSITE_DIRECTORY + '/directory1/file2.txt').should be < 200000 # uncompressed is 246KB
      File.size(SpecUtilities::TEST_WEBSITE_DIRECTORY + '/file1.html').should be < 200000 # uncompressed is 295kb
      File.size(SpecUtilities::TEST_WEBSITE_DIRECTORY + '/ruby.gif').should == 8576 # should not change
    ensure
      @specUtilities.deleteBucketAndAllFilesInsideIt()
      @invalidationCache.deleteCacheFile()
    end
  end

  it 'should set cache expiration header in s3 to 1 year for all files' do
    begin
      @s3Deploy.createBucket()
      @s3Deploy.recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()

      listOfFilesInBucket = @specUtilities.listFilesInBucketAsHashKeyedByS3ObjectKeyWithValueOfS3Object()

      # cache objects for 2 years: 60 seconds in a minute x 60 minutes in an hour x 24 hours in a day x 365 days in a year x 2 years = 63072000 seconds
      listOfFilesInBucket['directory1/file2.txt']['Cache-Control'].should == 'max-age=63072000'
      listOfFilesInBucket['file1.html']['Cache-Control'].should == 'max-age=63072000'
      listOfFilesInBucket['ruby.gif']['Cache-Control'].should == 'max-age=63072000'
    ensure
      @specUtilities.deleteBucketAndAllFilesInsideIt()
      @invalidationCache.deleteCacheFile()
    end
  end
end
