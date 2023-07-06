variable "name" {
  type = string
}

variable "cors" {
  type = object({
    allow_origins     = list(string)
    allow_headers     = list(string)
    allow_methods     = list(string)
    allow_credentials = bool
    expose_headers = list(string)
    max_age           = number
  })

  default = null
}

variable "type" {
  type = string
}

variable "region" {
  type = string
}

variable "stage" {
  type = string
}

variable "auto_deploy" {
  type = bool
}

variable "authorizer" {
  type = object({
    audience = string
    issuer   = string
  })
  default = {
    audience = ""
    issuer   = ""
  }
}

variable "domain" {
  type = string
}

variable "api_domain" {
  type    = string
  default = ""
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "functions" {
  description = "Integrations for API Gateway"
  nullable    = true
  type = list(object({
    permissions = string
    function = object({
      name             = string
      handler          = string
      memory_size      = number
      runtime          = string
      timeout          = number
      filename         = string
      tracing_config   = bool
      source_code_hash = string
      environment      = map(string)
    })
    api = object({
      route  = string
      method = string
    })
  }))
  default = null
}