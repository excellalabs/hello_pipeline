pipeline {
  agent {
    node {
      label 'dind'
    }

  }
  parameters {
        string(name: 'AWS_DEFAULT_REGION', defaultValue: 'us-east-2', description: 'The region to deploy to')
  }
  stages {
    stage('Test') {
      agent {
        node {
          label "ruby"
        }
      }
      steps {
        sh '''#!/usr/bin/env bash
        eval "$(rbenv init -)"
        bundle install
        bundle exec rspec
        '''
      }
    }
    stage('Build Container') {
      steps {
        sh '''docker build -t hello_world-ruby:${BUILD_TAG} .
        '''
        sh '''#!/usr/bin/env bash
if [[ $(aws ecr describe-repositories --query 'repositories[?repositoryName==`hello_world-ruby`].repositoryUri' --output text) -lt 1 ]]; then
aws ecr create-repository --repository-name hello_world-ruby;
fi
        '''
        sh '''
        export ECR_REPO=$(aws ecr describe-repositories --query 'repositories[?repositoryName==`hello_world-ruby`].repositoryUri' --output text)
        $(aws ecr get-login --no-include-email )
        docker tag hello_world-ruby:${BUILD_TAG} ${ECR_REPO}:${BUILD_TAG}
        docker push ${ECR_REPO}:${BUILD_TAG}'''
      }
    }

    stage('Push to ECS staging') {
      steps {
        sh '''#!/usr/bin/env bash
        export ECR_REPO=$(aws ecr describe-repositories --query 'repositories[?repositoryName==`hello_world-ruby`].repositoryUri' --output text)

        export CF_ROLE_ARN=$(aws cloudformation list-exports --query 'Exports[?Name==`CFRoleARN`].Value' --output text)
if aws cloudformation describe-stacks  --query 'Stacks[].StackName' | grep jenkinsecsHelloWorld-test ; then
aws cloudformation update-stack  --role-arn ${CF_ROLE_ARN} --stack-name jenkinsecsHelloWorld-test --template-body file://ruby-helloworld.json  --parameters ParameterKey=TaskAmount,ParameterValue=1 ParameterKey=ContainerImage,ParameterValue=${ECR_REPO}:${BUILD_TAG}
else
aws cloudformation create-stack  --role-arn ${CF_ROLE_ARN} --stack-name jenkinsecsHelloWorld-test --template-body file://ruby-helloworld.json  --parameters ParameterKey=TaskAmount,ParameterValue=1 ParameterKey=ContainerImage,ParameterValue=${ECR_REPO}:${BUILD_TAG}
fi
'''
        sh '''#!/usr/bin/env bash
       sleep 30
       export status=$(aws cloudformation describe-stacks  --stack-name=jenkinsecsHelloWorld-test --query Stacks[].StackStatus --output text)
       while [[ $status != *COMPLETE &&  $status != *FAILED ]]; do
       sleep 30
       export status=$(aws cloudformation describe-stacks  --stack-name=jenkinsecsHelloWorld-test --query Stacks[].StackStatus --output text)
       done
       echo $status
       [[ $status == "UPDATE_COMPLETE" || $status == "CREATE_COMPLETE" ]]
       '''
      }
    }
    stage('Wait for Input') {
      steps {
        input 'Proceed to production?'
      }
    }
  stage("Push to ECS production"){
    agent {
      node {
        label 'dind'
      }
    }
    steps {
      parallel(
        update_prod:{
      sh '''#!/usr/bin/env bash
      export ECR_REPO=$(aws ecr describe-repositories --query 'repositories[?repositoryName==`hello_world-ruby`].repositoryUri' --output text)

      export CF_ROLE_ARN=$(aws cloudformation list-exports --query 'Exports[?Name==`CFRoleARN`].Value' --output text)
if aws cloudformation describe-stacks  --query 'Stacks[].StackName' | grep jenkinsecsHelloWorld-production ; then
aws cloudformation update-stack  --role-arn ${CF_ROLE_ARN} --stack-name jenkinsecsHelloWorld-production --template-body file://ruby-helloworld.json  --parameters ParameterKey=TaskAmount,ParameterValue=2 ParameterKey=ContainerImage,ParameterValue=${ECR_REPO}:${BUILD_TAG}
else
aws cloudformation create-stack  --role-arn ${CF_ROLE_ARN} --stack-name jenkinsecsHelloWorld-production --template-body file://ruby-helloworld.json  --parameters ParameterKey=TaskAmount,ParameterValue=2 ParameterKey=ContainerImage,ParameterValue=${ECR_REPO}:${BUILD_TAG}
fi
'''
            sh '''#!/usr/bin/env bash
     sleep 30
     export status=$(aws cloudformation describe-stacks  --stack-name=jenkinsecsHelloWorld-production --query Stacks[].StackStatus --output text)
     while [[ $status != *COMPLETE &&  $status != *FAILED ]]; do
     sleep 30
     export status=$(aws cloudformation describe-stacks  --stack-name=jenkinsecsHelloWorld-production --query Stacks[].StackStatus --output text)
     done
     echo $status
     [[ $status == "UPDATE_COMPLETE" || $status == "CREATE_COMPLETE" ]]
     '''

          },
          "destroyStaging": {
            sh '''export CF_ROLE_ARN=$(aws cloudformation list-exports --query 'Exports[?Name==`CFRoleARN`].Value' --output text)
            aws cloudformation delete-stack  --role-arn ${CF_ROLE_ARN} --stack-name jenkinsecsHelloWorld-test'''

          }
        )
      }
    }
  }
}
