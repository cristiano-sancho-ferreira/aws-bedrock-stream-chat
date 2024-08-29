########################
# SDLF Foundations comon
########################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

################### IAM ###################

# Variáveis aleatórias para sufixos
resource "random_integer" "suffix" {
  min = 200
  max = 900
}

# Nome das políticas e roles
locals {
  suffix                      = random_integer.suffix.result
  vector_store_name           = "bedrock-sample-rag-${local.suffix}"
  bedrock_execution_role_name = "AmazonBedrockExecutionRoleForKnowledgeBase_${local.suffix}"
  fm_policy_name              = "AmazonBedrockFoundationModelPolicyForKnowledgeBase_${local.suffix}"
  s3_policy_name              = "AmazonBedrockS3PolicyForKnowledgeBase_${local.suffix}"
  oss_policy_name             = "AmazonBedrockOSSPolicyForKnowledgeBase_${local.suffix}"
  region_name                 = var.region_name
  account_number              = data.aws_caller_identity.current.account_id
  bucket_name                 = aws_s3_bucket.repositorio.id
}

# Role para Bedrock
resource "aws_iam_role" "bedrock_execution_role" {
  name               = local.bedrock_execution_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "bedrock.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  description        = "Amazon Bedrock Knowledge Base Execution Role for accessing OSS and S3"
  max_session_duration = 3600
}

# Política Foundation Model
resource "aws_iam_policy" "foundation_model_policy" {
  name        = local.fm_policy_name
  description = "Policy for accessing foundation model"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = "arn:aws:bedrock:${local.region_name}::foundation-model/amazon.titan-embed-text-v1"
    }]
  })
}

# Política S3
resource "aws_iam_policy" "s3_policy" {
  name        = local.s3_policy_name
  description = "Policy for reading documents from s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        "arn:aws:s3:::${local.bucket_name}",
        "arn:aws:s3:::${local.bucket_name}/*"
      ]
      Condition = {
        StringEquals = {
          "aws:ResourceAccount" = local.account_number
        }
      }
    }]
  })
}


# Anexa as políticas à role
resource "aws_iam_role_policy_attachment" "attach_fm_policy" {
  role       = aws_iam_role.bedrock_execution_role.name
  policy_arn = aws_iam_policy.foundation_model_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.bedrock_execution_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

# Política OSS
resource "aws_iam_policy" "oss_policy" {
  name        = local.oss_policy_name
  description = "Policy for accessing opensearch serverless"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["aoss:APIAccessAll"]
      Resource = "arn:aws:aoss:${local.region_name}:${local.account_number}:collection/${local.vector_store_name}"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_oss_policy" {
  role       = aws_iam_role.bedrock_execution_role.name
  policy_arn = aws_iam_policy.oss_policy.arn
}

# Output do ARN da Role criada
output "bedrock_kb_execution_role_arn" {
  value = aws_iam_role.bedrock_execution_role.arn
}



################### S3 ###################

resource "aws_s3_bucket" "repositorio"{
  bucket = "cdbes01e08-sancho-${local.suffix}"   
  tags = var.common_tags
}



################### OpenSearch ###################

resource "aws_opensearchserverless_collection" "vector_search_collection" {
  name = local.vector_store_name
  description = "Vector search collection for knowledge base"
  type = "VECTORSEARCH"

  depends_on = [aws_opensearchserverless_security_policy.example]
}

resource "aws_opensearchserverless_security_policy" "example" {
  name = "example"
  type = "encryption"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/example"
        ],
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}




/*
# Recurso para criar a política de acesso
resource "aws_opensearchserverless_access_policy" "oss_access_policy" {
  name  = local.oss_policy_name
  type  = "data"
  
  policy = jsonencode({
    Rules = [{
      Resource   = ["collection/${aws_opensearchserverless_collection.vector_search_collection.name}"],
      Permission = [
        "aoss:CreateCollectionItems",
        "aoss:DeleteCollectionItems",
        "aoss:UpdateCollectionItems",
        "aoss:DescribeCollectionItems",
        "aoss:CreateIndex",
        "aoss:DeleteIndex",
        "aoss:UpdateIndex",
        "aoss:DescribeIndex",
        "aoss:ReadDocument",
        "aoss:WriteDocument"
      ],
      ResourceType = "collection"
    }]
    Principal = [aws_iam_role.bedrock_execution_role.arn, local.account_number]
    Description = "Policy to access the OpenSearch Serverless collection"
  })
  
}
*/



