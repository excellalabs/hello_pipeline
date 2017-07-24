# Sample "Hello World" Ruby application with a Jenkins CI/CD Pipeline

This repository provides a basic Ruby Sinatra application that renders
"Hello World" over HTTP through Passenger and Nginx.

The application can be created into a Docker container, contains an Rspec test
suite to verify the expected text is rendered, and has a Jenkins CI pipeline.

Upon a successful CI build the container is published to an Amazon ECR. Which
can then be pushed to production with a single click.

## The Jenkins CI / CD Pipeline

Included is a cloudformation template that deploys a new VPC along with an
ECS cluster and Jenkins, based on a cloudformation template originally
[created by Stelligent](https://stelligent.com/2016/08/24/containerized-ci-solutions-in-aws-part-1-jenkins-in-ecs/).

### Creating the Jenkins CloudFormation Stack

You'll first need to make sure you have created an SSH keypair and added it to your account under:  
`EC2` > `NETWORK & SECURITY` > `Key Pairs`

Next you'll need to go to AWS' `CloudFormation` (under `Management Tools`) and press the `Create Stack` button.

This will take you to a screen where you can select to upload a CloudFormation
template file. Be sure to select the `ecs-jenkins.json` file from the root of
this repository and to give the stack a name ("jenkins-ecs" for example).

Once you've selected the file and hit `Next` you'll be taken to a page to input
several parameters for the template. These include the following:

```
AvailabilityZone1 and AvailabilityZone2 -- two availability zones that you want to deploy your VPC and ECS cluster in.
InstanceType -- the amazon instance type you want for your ECS instances (m4.large suggested)
EcsImageId -- the ami-id of the ECS image you want to use - see the latest options [here](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html).
KeyPair - the SSH key pair you'd like to use.
PublicAccessCIDR -- The IP address block that will have access to your Jenkins instance in CIDR format (e.g., 192.168.0.1/32)
```

Once the CloudFormation template is deployed, under the 'outputs' tab in the
CloudFormation console, there will be a Jenkins URL that you can click on to
take you to the Jenkins instance. You'll also want to remember this page for
the `JenkinsConfigurationAlternativeJenkinsURL` and the `DockerCloudFormationARN`
values that are needed later.

### Security Configuration & User Account

You'll need to make some security configuration changes at this time under:  
`Manage Jenkins` > `Configure Global Security`

* Click `Enable Security`
* Under Access Control select `Jenkins’ own user database`
* Click `Save`

You'll need to create a user account next. This can be done by clicking "sign
up" in the upper-right corner. Enter the appropriate information to create an
account and click `Sign up`.

### Install Jenkins Plugins

`Manage Jenkins` > `Manage Plugins` > `Available`

* Search for "Blue Ocean" and select it.
* Search for "Amazon EC2 Container Service" and select it.
* Select "Download Now And Install After Restart"
* Once the plugins are installed refresh the page and click "log in" in the upper-right corner.

### Create the AWS ECS cloud provider

`Manage Jenkins` > `Configure System`

* Scroll to the very bottom of the page
* Under "Cloud" select `Add a new cloud` > `Amazon EC2 Container Service Cloud`
* Ener the following details:

        Name: jenkins-slave
        Amazon Ecs Credentials: None
        Region Name: AWS region you deployed your CloudFormation Stack into
        ECS Cluster: Cluster that starts with your stack name
        Advanced:
          Alternative Jenkins URL: Use the `JenkinsConfigurationAlternativeJenkinsURL` referenced earlier

* Click Save

### Add Docker Containers to Jenkins Workers

Next add two Docker containers for the Jenkins workers to use when testing the
Ruby application:

`Manage Jenkins` > `Configure System`

Search on `ECS slave templates` and click `Add`:

Create a template with the following information:

        Template Name: dind
        Template Label: dind
        Docker image: excellalabs/jnlp-docker
        Memory reservation: 512
        Advanced
          Task role ARN: Use the `DockerCloudFormationARN` referenced earlier.
          Privileged mode: Checked
          Container mountpoints:
            Name: docker
            Source Path: /var/run/docker.sock
            Container Path: /var/run/docker.sock

Repeat the steps above to add another `ECS slave template` with the following:

        Template Name: ruby
        Template Label: ruby
        Docker image: excellalabs/jnlp-ruby
        Memory reservation: 512

Click `Save`

### Creating the Application Pipeline

Once the plugins have been installed, and the Docker containers have been added
you'll need to create a new application pipeline:  
`Open Blue Ocean` > `Create a new Pipeline`

* Select `Git`
* Enter the following Repository URL: `https://github.com/excellalabs/hello_pipeline.git`
* Click `Create Pipeline`

Note: Jenkins may automatically kick off a build, if so it will likely fail the first time due to an incorrect region. Follow the steps below to have the build work successfully.

### The Build

Congratulations. You've successfully created a Jenkins CI server through
automation and setup a Blue Ocean CI / CD Pipeline from the `Jenkinsfile`
within the application repository to ensure that all future pull requests have
passing tests before creating a new release to push to an internal AWS ECR
docker container registry.

The pipeline also allows for one click deployment once the build is satisfactory
and ready to go to production.

To see how this pipeline works you can do the following:  
`Open Blue Ocean` > `hello_pipeline` > `Branches`

Next to the master branch is a play button (after indexing of the git repository completes).  
Push the play icon to trigger a build.  
It will now ask you to enter an AWS region to run the build in, be sure this
region matches the AWS::Region you set when you created your CloudFormation.  
Note: You may need to refresh occasionally due to some bugs in the Blue Ocean Jenkins UI.

Once this build is completed successfully you'll see a "Proceed to Production" button.

This button will let you deploy your newly built Docker container to production. To verify the staging build is working and demo the applicatoin you can find the internal Amazon URL within the AWS CloudFormation stack output by doing the following:

* Go to `CloudFormation`
* Click on the newly created `jenkinsecsHelloWorld-test` stack
* Select the `Outputs` tab
* The key `ELBDNS` contains a value for the staging application deployment
* Paste the URL from this value into a new tab and verify it says "Hello World"

Once you've verified the output meets your acceptance criteria you can pus the
"Proceed to Production" button to push it to production.

Follow the steps above to see your production application on it's internal AWS
URL. The only difference will be that the stack name will switch from:  
`jenksinsecsHelloWorld-test` to `jenkinsecsHelloWorld-production`

Below we go a bit more into the Ruby application and what the container
provides, but everything is now successfully automated.

## The Application

### Running the Sinatra Application

```
bundle install
bundle exec rackup
```

You can now browse the Hello World app at:
[http://localhost:9292](http://localhost:9292)

### Running the Rspec Test Suite

```
bundle install
bundle exec rspec
```

You'll see that there is one passing spec verifying that "Hello World" was
rendered with a 200 HTTP response.


## Docker Container

To create and run a Docker container of the Hello World Sinatra application
you can do the following:

```
docker build -t="hello_world-ruby-2_4:0.1" .
docker run -d -p 9292:80 hello_world-ruby-2_4:0.1
```

You can now browse the application at: [http://localhost:9292](http://localhost:9292)

This docker container utilizes Phusion Passenger and Nginx to allow it to
reunder Ruby, Python, and JavaScript applications (including Node.js) easily
with the same configuration.
