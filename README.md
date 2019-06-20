# AWS API Gateway example

## Pre Requisite:

1. Node
2. Make
3. awscli
4. jq

## How to use it:

Following is the lambda and role config for using the api in other project.

  ```yaml
Parameters:
  Service:
    Type: String

...

### Lambda
  LambdaThatWillUseThisApi:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: !Sub ${Service}-lambda
      CodeUri: ../src/lambdaSourceCode
      Role: !GetAtt ApiRole.Arn
      Environment:
        Variables:
          ENVIRONMENT: !Ref Environment
          
...

  ApiRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - lambda.amazonaws.com
            Action:
              - sts:AssumeRole
      Path: /
      RoleName: !Sub ${Service}
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
        - !Sub arn:aws:iam::${AWS::AccountId}:policy/aws-apigw-example-fullaccess
  ```
