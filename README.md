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

When? (example use case)
-------
In this example we will setup a new Cloudfront Private Streaming distribution
with the following attributes:

* S3 origin bucket:    my-video-bucket
* CF base URL (CNAME): rtmp://cf.example.com/

#### Setup AWS keys ####
    $ export AWS_ACCESS_KEY_ID='xxxxx'
	$ export AAWS_SECRET_ACCESS_KEY='xxxxxx'

#### Create a new Cloudfront Streaming Distribution ####
	$ ./cf-streaming-distribution.rb create my-video-bucket \
   		--cname cf.example.com \
 		-m "private streaming distribution (rtmp) with origin bucket: my-video-bucket"

 		Success!
		domain_name:  s1loj2pirm00it.cloudfront.net
		aws_id:       E1UGDLF9XZBD79

