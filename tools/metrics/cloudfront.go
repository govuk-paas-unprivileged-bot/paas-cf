package main

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudfront"
	"github.com/aws/aws-sdk-go/service/cloudfront/cloudfrontiface"
)

type CloudFrontService struct {
	Client cloudfrontiface.CloudFrontAPI
}

func NewCloudFrontService(sess *session.Session) *CloudFrontService {
	return &CloudFrontService{
		Client: cloudfront.New(sess),
	}
}

func (cfs *CloudFrontService) listDistributions() ([]*cloudfront.DistributionSummary, error) {
	var distributionSummaries []*cloudfront.DistributionSummary
	err := cfs.Client.ListDistributionsPages(
		nil,
		func(listDistributionsOutput *cloudfront.ListDistributionsOutput, _ bool) bool {
			distributionSummaries = append(distributionSummaries, listDistributionsOutput.DistributionList.Items...)
			return true
		},
	)
	if err != nil {
		return distributionSummaries, err
	}
	return distributionSummaries, nil
}

type CustomDomain struct {
	CloudFrontDomain string
	AliasDomain      string
}

func (cfs *CloudFrontService) CustomDomains() ([]CustomDomain, error) {
	distributionSummaries, err := cfs.listDistributions()
	if err != nil {
		return []CustomDomain{}, err
	}
	var customDomains []CustomDomain
	for _, ds := range distributionSummaries {
		for _, item := range ds.Aliases.Items {
			customDomains = append(customDomains, CustomDomain{
				CloudFrontDomain: *ds.DomainName,
				AliasDomain:      *item,
			})
		}
	}
	return customDomains, nil
}
