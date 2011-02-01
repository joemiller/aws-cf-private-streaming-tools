aws-cf-private-streaming-tools
==============================

What?
-----------
A set of ruby CLI tools for creating and modifying Amazon Cloudfront 
Private Streaming Distributions and Origin Access ID's, using the
RightAWS ruby library.

Why?
----
I created these tools a in late 2010 because I needed to setup a 
private streaming distribution (RTMP) on Amazon Cloudfront.  However,
the Amazon web management console did not support this and I could
not find any cli tools either.

Luckily the right_aws ruby libraries (>= 2.0.0) already had support 
for Private Streaming distributions, so all I had to do was put together
a few CLI wrappers to make them easy for admins to utilize.

Available Commands
------------------
#### cf-streaming-distribution.rb ####
	$ ./cf-streaming-distribution.rb --help

	Synopsis
	--------
	cf-streaming-distribution: Manipulate Amazon Cloudfront Streaming
	Distributions

	Usage
	-----
	cf-streaming-distribution.rb [OPTIONS] [command] [args]

	Commands
	--------
	  list
	      List all Streaming Distributions

	  get [aws_id]
	      Get details about the Streaming Distribution identified by [aws_id].

	  create [bucket]
	      Create new Streaming Distribution using S3 origin bucket [bucket].  CNAMEs
	      can optionally be specified with multiple --cname options, and a comment can
	      be applied with --comment option

	  delete [aws_id] [e_tag]
	      Delete the Streaming Distribution identified by [aws_id] and [e_tag].  A
	      distribution must first be disabled before it can be deleted.  Use 'get'
	      to retrieve a distribution's e_tag.

	  modify [aws_id]
	      Modify attributes on the Streaming Distribution identified by [aws_id].  Must
	      be used in conjunction with at least one of the following options:
	      --comment, --enabled, --oai, --trusted-signer, --cname

	  wait [aws_id]
	      Loop until a Streaming Distribution specified by [aws_id] enters the 'deployed'
	      state.  You could use this in scripts if you need to know when a
	      distribution becomes available for use.

#### ./cf-origin-access-id.rb ####
	$ ./cf-origin-access-id.rb --help
	Synopsis
	--------
	cf-origin-access-id:

	   List, create, delete CloudFront Origin Access Identities (OAI's), as well
	   as grant permissions on S3 objects to CloudFront OAI's.

	Usage
	-----
	cf-origin-access-id.rb [OPTIONS] [command] [args]

	commands:
	---------
	 list:
	      List Origin Access Identities

	 create [comment]
	      Create a new Origin Access Identity.  The AWS_ID and S3 Canonical ID
	      will be returned if successful

	 get [aws_id]
	      Get details about an Origin Access Identity specified by [aws_id].  This
	      command will display e_tag which is needed to delete an OAI

	 delete [aws_id] [e_tag]
	      Delete the Origin Access Identity specified by [aws_id] and [e_tag]. Use
	      'get' to retrieve the current e_tag.

	 grant [aws_id] [bucket]
	      grant 'FULL_PERMISSION' access on <tt>all</tt> objects inside the S3 bucket specified
	      by [bucket] to the OAI specified by [aws_id].  There is little reason to
	      create an OAI other than to give it permissions to some objects within S3,
	      and this command helps simplify that for you.

Example Workflow
----------------
In this example we will setup a new Cloudfront Private Streaming distribution
with the following attributes:

* S3 origin bucket:    my-video-bucket
* CF base URL (CNAME): rtmp://cf.example.com/

#### 1. Setup AWS keys ####
    $ export AWS_ACCESS_KEY_ID='xxxxx'
	$ export AAWS_SECRET_ACCESS_KEY='xxxxxx'

#### 2. Create a new Cloudfront Streaming Distribution ####
	$ ./cf-streaming-distribution.rb create my-video-bucket \
   		--cname cf.example.com \
 		-m "private streaming distribution (rtmp) with origin bucket: my-video-bucket"

 		Success!
		domain_name:  s1loj2pirm00it.cloudfront.net
		aws_id:       E1UGDLB9XZBD79

#### 3. Configure CNAME in your DNS server #####
This part will depend on DNS server or DNS provider.  You'll need to create a new CNAME
for cf.example.com --> s1loj2pirm00it.cloudfront.net

#### 4. Create a new Origin-Access-ID (OAI) ####
	$ ./cf-origin-access-id.rb create "OAI for use on the cf.example.com distribution"
	  Success!
	  AWS_ID           : E2CWXW7A1B3YIU
	  Location       : https://cloudfront.amazonaws.com/origin-access-identity/cloudfront/E2CWXW7A1B3YIU
	  S3 Canonical ID: 3b5285f7f1b51ff2e63e8ff8127b7ffb76edee24580cb7fff6ef812aa87b749aaa3ed1aab389aaaab4453499a7ba57e7

#### 5. Assign the OAI to the Cloudfront distribution ####
	./cf-streaming-distribution.rb modify E1UGDLB9XZBD79 --oai E2CWXW7A1B3YIU
	  Success!

#### 6. Grant the OAI access to the files in the S3 bucket ####
	$ ./cf-origin-access-id.rb grant E2CWXW8B1U3YJU my-video-bucket
	  Applying grant [E2CWXW8B1U3YJU:'FULL_CONTROL'] on: my-video-bucket/flvs/video01.flv
	  Applying grant [E2CWXW8B1U3YJU:'FULL_CONTROL'] on: my-video-bucket/flvs/video02.flv
	  ...
	
#### 7. Create RSA Keypair on the Amazon AWS website ####
You cannot create keypairs with the cloudfront API, so you'll need to do this step
on the AWS website.

* Goto http://aws.amazon.com then login:
* Account > Security Credentials > Key Pairs
* Click “Create New Key Pair” under the “Cloudfront Key Pairs” section
* A keypair will be created and the private key will automatically begin downloading. 

	You must save this file! it will be in the form “pk-XXXXXX.pem”. If you lose this key, 
	you can’t get it back because Amazon only stores the public key.
	
#### 8. Register the account and keypairs on the cloudfront distribution ####
NOTE: the --trusted-signer arguments takes an amazon account ID as an argument.  
The special ‘self’ can be used instead.

	$ ./cf-streaming-distribution.rb modify E1UGDLB9XZBD79 --trusted-signer self
	  Success!
	
#### 9. Verify settings on the new private Streaming Distribution ####
	$ ./cf-streaming-distribution.rb get E1UGDLB9XZBD79
	 AWS_ID            : E1UGDLB9XZBD79
	   E_TAG           : EQ3HGAPOK1IFN
	   Status          : InProgress
	   Enabled         : true
	   domain_name     : s1loj2pirm00it.cloudfront.net
	   origin          : my-video-bucket.s3.amazonaws.com
	   CNAMEs          : cf.example.com
	   Comment         : private streaming distribution (rtmp) with origin bucket: my-video-bucket
	   Origin Access ID: origin-access-identity/cloudfront/E2CWXW7A1B3YIU
	   Trusted Signers : self
	   Active Signers:
	       -> aws_account_number: self
	            -> key_pair_id  :  APDBDOEHALFXGK5AQU5R

NOTE: The distribution will not be usable until Status changes from InProgress to Deployed. 
This can take up to 15minutes.

You can also use the command `cf-streaming-distribution.rb wait AWS_ID` to
wait for a distribution to change from InProgress to Deployed.  The command will
exit as soon as the status changes to Deployed.  This is useful for scripts
where you need to control timing.

Who?
----
Joe Miller - joeym -at- joeym.net