require 'rspec'
require 'Route53Deploy'
require 'Constants'
require 'SpecUtilities'

describe 'Route53Deploy' do
  before(:each) do
    # no mocks available for deleting hosted zones.
    # TODO: consider implementing the mocks and changing this to a mocked spec
    @specUtilities = SpecUtilities.new()
    @route53Deploy = @specUtilities.getRoute53Deploy()
  end

  # this test would be better split into two.  do that when/if mocked.
  it 'should should create a hosted zone with a domain which is the same as the s3 bucket but without the www hostname and print out one instructions line and four nameservers lines' do
    begin
      @route53Deploy.should_receive(:puts).exactly(7).times

      @route53Deploy.createHostedZone()

      zoneId = @route53Deploy.getHostedZoneIdWithNameMatchingBucketNameWithoutWwwDotPrefix()

      hostedZoneName = @route53Deploy.getHostedZoneNameWithNameMatchingBucketNameWithoutWwwDotPrefix()

      bucketName = @specUtilities.getBucketName()
      bucketNameWithoutWww = bucketName.gsub(/www\./, '')
      bucketNameWithoutWwwWithPeriodAtEnd = bucketNameWithoutWww + '.'

      hostedZoneName.should == bucketNameWithoutWwwWithPeriodAtEnd
    ensure
      @specUtilities.deleteHostedZone(zoneId)
    end
  end

  it 'should add an A record pointing to wwwizer' do
    begin
      @route53Deploy.should_receive(:puts).exactly(7).times

      @route53Deploy.createHostedZone()

      zoneId = @route53Deploy.getHostedZoneIdWithNameMatchingBucketNameWithoutWwwDotPrefix()

      @route53Deploy.createARecordPointingToWwwizer(zoneId)

      resourceRecordSet = @specUtilities.getResourceRecordSetForHostedZoneWithNameAsBucketNameWithoutWwwWithPeriodAtEnd()

      resourceRecordSet['ResourceRecords'][0].should == Constants::WWWIZER_IP_ADDRESS
    ensure
      @specUtilities.deleteWwwizerARecord(zoneId)
      @specUtilities.deleteHostedZone(zoneId)
    end
  end

  it 'should add an CNAME record pointing to the origin s3 bucket ' do
    begin
      @route53Deploy.should_receive(:puts).exactly(7).times

      @route53Deploy.createHostedZone().body

      zoneId = @route53Deploy.getHostedZoneIdWithNameMatchingBucketNameWithoutWwwDotPrefix()

      @route53Deploy.createCNameRecordPointingToOriginS3Bucket(zoneId)

      resourceRecordSet = @specUtilities.getResourceRecordSetForHostedZoneWithNameAsBucketNameWithWwwWithPeriodAtEnd()

      resourceRecordSet['ResourceRecords'][0].should == @route53Deploy.getBucketHostNameWithPeriodAtEnd()
    ensure
      @specUtilities.deleteCNameRecordPointingToOriginS3Bucket(zoneId)
      @specUtilities.deleteHostedZone(zoneId)
    end
  end

  it 'should know if a hosted zone exists with a name matching the bucket name without the www. prefix' do
    begin
      @route53Deploy.should_receive(:puts).exactly(7).times

      @route53Deploy.hostedZoneWithNameMatchingBucketNameWithoutWwwDotPrefixExists().should == false

      @route53Deploy.createHostedZone()

      zoneId = @route53Deploy.getHostedZoneIdWithNameMatchingBucketNameWithoutWwwDotPrefix()

      @route53Deploy.hostedZoneWithNameMatchingBucketNameWithoutWwwDotPrefixExists().should == true
    ensure
      @specUtilities.deleteHostedZone(zoneId)
    end
  end
end
