# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_static_website_deploy/version'

Gem::Specification.new do |gem|
  gem.name          = "aws_static_website_deploy"
  gem.version       = AwsStaticWebsiteDeploy::VERSION
  gem.authors       = ["David Nelson"]
  gem.email         = ["david.jonathan.nelson@gmail.com"]
  gem.summary     = "Deploy static websites to an s3 and route53 backed cloudfront distribution."
  gem.description = "A ruby gem for uploading changed files to s3, configuring s3 as a website, creating cloudfront distributions backed by an s3 origin, invalidating cloudfront paths after testing the website on s3, and creating a route53 configuration for the website."
  gem.homepage    = "http://github.com/davidjnelson/aws_static_website_deploy"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
