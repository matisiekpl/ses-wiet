terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-central-1"
  profile = "wiet"
}

variable "domain" {
  type = string
}

resource "aws_ses_domain_identity" "application_domain" {
  domain = var.domain
}

resource "aws_ses_domain_mail_from" "application_domain" {
  domain           = aws_ses_domain_identity.application_domain.domain
  mail_from_domain = "outbound.${aws_ses_domain_identity.application_domain.domain}"
}

resource "aws_ses_domain_dkim" "application_domain_dkim" {
  domain = aws_ses_domain_identity.application_domain.domain
}

output "domain_verification_token" {
  value = [
    "For domain verification, add the following CNAME record to your domain's DNS configuration:",
    "${aws_ses_domain_dkim.application_domain_dkim.dkim_tokens[0]}._domainkey",
    "${aws_ses_domain_dkim.application_domain_dkim.dkim_tokens[0]}.dkim.amazonses.com",
    "${aws_ses_domain_dkim.application_domain_dkim.dkim_tokens[1]}._domainkey",
    "${aws_ses_domain_dkim.application_domain_dkim.dkim_tokens[1]}.dkim.amazonses.com",
    "${aws_ses_domain_dkim.application_domain_dkim.dkim_tokens[2]}._domainkey",
    "${aws_ses_domain_dkim.application_domain_dkim.dkim_tokens[2]}.dkim.amazonses.com",
  ]
}

resource "aws_iam_user" "wrss_application_user" {
  name = "wrss_application_user"
}

resource "aws_iam_user_policy" "wrss_application_user_policy" {
  name = "wrss_application_user_policy"
  user = aws_iam_user.wrss_application_user.name
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ses:SendEmail",
          "ses:SendRawEmail",
        ],
        "Resource": "*"
      }
    ]
  })
}