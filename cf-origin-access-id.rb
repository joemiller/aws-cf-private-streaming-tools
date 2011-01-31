#!/usr/bin/ruby
#
# == Synopsis
#
# cf-origin-access-id:
#    List, create, delete CloudFront Origin Access Identities (OAI's), as well
#    as grant permissions on S3 objects to CloudFront OAI's.
#
# == Usage
#
# cf-origin-access-id.rb [OPTIONS] [command] [args]
#
# == commands:
#  list:
#       List Origin Access Identities
#
#  create [comment]
#       Create a new Origin Access Identity.  The AWS_ID and S3 Canonical ID
#       will be returned if successful
#
#  get [aws_id]
#       Get details about an Origin Access Identity specified by [aws_id].  This
#       command will display e_tag which is needed to delete an OAI
#
#  delete [aws_id] [e_tag]
#       Delete the Origin Access Identity specified by [aws_id] and [e_tag]. Use
#       'get' to retrieve the current e_tag.
#
#  grant [aws_id] [bucket]
#       grant 'FULL_PERMISSION' access on +all+ objects inside the S3 bucket specified
#       by [bucket] to the OAI specified by [aws_id].  There is little reason to
#       create an OAI other than to give it permissions to some objects within S3,
#       and this command helps simplify that for you.
#
# == OPTIONS:
#  -h, --help
#    show help
#
#  -k, --key [AWS_ACCESS_KEY_ID]
#    Amazon AWS ACCESS KEY ID (can also be set in environment variable 'AWS_ACCESS_KEY_ID')
#
#  -s, --seckey [AWS_SECRET_ACCESS_KEY]
#    Amazon AWS SECRET ACCESS KEY (can also be set in environment variable 'AWS_SECRET_ACCESS_KEY')

# joe miller, <joeym@joeym.net>, 10/30/2010

require 'rubygems'
require 'right_aws'
require 'getoptlong'
require 'rdoc/usage'

opts = GetoptLong.new(
    [ '--help',    '-h', GetoptLong::NO_ARGUMENT ],
    [ '--key',     '-k', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--seckey',  '-s', GetoptLong::REQUIRED_ARGUMENT ]
)

key = ENV['AWS_ACCESS_KEY_ID']
seckey = ENV['AWS_SECRET_ACCESS_KEY']

opts.each do |opt, arg|
    case opt
        when '--help'
            RDoc::usage
        when '--list'
            do_list = true
        when '--key'
            key = arg
        when '--seckey'
            seckey = arg
    end
end

if ARGV.length < 1
    puts "no command given (try --help)"
    exit 1
end

command = ARGV.shift
args    = ARGV

log = Logger.new(STDERR)
log.level = Logger::FATAL

### connect to amazon cloudfront
cf = RightAws::AcfInterface.new(key, seckey, {:logger => log} )

if command == 'list'
    oais = cf.list_origin_access_identities

    oais.each do |oai|
        puts
        puts "AWS_ID           :  #{oai[:aws_id]}"
        puts "  S3 Canonical ID:  #{oai[:s3_canonical_user_id]}"
        puts "  Comment        :  #{oai[:comment]}"
    end
elsif command == 'create'
    if args.length < 1
        puts "'create' requires 1 arg (try --help)"
        exit 1
    end

    comment = args.shift

    begin
        result = cf.create_origin_access_identity(comment)
    rescue RightAws::AwsError => e
        e.errors.each do |code, msg|
            puts "Error (#{code}): #{msg}"
        end
        exit 1
    end

    puts "Success!"
    puts "AWS_ID           : #{result[:aws_id]}"
    puts "  Location       : #{result[:location]}" 
    puts "  S3 Canonical ID: #{result[:s3_canonical_user_id]}"

elsif command == 'get'
    if args.length < 1
        puts "'get' requires 1 arg (try --help)"
        exit 1
    end

    aws_id = args.shift

    begin
        result = cf.get_origin_access_identity(aws_id)
    rescue RightAws::AwsError => e
        e.errors.each do |code, msg|
            puts "Error (#{code}): #{msg}"
        end
        exit 1
    end

    puts "AWS_ID           : #{result[:aws_id]}"
    puts "  E_TAG          : #{result[:e_tag]}"
    puts "  Caller ref     : #{result[:caller_reference]}"
    puts "  Comment        : #{result[:comment]}"
    puts "  S3 Canonical ID: #{result[:s3_canonical_user_id]}"

elsif command == 'delete'
    if args.length < 2
        puts "'delete' requires 2 args (try --help)"
        exit 1
    end

    aws_id = args.shift
    etag   = args.shift

    begin
        result = cf.delete_origin_access_identity(aws_id, etag)
    rescue RightAws::AwsError => e
        e.errors.each do |code, msg|
            puts "Error (#{code}): #{msg}"
        end
        exit 1
    end

    if result == true
        puts "Delete successful"
    else
        puts "Delete failed"
    end

elsif command == 'grant'
    if args.length < 2
        puts "'grant' requires 2 args (try --help)"
        exit 1
    end

    aws_id = args.shift
    bucket = args.shift

    begin
        s3       = RightAws::S3.new(key, seckey, {:logger => log})
        s3bucket = s3.bucket(bucket)

        s3canonical_id = cf.get_origin_access_identity(aws_id)[:s3_canonical_user_id]

        count = 0
        s3bucket.keys.each do |key|
            count += 1
            puts "#{count}: Applying grant [#{aws_id}:'FULL_CONTROL'] on: s3://#{key.full_name}"

            grantee = RightAws::S3::Grantee.new(key, s3canonical_id)
            grantee.grant('FULL_CONTROL')
        end

    rescue RightAws::AwsError => e
        e.errors.each do |code, msg|
            puts "Error (#{code}): #{msg}"
        end
        exit 1
    end

else
    puts "no command given (try --help)"
    exit 1
end

module Grants
    def test
        puts 'test'
    end
end
class RightAws::S3Interface; include Grants; end

exit 0
