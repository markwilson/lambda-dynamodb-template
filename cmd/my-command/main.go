package main

import (
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"os"
)

var dynamoDBSvc *dynamodb.DynamoDB

func init() {
	endpoint := os.Getenv("ENDPOINT_OVERRIDE")
	var cfg *aws.Config
	if endpoint != "" {
		cfg = &aws.Config{Endpoint: aws.String(endpoint)}
	}

	dynamoDBSvc = dynamodb.New(session.Must(session.NewSession()), cfg)
}

func main() {
	lambda.Start(handler)
}

func handler() error {
	// TODO: use the dynamoDBSvc...

	return nil
}
