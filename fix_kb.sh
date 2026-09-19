#!/bin/bash
ROLE_NAME="AgentCore-customersupport-ApplicationAgentCustomerS-tLdnSvKbk5kA"

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "AgentCoreKnowledgeBaseAccess" \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ],
        "Resource": "arn:aws:bedrock:us-east-1:682628551768:knowledge-base/ZIAGE1RLYY"
      }
    ]
  }'

echo "SUCCESS! Nadagdag na ang knowledge base permissions."
