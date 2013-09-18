#require File.expand_path('Constants', __FILE__)

public
class PendingCloudfrontInvalidationCache
  public
  def initialize(awsKey, awsSecret)
    @awsKey = awsKey
    @awsSecret = awsSecret
  end

  public
  def appendPathsIfNotAlreadyInFile(pathsToInvalidate)
    if(File.exists?(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH))
      previousPathsToInvalidate = readInvalidationPathsCacheFileIntoSet()

      appendArrayElementsToFileIfNotAlreadyPresent(previousPathsToInvalidate, pathsToInvalidate)
    else
      writeArrayElementsIntoNewInvalidationPathsCacheFile(pathsToInvalidate)
    end
  end

  public
  def deleteCacheFile()
    if(File.exists?(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH)) then
      File.delete(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH)
    end
  end

  public
  def readInvalidationPathsCacheFileIntoArray()
    return IO.read(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH).split("\n")
  end

  private
  def readInvalidationPathsCacheFileIntoSet()
    return readInvalidationPathsCacheFileIntoArray().to_s()
  end

  private
  def appendArrayElementsToFileIfNotAlreadyPresent(existingElementsSet, newElementsArray)
    File.open(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH, 'a') do |file|
      newElementsArray.each do |path|
        if(!existingElementsSet.include? path)
          file.puts path
        end
      end
    end
  end

  private
  def writeArrayElementsIntoNewInvalidationPathsCacheFile(pathsToInvalidate)
    File.open(Constants::CLOUDFRONT_INVALIDATION_CACHE_FILE_PATH, 'w') do |file|
      pathsToInvalidate.each do |path|
        file.puts path
      end
    end
  end
end
