require 'fog'
require 'digest/md5'
require 'PendingCloudfrontInvalidationCache'

public
class S3Deploy
  public
  def initialize(awsKey, awsSecret, bucketName, websiteRootDirectory, invalidationCache)
    @awsKey = awsKey
    @awsSecret = awsSecret
    @bucketName = bucketName
    @websiteRootDirectory = websiteRootDirectory
    @s3 = Fog::Storage.new({
                                  :provider => 'AWS',
                                  :aws_access_key_id => @awsKey,
                                  :aws_secret_access_key => @awsSecret,
                                  :region => 'us-east-1'
                              })
    @invalidationCache = invalidationCache
  end

  public
  def createBucket()
    return @s3.put_bucket(@bucketName,
                          'x-amz-acl' => 'public-read')
  end

  public
  def bucketExists()
    begin
      getBucketResponse = @s3.get_bucket(@bucketName)
    rescue Excon::Errors::NotFound
      return false
    end

    return true
  end

  public
  def configureBucketAsWebsite()
    @s3.put_bucket_website(@bucketName, "index.html", :key => "404.html")
  end

  public
  def recursivelyDeployModifiedFilesInDirectoryToBucketAndReturnDeployedFilesList()
    filesUploaded = []
    s3ObjectKeyAsKeyEtagAsValueHash = listFilesInBucketAsHashKeyedByS3ObjectKeyAndEtagAsValue()

    Dir.glob("#{@websiteRootDirectory}/**/*").each do |filePath|
      # don't upload directories
      if(File.file?(filePath)) then
        fileS3Key = filePath.gsub("#{@websiteRootDirectory}/", "")
        localFileMd5Hash = getMd5HashForFilePath(filePath)
        remoteFileMd5Hash = s3ObjectKeyAsKeyEtagAsValueHash[fileS3Key]

        if(remoteFileMd5Hash == nil || localFileMd5Hash != remoteFileMd5Hash) then
          contentTypeHeader = getContentTypeHeaderForFile(filePath)
          contentEncodingHeader = ''

          if(isTextFile(filePath)) then
            contentEncodingHeader = 'gzip'
            gzipFile(filePath)
          end

          File.open(filePath, 'r') do |fileStream|
            s3Object = @s3.put_object(@bucketName, fileS3Key, fileStream, 'Content-Type' => contentTypeHeader,
                                                                          'Content-Encoding' => contentEncodingHeader,
                                                                          'Cache-Control' => 'max-age=63072000')
          end

          filesUploaded.push(fileS3Key)
        end
      end
    end

    @invalidationCache.appendPathsIfNotAlreadyInFile(filesUploaded)

    return filesUploaded
  end

  public
  def listFilesInBucketAsHashKeyedByS3ObjectKeyAndEtagAsValue()
    s3ObjectKeyAsKeyEtagAsValueHash = {}

    @s3.get_bucket(@bucketName).body['Contents'].each do |s3Object|
      s3ObjectKey = s3Object['Key']
      s3ObjectMd5 = s3Object['ETag']

      s3ObjectKeyAsKeyEtagAsValueHash[s3ObjectKey] = s3ObjectMd5
    end

    return s3ObjectKeyAsKeyEtagAsValueHash
  end

  public
  def getBucketName()
    return @bucketName
  end

  #public so SpecUtilities can use it
  public
  def getS3Facade()
    return @s3
  end

  private
  def gzipFile(filePath)
    Zlib::GzipWriter.open(filePath) do |gz|
      gz.mtime = File.mtime(filePath)
      gz.orig_name = filePath
      gz.write IO.binread(filePath)
    end
  end

  private
  def getMd5HashForFilePath(filePath)
    fileContents = File.read(filePath)
    md5Hash = Digest::MD5.hexdigest(fileContents)

    return md5Hash
  end

  private
  def isTextFile(file)
    contentTypeHeader = MIME::Types.type_for(file).first.to_s

    if(contentTypeHeader.match(/^text/)) then
      return true
    end

    return false
  end

  private
  def getContentTypeHeaderForFile(file)
    contentTypeHeader = MIME::Types.type_for(file).first.to_s

    #set utf-8 charset for text only
    if(isTextFile(file)) then
      contentTypeHeader += '; charset=utf-8'
    end

    return contentTypeHeader
  end
end
