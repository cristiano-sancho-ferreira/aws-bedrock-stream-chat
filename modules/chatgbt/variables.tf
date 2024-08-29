variable "lambda_function_name" {
  default = "bedrock-lambda-function"
}

variable "api_gateway_name" {
  default = "api_retrive_question_bedrock"
}

variable "region" {
  default = "us-east-1"
}


variable "bedrock_model_id" {
  description = "The Bedrock model ID you want to invoke"
  default     = "bedrock-model-id"
}
