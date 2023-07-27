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

locals {
  format_string = one([for k, v in var.format : k if v != null])
  mode_string   = one([for k, v in var.mode : k if v != null])
}

resource "google_artifact_registry_repository" "registry" {
  provider      = google-beta
  project       = var.project_id
  location      = var.location
  description   = var.description
  format        = upper(local.format_string)
  labels        = var.labels
  repository_id = var.id
  mode          = "${upper(local.mode_string)}_REPOSITORY"
  kms_key_name  = var.encryption_key

  dynamic "remote_repository_config" {
    for_each = var.mode.remote ? [1] : []
    content {
      dynamic "docker_repository" {
        for_each = var.format.docker != null ? [1] : []
        content {
          public_repository = "DOCKER_HUB"
        }
      }

      dynamic "maven_repository" {
        for_each = var.format.maven != null ? [1] : []
        content {
          public_repository = "MAVEN_CENTRAL"
        }
      }

      dynamic "npm_repository" {
        for_each = var.format.npm != null ? [1] : []
        content {
          public_repository = "NPMJS"
        }
      }

      dynamic "python_repository" {
        for_each = var.format.python != null ? [1] : []
        content {
          public_repository = "PYPI"
        }
      }
    }
  }
}

resource "google_artifact_registry_repository_iam_binding" "bindings" {
  provider   = google-beta
  for_each   = var.iam
  project    = var.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = each.key
  members    = each.value
}
