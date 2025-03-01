/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "auto_create_network" {
  description = "Whether to create the default network for the project."
  type        = bool
  default     = false
}

variable "billing_account" {
  description = "Billing account id."
  type        = string
  default     = null
}

variable "compute_metadata" {
  description = "Optional compute metadata key/values. Only usable if compute API has been enabled."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "contacts" {
  description = "List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "custom_roles" {
  description = "Map of role name => list of permissions to create in this project."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "default_service_account" {
  description = "Project default service account setting: can be one of `delete`, `deprivilege`, `disable`, or `keep`."
  default     = "keep"
  type        = string
  validation {
    condition = (
      var.default_service_account == null ||
      contains(["delete", "deprivilege", "disable", "keep"], var.default_service_account)
    )
    error_message = "Only `delete`, `deprivilege`, `disable`, or `keep` are supported."
  }
}

variable "descriptive_name" {
  description = "Name of the project name. Used for project name instead of `name` variable."
  type        = string
  default     = null
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    custom_roles = optional(string)
    org_policies = optional(string)
  })
  nullable = false
  default  = {}
}

variable "group_iam" {
  description = "Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam" {
  description = "Authoritative IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_bindings" {
  description = "Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary."
  type = map(object({
    members = list(string)
    role    = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "iam_bindings_additive" {
  description = "Individual additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "lien_reason" {
  description = "If non-empty, creates a project lien with this description."
  type        = string
  default     = null
}

variable "logging_data_access" {
  description = "Control activation of data access logs. Format is service => { log type => [exempted members]}. The special 'allServices' key denotes configuration for all services."
  type        = map(map(list(string)))
  nullable    = false
  default     = {}
  validation {
    condition = alltrue(flatten([
      for k, v in var.logging_data_access : [
        for kk, vv in v : contains(["DATA_READ", "DATA_WRITE", "ADMIN_READ"], kk)
      ]
    ]))
    error_message = "Log type keys for each service can only be one of 'DATA_READ', 'DATA_WRITE', 'ADMIN_READ'."
  }
}

variable "logging_exclusions" {
  description = "Logging exclusions for this project in the form {NAME -> FILTER}."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "logging_sinks" {
  description = "Logging sinks to create for this project."
  type = map(object({
    bq_partitioned_table = optional(bool)
    description          = optional(string)
    destination          = string
    disabled             = optional(bool, false)
    exclusions           = optional(map(string), {})
    filter               = string
    iam                  = optional(bool, true)
    type                 = string
    unique_writer        = optional(bool, true)
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      contains(["bigquery", "logging", "pubsub", "storage"], v.type)
    ])
    error_message = "Type must be one of 'bigquery', 'logging', 'pubsub', 'storage'."
  }
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      v.bq_partitioned_table != true || v.type == "bigquery"
    ])
    error_message = "Can only set bq_partitioned_table when type is `bigquery`."
  }
}

variable "metric_scopes" {
  description = "List of projects that will act as metric scopes for this project."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "name" {
  description = "Project name and id suffix."
  type        = string
}

variable "org_policies" {
  description = "Organization policies applied to this project keyed by policy name."
  type = map(object({
    inherit_from_parent = optional(bool) # for list policies only.
    reset               = optional(bool)
    rules = optional(list(object({
      allow = optional(object({
        all    = optional(bool)
        values = optional(list(string))
      }))
      deny = optional(object({
        all    = optional(bool)
        values = optional(list(string))
      }))
      enforce = optional(bool) # for boolean policies only.
      condition = optional(object({
        description = optional(string)
        expression  = optional(string)
        location    = optional(string)
        title       = optional(string)
      }), {})
    })), [])
  }))
  default  = {}
  nullable = false
}

variable "parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = var.parent == null || can(regex("(organizations|folders)/[0-9]+", var.parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "prefix" {
  description = "Optional prefix used to generate project id and name."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_create" {
  description = "Create project. When set to false, uses a data source to reference existing project."
  type        = bool
  default     = true
}

variable "service_config" {
  description = "Configure service API activation."
  type = object({
    disable_on_destroy         = bool
    disable_dependent_services = bool
  })
  default = {
    disable_on_destroy         = false
    disable_dependent_services = false
  }
}

variable "service_encryption_key_ids" {
  description = "Cloud KMS encryption key in {SERVICE => [KEY_URL]} format."
  type        = map(list(string))
  default     = {}
}

# accessPolicies/ACCESS_POLICY_NAME/servicePerimeters/PERIMETER_NAME
variable "service_perimeter_bridges" {
  description = "Name of VPC-SC Bridge perimeters to add project into. See comment in the variables file for format."
  type        = list(string)
  default     = null
}

# accessPolicies/ACCESS_POLICY_NAME/servicePerimeters/PERIMETER_NAME
variable "service_perimeter_standard" {
  description = "Name of VPC-SC Standard perimeter to add project into. See comment in the variables file for format."
  type        = string
  default     = null
}

variable "services" {
  description = "Service APIs to enable."
  type        = list(string)
  default     = []
}

variable "shared_vpc_host_config" {
  description = "Configures this project as a Shared VPC host project (mutually exclusive with shared_vpc_service_project)."
  type = object({
    enabled          = bool
    service_projects = optional(list(string), [])
  })
  default = null
}

variable "shared_vpc_service_config" {
  description = "Configures this project as a Shared VPC service project (mutually exclusive with shared_vpc_host_config)."
  # the list of valid service identities is in service-agents.yaml
  type = object({
    host_project                = string
    network_users               = optional(list(string), [])
    service_identity_iam        = optional(map(list(string)), {})
    service_identity_subnet_iam = optional(map(list(string)), {})
    service_iam_grants          = optional(list(string), [])
    network_subnet_users        = optional(map(list(string)), {})
  })
  default = {
    host_project = null
  }
  nullable = false
  validation {
    condition = var.shared_vpc_service_config.host_project != null || (
      var.shared_vpc_service_config.host_project == null &&
      length(var.shared_vpc_service_config.network_users) == 0 &&
      length(var.shared_vpc_service_config.service_iam_grants) == 0 &&
      length(var.shared_vpc_service_config.service_identity_iam) == 0 &&
      length(var.shared_vpc_service_config.service_identity_subnet_iam) == 0 &&
      length(var.shared_vpc_service_config.network_subnet_users) == 0
    )
    error_message = "You need to provide host_project when providing Shared VPC host and subnet IAM permissions."
  }
}

variable "skip_delete" {
  description = "Allows the underlying resources to be destroyed without destroying the project itself."
  type        = bool
  default     = false
}
