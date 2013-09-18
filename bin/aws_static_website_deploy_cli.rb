require './lib/aws_static_website_deploy/AwsStaticWebsiteDeploy'

awsDeploy = AwsStaticWebsiteDeploy.new('config.yml')
mode = ARGV[0]
directory = ARGV[1]

if(mode == 's3') then
  if(!File.exists?(directory)) then
    puts 'the directory: ' + directory + 'passed as the second argument does not exist'
  end

  if(!File.directory?(directory)) then
    puts 'the path: ' + directory + 'passed as second argument exists but is not a directory'
  end

  awsDeploy.deployDirectoryToS3(directory)
elsif(mode == 'cloudfront') then
  awsDeploy.deployBucketToCloudfront()
else
  puts 'Mode not recognized.  Please pass s3 or cloudfront as the first argument.'
end
