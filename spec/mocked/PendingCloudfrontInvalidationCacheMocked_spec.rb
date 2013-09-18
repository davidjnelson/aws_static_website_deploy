require 'rspec'
require File.expand_path('../../real/PendingCloudfrontInvalidationCache_spec', __FILE__)

describe PendingCloudfrontInvalidationCache do
  Fog.mock!
end
