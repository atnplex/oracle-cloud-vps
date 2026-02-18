# Account 3 (anhnguy079) — Baseline Terraform
# This file defines the core governance (Budgets, Alarms) and base compartments.

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# 1. Compartments
resource "oci_iam_compartment" "network" {
  name           = "network"
  description    = "Infrastructure networking layer"
  compartment_id = var.tenancy_ocid
}

resource "oci_iam_compartment" "workloads" {
  name           = "workloads"
  description    = "Computational workloads (VPS instances)"
  compartment_id = var.tenancy_ocid
}

# 2. Governance: Budget
resource "oci_budgets_budget" "baseline_budget" {
  amount         = 1
  compartment_id = var.tenancy_ocid
  display_name   = "Safety-Budget-Monthly"
  reset_period   = "MONTHLY"
  
  description = "Safety net for Always Free tier (Acc3)"
  target_type = "COMPARTMENT"
  targets     = [var.tenancy_ocid]
}

resource "oci_budgets_alert_rule" "alert_80" {
  budget_id      = oci_budgets_budget.baseline_budget.id
  threshold      = 80
  threshold_type = "PERCENTAGE"
  type           = "ACTUAL"
  
  message     = "OCI Account 3 has reached 80% of its monthly budget safety limit."
  recipients  = "alex@atnplex.com"
}

# 3. Security: Cloud Guard
resource "oci_cloud_guard_cloud_guard_configuration" "main" {
  compartment_id         = var.tenancy_ocid
  reporting_region       = var.region
  status                 = "ENABLED"
  self_manage_resources  = false
}
