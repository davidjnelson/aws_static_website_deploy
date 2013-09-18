require 'rspec'
require File.expand_path('../../real/S3Deploy_spec', __FILE__)

describe S3Deploy do
    Fog.mock!
end
