#!/bin/bash
ROLE_NAME="AgentCore-customersupport-ApplicationAgentCustomerS-tLdnSvKbk5kA"

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "AgentCoreMemoryAccess" \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "bedrock-agentcore:GetMemory",
          "bedrock-agentcore:CreateEvent",
          "bedrock-agentcore:ListEvents",
          "bedrock-agentcore:ListSessions",
          "bedrock-agentcore:RetrieveMemoryRecords",
          "bedrock-agentcore:ListMemoryRecords",
          "bedrock-agentcore:GetMemoryRecord"
        ],
        "Resource": "arn:aws:bedrock-agentcore:us-east-1:682628551768:memory/CustomerSupportMemory-F2uG20EHm7"
      }
    ]
  }'

echo "SUCCESS! Nadagdag na ang memory permissions."
