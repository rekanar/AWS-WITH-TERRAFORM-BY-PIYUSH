# Phase 1 — Terraform Fundamentals

> **Mentor Note:** Before writing a single line of Terraform code, you must deeply understand what Terraform is, why it exists, and how it works. This mental model will save you weeks of confusion later.

---

## Table of Contents

1. [What is Infrastructure as Code (IaC)?](#1-what-is-infrastructure-as-code-iac)
2. [Why Terraform? (vs Alternatives)](#2-why-terraform-vs-alternatives)
3. [How Terraform Works Internally](#3-how-terraform-works-internally)
4. [Terraform Core Concepts](#4-terraform-core-concepts)
5. [Terraform Workflow](#5-terraform-workflow)
6. [Terraform State — Deep Dive](#6-terraform-state--deep-dive)
7. [Your First Terraform File](#7-your-first-terraform-file)
8. [Commands to Execute](#8-commands-to-execute)
9. [Expected Output](#9-expected-output)
10. [Common Errors](#10-common-errors)
11. [Debugging Tips](#11-debugging-tips)
12. [Real-World Production Notes](#12-real-world-production-notes)
13. [Mini Assignment](#13-mini-assignment)

---

## 1. What is Infrastructure as Code (IaC)?

### Concept Explanation

**Infrastructure as Code (IaC)** means managing and provisioning cloud resources (servers, databases, networks, etc.) using **code files** instead of clicking through a UI console.

Think of it this way:

- **Without IaC:** You log into AWS Console → click "Create EC2" → fill forms → repeat for every environment
- **With IaC:** You write a `.tf` file describing what you want → run a command → Terraform handles the rest

```
Traditional (Manual)               IaC (Terraform)
─────────────────────              ────────────────────
Log in to AWS Console         →    Write code in .tf files
Click through UI              →    terraform apply
Repeat for dev/stage/prod     →    Reuse same code across environments
Hope you remember what you did →   Everything is version-controlled in Git
No audit trail                →    Git history = full audit trail
```

### Why Companies Use IaC

| Problem Without IaC             | Solution With IaC               |
| ------------------------------- | ------------------------------- |
| "Works in dev, broken in prod"  | Identical infra via same code   |
| Snowflake servers (each unique) | Consistent, reproducible infra  |
| No disaster recovery            | Rebuild entire infra in minutes |
| Manual, error-prone changes     | Automated, tested changes       |
| No visibility into what changed | Git diff shows every change     |

### Industry Best Practice

> **Always treat infrastructure like application code.** It lives in Git, goes through code review (Pull Requests), and is deployed via CI/CD pipelines — never by hand.

---

## 2. Why Terraform? (vs Alternatives)

### Concept Explanation

There are multiple IaC tools. Understanding the landscape helps you make informed decisions.

| Tool           | Vendor              | Language     | Multi-Cloud | Notes                                              |
| -------------- | ------------------- | ------------ | ----------- | -------------------------------------------------- |
| **Terraform**  | HashiCorp (now IBM) | HCL          | Yes         | Industry standard, huge ecosystem                  |
| CloudFormation | AWS                 | YAML/JSON    | AWS only    | Tightly integrated with AWS, verbose               |
| Pulumi         | Pulumi              | Python/TS/Go | Yes         | Uses real programming languages                    |
| CDK            | AWS                 | Python/TS    | AWS focused | Compiles to CloudFormation                         |
| Ansible        | Red Hat             | YAML         | Yes         | Better for config mgmt, not ideal for provisioning |

### Why Terraform Wins in Most Enterprise Shops

1. **Multi-cloud support** — same tool for AWS, Azure, GCP
2. **Declarative syntax** — you describe WHAT you want, not HOW to do it
3. **Massive provider ecosystem** — 3000+ providers (AWS, GitHub, Datadog, Kubernetes, etc.)
4. **Strong community** — most job postings require Terraform
5. **Module registry** — reusable, shareable modules at [registry.terraform.io](https://registry.terraform.io)
6. **Plan before apply** — preview changes before they happen (like a dry run)

### Industry Best Practice

> Use **OpenTofu** (open-source Terraform fork) or **Terraform >= 1.5** in new projects. HashiCorp changed the license in 2023 — understand the BSL license implications for your company before using the commercial version.

---

## 3. How Terraform Works Internally

### Concept Explanation

Terraform operates in a **declarative model** using a 3-step internal process:

```
┌─────────────────────────────────────────────────────────┐
│                  TERRAFORM EXECUTION FLOW                │
│                                                         │
│  .tf Files          Terraform Core         AWS API      │
│  ──────────         ─────────────          ───────      │
│  desired state  →   diff engine       →    real state   │
│                     (plan)                              │
│                         ↓                              │
│                     create/update/delete calls          │
└─────────────────────────────────────────────────────────┘
```

**Terraform's 3-way reconciliation:**

1. **Desired State** — what you wrote in `.tf` files
2. **Current State** — what's in `terraform.tfstate`
3. **Real State** — what actually exists in AWS

Terraform computes the **diff** between desired and current, then makes API calls to reconcile.

### The DAG (Directed Acyclic Graph)

Terraform builds a **dependency graph** of all resources before executing. This means:

- Independent resources are created **in parallel**
- Dependent resources are created **in order**

```
Example dependency graph:

VPC ──────────┐
              ↓
Subnet ──→ Security Group ──→ EC2 Instance
```

---

## 4. Terraform Core Concepts

### 4.1 Providers

A **provider** is a plugin that allows Terraform to interact with a specific API (AWS, Azure, GitHub, etc.).

```hcl
# providers.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "us-east-1"
}
```

**What `~> 5.0` means:**

- Allows `5.0`, `5.1`, `5.99` — but NOT `6.0`
- This is called a **pessimistic constraint operator**
- Protects you from breaking changes in major versions

### 4.2 Resources

A **resource** is the fundamental building block — it represents a single infrastructure object.

```hcl
# Syntax
resource "<PROVIDER>_<TYPE>" "<LOCAL_NAME>" {
  argument1 = "value"
  argument2 = "value"
}

# Example
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-company-assets-2024"
}
```

- `aws_s3_bucket` = provider + resource type
- `my_bucket` = local name (used to reference this resource in other places)
- Referenced elsewhere as: `aws_s3_bucket.my_bucket.id`

### 4.3 Variables

**Input variables** make your configuration reusable and environment-agnostic.

```hcl
# variables.tf
variable "environment" {
  description = "Deployment environment (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}
```

### 4.4 Outputs

**Outputs** expose values from your infrastructure — useful for referencing across modules or displaying after apply.

```hcl
# outputs.tf
output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.arn
}
```

### 4.5 Data Sources

**Data sources** let you read existing resources that were NOT created by this Terraform configuration.

```hcl
# Read an existing VPC you didn't create
data "aws_vpc" "existing" {
  tags = {
    Name = "production-vpc"
  }
}

# Use it
resource "aws_subnet" "new_subnet" {
  vpc_id = data.aws_vpc.existing.id
  # ...
}
```

### 4.6 Locals

**Locals** are computed values used to avoid repetition.

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = "terraform-learning"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
  }

  bucket_name = "${var.project_name}-${var.environment}-assets"
}
```

---

## 5. Terraform Workflow

### The 4 Core Commands

```
terraform init → terraform plan → terraform apply → terraform destroy
     ↑                ↑                ↑                  ↑
  Setup          Preview          Execute            Teardown
```

---

### 5.1 `terraform init`

**What it does:**

- Downloads provider plugins (e.g., AWS provider)
- Initializes the backend (local or remote)
- Downloads modules
- Creates `.terraform/` directory and `.terraform.lock.hcl`

```bash
terraform init
```

**What gets created:**

```
.terraform/
├── providers/
│   └── registry.terraform.io/
│       └── hashicorp/
│           └── aws/
│               └── 5.x.x/
│                   └── terraform-provider-aws_v5.x.x
└── terraform.lock.hcl   ← dependency lock file (commit this to Git)
```

**Why `.terraform.lock.hcl` matters:**

- Locks exact provider versions
- Ensures everyone on the team uses the same provider version
- **Always commit this file to Git**

**Industry Best Practice:**

```bash
# Always re-run init after:
# - Adding a new provider
# - Changing backend config
# - Updating provider version constraints
terraform init -upgrade   # upgrades providers within version constraints
```

---

### 5.2 `terraform plan`

**What it does:**

- Reads current state (from `terraform.tfstate`)
- Reads desired state (from `.tf` files)
- Shows you EXACTLY what will happen — create, update, or destroy

```bash
terraform plan
```

**Reading the plan output:**

```
+ resource will be CREATED
~ resource will be UPDATED in-place
- resource will be DESTROYED
-/+ resource will be DESTROYED and re-created (replacement)
<= data source will be READ
```

**Save a plan file (production best practice):**

```bash
terraform plan -out=tfplan       # save plan to file
terraform apply tfplan           # apply exactly that saved plan
```

> **Why save the plan?** In CI/CD, you run `plan` in one step (PR review) and `apply` in another (after approval). Saving ensures what gets applied is exactly what was reviewed.

**Common `plan` flags:**

```bash
terraform plan -var="environment=prod"          # override a variable
terraform plan -var-file="prod.tfvars"          # use a tfvars file
terraform plan -target=aws_s3_bucket.my_bucket  # plan only one resource
terraform plan -refresh=false                   # skip AWS API calls (faster, risky)
```

---

### 5.3 `terraform apply`

**What it does:**

- Executes the plan
- Makes actual AWS API calls
- Updates `terraform.tfstate` with new state

```bash
terraform apply          # shows plan, prompts for "yes"
terraform apply -auto-approve  # skips confirmation (use in CI/CD only)
terraform apply tfplan   # applies a previously saved plan
```

> **Beginner Mistake:** Never use `-auto-approve` in production manually. Always review the plan first. `-auto-approve` is only for CI/CD pipelines where plan was already reviewed and approved via PR.

---

### 5.4 `terraform destroy`

**What it does:**

- Destroys ALL resources managed by the current configuration
- Updates state to reflect deletions

```bash
terraform destroy                             # destroys everything
terraform destroy -target=aws_s3_bucket.my_bucket  # destroys one resource
```

> **Production Warning:** `terraform destroy` in a production environment is catastrophic. Most teams:
>
> 1. Restrict who can run destroy
> 2. Use [lifecycle prevent_destroy](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle) on critical resources
> 3. Require manual approval gates

```hcl
# Protecting critical resources from accidental destroy
resource "aws_rds_instance" "production_db" {
  # ...
  lifecycle {
    prevent_destroy = true
  }
}
```

### Other Useful Commands

```bash
terraform fmt              # auto-format all .tf files (run before every commit)
terraform validate         # validates syntax without connecting to AWS
terraform show             # human-readable view of state or plan
terraform state list       # list all resources in state
terraform state show <resource>  # inspect a specific resource in state
terraform output           # display outputs
terraform graph            # generate dependency graph (pipe to graphviz)
terraform version          # check Terraform version
```

---

## 6. Terraform State — Deep Dive

### What is Terraform State?

The **state file** (`terraform.tfstate`) is Terraform's source of truth about what real-world resources it manages.

It is a **JSON file** that maps your Terraform resource definitions to real AWS resource IDs:

```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "resources": [
    {
      "type": "aws_s3_bucket",
      "name": "my_bucket",
      "instances": [
        {
          "attributes": {
            "id": "my-company-assets-2024",
            "arn": "arn:aws:s3:::my-company-assets-2024",
            "bucket": "my-company-assets-2024",
            "region": "us-east-1"
          }
        }
      ]
    }
  ]
}
```

### Why State is Critical

| Without State                    | With State                                  |
| -------------------------------- | ------------------------------------------- |
| Terraform can't know what exists | Tracks all managed resources                |
| Would try to recreate everything | Diffs desired vs actual                     |
| Couldn't detect drift            | Detects when someone changes infra manually |
| Can't destroy what it created    | Knows exactly what to delete                |

### State File Location

**Default (local):** `terraform.tfstate` in your project directory
**Remote (production):** S3 + DynamoDB (covered in Phase 3)

### NEVER Do These With State

```
❌ Edit terraform.tfstate manually (unless emergency)
❌ Commit terraform.tfstate to Git (contains sensitive data like passwords)
❌ Share a local state file between team members
❌ Delete terraform.tfstate without running destroy first
```

### Terraform State Commands

```bash
terraform state list                          # list all resources
terraform state show aws_s3_bucket.my_bucket  # show resource details
terraform state mv <old> <new>               # rename/move a resource
terraform state rm aws_s3_bucket.my_bucket   # remove from state (does NOT delete AWS resource)
terraform import aws_s3_bucket.existing my-existing-bucket  # import existing resource
```

### State Locking

When multiple people or pipelines run Terraform simultaneously without locking, you get **state corruption**.

```
Person A runs terraform apply  ──┐
                                  ├──→ Both write to state = CORRUPTION
Person B runs terraform apply  ──┘
```

**Solution:** Remote backend with state locking (DynamoDB) — covered in Phase 3.

### Terraform Refresh

```bash
terraform refresh   # syncs state with real AWS state (detects manual changes)
# Note: In Terraform >= 1.5+, refresh happens automatically during plan
```

---

## 7. Your First Terraform File

### Project Structure for Phase 1

```
phase1-basics/
├── main.tf          ← resource definitions
├── providers.tf     ← provider and version config
├── variables.tf     ← input variables
├── outputs.tf       ← output values
└── terraform.tfvars ← variable values (gitignored if sensitive)
```

### providers.tf

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Project     = var.project_name
      Environment = var.environment
    }
  }
}
```

> **Pro Tip:** `default_tags` on the provider applies tags to ALL AWS resources automatically. No need to specify tags on every resource individually.

### variables.tf

```hcl
variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "tf-learning"
}
```

### main.tf

```hcl
# Random suffix to ensure globally unique S3 bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket — Phase 1 learning resource
resource "aws_s3_bucket" "learning" {
  bucket = "${var.project_name}-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }
}
```

> **Why random_id?** S3 bucket names are globally unique across ALL AWS accounts. Adding a random suffix avoids name conflicts.

### outputs.tf

```hcl
output "bucket_id" {
  description = "The name/ID of the S3 bucket"
  value       = aws_s3_bucket.learning.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.learning.arn
}

output "bucket_region" {
  description = "The AWS region where the bucket was created"
  value       = aws_s3_bucket.learning.region
}
```

### terraform.tfvars

```hcl
region       = "us-east-1"
environment  = "dev"
project_name = "tf-learning"
```

> **Note:** Add `terraform.tfvars` to `.gitignore` if it ever contains secrets. For now it's fine to commit since it has no sensitive data.

### .gitignore

```gitignore
# Terraform state files — NEVER commit these
*.tfstate
*.tfstate.*
*.tfstate.backup

# Terraform working directory
.terraform/

# Crash logs
crash.log
crash.*.log

# Sensitive variable files
*.tfvars
*.tfvars.json
!example.tfvars    # commit example files with no real values

# Generated plan files
*.tfplan
tfplan

# Override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# macOS
.DS_Store
```

---

## 8. Commands to Execute

Run these in order from within the `phase1-basics/` directory:

```bash
# Step 1: Verify Terraform is installed
terraform version
# Expected: Terraform v1.5.x or higher

# Step 2: Initialize — downloads AWS provider
terraform init

# Step 3: Format code
terraform fmt

# Step 4: Validate syntax
terraform validate
# Expected: Success! The configuration is valid.

# Step 5: Preview what will be created
terraform plan

# Step 6: Review the plan output carefully, then apply
terraform apply
# Type: yes

# Step 7: View outputs
terraform output

# Step 8: Inspect the state file
terraform state list
terraform state show aws_s3_bucket.learning

# Step 9: Verify in AWS (optional)
aws s3 ls | grep tf-learning

# Step 10: Clean up (destroy resources)
terraform destroy
# Type: yes
```

---

## 9. Expected Output

### After `terraform init`:

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
- Installed hashicorp/aws v5.x.x (signed by HashiCorp)

Terraform has been successfully initialized!
```

### After `terraform plan`:

```
Terraform will perform the following actions:

  # aws_s3_bucket.learning will be created
  + resource "aws_s3_bucket" "learning" {
      + bucket                      = "tf-learning-dev-a1b2c3d4"
      + id                          = (known after apply)
      + arn                         = (known after apply)
      + region                      = (known after apply)
      ...
    }

  # random_id.bucket_suffix will be created
  + resource "random_id" "bucket_suffix" {
      + byte_length = 4
      + hex         = (known after apply)
      + id          = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

### After `terraform apply`:

```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn    = "arn:aws:s3:::tf-learning-dev-a1b2c3d4"
bucket_id     = "tf-learning-dev-a1b2c3d4"
bucket_region = "us-east-1"
```

### After `terraform state list`:

```
aws_s3_bucket.learning
random_id.bucket_suffix
```

---

## 10. Common Errors

### Error 1: No AWS credentials configured

```
Error: No valid credential sources found for AWS Provider.
```

**Fix:**

```bash
aws configure
# OR set environment variables:
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

---

### Error 2: S3 bucket name already exists

```
Error: creating Amazon S3 (Simple Storage) Bucket: BucketAlreadyExists
```

**Fix:** S3 bucket names are globally unique. Use `random_id` or add your account ID to the name.

---

### Error 3: Version constraint not satisfied

```
Error: Unsatisfied version constraints
This configuration requires Terraform 1.5.0 or higher
```

**Fix:** Upgrade Terraform:

```bash
# Using tfenv (recommended version manager)
tfenv install 1.9.0
tfenv use 1.9.0
```

---

### Error 4: Provider not initialized

```
Error: Could not load plugin
```

**Fix:** You forgot to run `terraform init` after adding or changing providers.

```bash
terraform init
```

---

### Error 5: Trying to create bucket in wrong region

```
Error: creating Amazon S3 Bucket: IllegalLocationConstraintException
```

**Fix:** Check your provider region and ensure consistency.

---

### Error 6: Lock file out of sync

```
Error: Required plugins are not installed
```

**Fix:**

```bash
terraform init -upgrade
```

---

## 11. Debugging Tips

### Enable verbose logging

```bash
export TF_LOG=DEBUG        # most verbose
export TF_LOG=INFO         # general info
export TF_LOG=WARN         # warnings only
export TF_LOG_PATH=./terraform.log  # write logs to file

terraform apply
```

### Check what Terraform sees

```bash
terraform console   # opens an interactive REPL
> var.environment   # prints variable value
> aws_s3_bucket.learning.arn  # inspect resource attribute
```

### Inspect the state directly

```bash
terraform show                            # human-readable state
cat terraform.tfstate | python -m json.tool  # formatted JSON
```

### Validate without AWS connection

```bash
terraform validate   # syntax only, no AWS API calls
```

### Check provider version being used

```bash
terraform version
cat .terraform.lock.hcl
```

### Refresh state to detect drift

```bash
terraform plan -refresh-only  # shows what changed outside of Terraform
```

---

## 12. Real-World Production Notes

### 1. Never use local state in teams

Local `terraform.tfstate` = one person's laptop = team disaster. Phase 3 covers remote state on S3.

### 2. Use a Terraform version manager

```bash
# Install tfenv (Terraform version manager — like nvm for Node)
# https://github.com/tfutils/tfenv
tfenv install 1.9.0
tfenv use 1.9.0
```

Teams pin Terraform versions in `required_version` to prevent version mismatch issues.

### 3. Provider version pinning is non-negotiable

```hcl
# BAD — can break on any day a new major version releases
version = ">= 3.0"

# GOOD — allows minor updates but blocks major breaking changes
version = "~> 5.0"

# BEST for critical production — exact pin
version = "5.31.0"
```

### 4. `default_tags` on the provider saves you

Without `default_tags`, every resource needs a `tags` block. Forget one → compliance violation. Set it once on the provider.

### 5. Always run `terraform fmt` before committing

Add it as a pre-commit hook:

```yaml
# .pre-commit-config.yaml (Phase 8 topic)
- repo: https://github.com/antonbabenko/pre-commit-terraform
  hooks:
    - id: terraform_fmt
    - id: terraform_validate
```

### 6. The `random` provider pattern is standard

Using `random_id` or `random_string` for globally unique resource names (S3, IAM roles, etc.) is standard practice in production modules.

### 7. terraform.tfvars vs environment variables

```bash
# Option A: tfvars file (common for non-sensitive config)
terraform apply -var-file="dev.tfvars"

# Option B: Environment variables (good for secrets in CI/CD)
export TF_VAR_db_password="supersecret"
terraform apply  # Terraform reads TF_VAR_* automatically
```

---

## 13. Mini Assignment

Complete all steps below before moving to Phase 2:

### Assignment Tasks

**Task 1 — Setup**

- [ ] Install Terraform >= 1.5 on your machine
- [ ] Verify with `terraform version`
- [ ] Install AWS CLI and configure with `aws configure`
- [ ] Verify with `aws sts get-caller-identity`

**Task 2 — Create the project**

- [ ] Create folder `phase1-basics/`
- [ ] Create all 5 files: `main.tf`, `providers.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars`
- [ ] Create `.gitignore` with proper Terraform exclusions

**Task 3 — Execute the workflow**

- [ ] Run `terraform init` — note what was downloaded
- [ ] Run `terraform fmt` — check if any files were reformatted
- [ ] Run `terraform validate` — should show "Success"
- [ ] Run `terraform plan` — read every line of the output
- [ ] Run `terraform apply` — inspect the bucket in AWS Console
- [ ] Run `terraform output` — verify all 3 outputs appear
- [ ] Run `terraform state list` — note both resources
- [ ] Run `terraform destroy` — verify bucket is gone from AWS Console

**Task 4 — Experiment**

- [ ] Change `environment` variable to `"stage"` in `terraform.tfvars`, re-apply
- [ ] Add a new output: `bucket_domain_name` (hint: check `aws_s3_bucket` docs)
- [ ] Try running `terraform apply` again on an already-applied config — observe "No changes"
- [ ] Manually delete the S3 bucket from AWS Console, then run `terraform plan` — observe drift detection

**Task 5 — Reflection Questions** (answer in your own words)

1. What is the difference between `terraform plan` and `terraform apply`?
2. What happens to `terraform.tfstate` after `terraform destroy`?
3. Why should `terraform.tfstate` never be committed to Git?
4. What does `~> 5.0` mean in a version constraint?
5. What is the purpose of the `.terraform.lock.hcl` file?

---

## Phase 1 Completion Checklist

- [ ] Understand IaC concepts and why companies use it
- [ ] Understand Terraform vs alternative tools
- [ ] Understand how Terraform works internally (DAG, state)
- [ ] Know all 4 core Terraform concepts (providers, resources, variables, outputs)
- [ ] Successfully executed: init → fmt → validate → plan → apply → destroy
- [ ] Understand terraform state and why it's critical
- [ ] Created `.gitignore` with proper Terraform exclusions
- [ ] Completed all mini assignment tasks

---

**Once complete, confirm and we'll move to Phase 2:**

> Phase 2 — AWS Provider deep-dive, AWS CLI auth methods, creating your first S3 bucket with proper configuration, encryption, versioning, and access controls.
