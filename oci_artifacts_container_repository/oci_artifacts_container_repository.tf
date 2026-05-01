# resource "oci_artifacts_container_repository" "homepage-80_platform_linux-x86_64" {
#   # Required
#   compartment_id = var.compartment_id
#   display_name   = "homepage-80_platform_linux-x86_64"

#   # Optional
#   # defined_tags  = { "K8S.Apps" = "Free" }
#   # freeform_tags = { "K8S" = "Free Apps" }
#   is_immutable = false
#   is_public    = false
#   readme {
#     # Required
#     content = "Image repository with _**x86_64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
#     format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
#   }

# }

resource "oci_artifacts_container_repository" "homepage-80_platform_linux-arm64" {
  # Required
  compartment_id = var.compartment_id
  display_name   = "homepage-80_platform_linux-arm64"

  # Optional
  # defined_tags  = { "K8S.Apps" = "Free" }
  # freeform_tags = { "K8S" = "Free Apps" }
  is_immutable = false
  is_public    = false
  readme {
    # Required
    content = "Image repository with _**arm64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
    format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
  }

}

# Namespace: oci-devops applications
# resource "oci_artifacts_container_repository" "udp-health-check-server-1700_platform_linux-x86_64" {
#   # Required
#   compartment_id = var.compartment_id
#   display_name   = "udp-health-check-server-1700_platform_linux-x86_64"

#   # Optional
#   # defined_tags  = { "K8S.Apps" = "Free" }
#   # freeform_tags = { "K8S" = "Free Apps" }
#   is_immutable = false
#   is_public    = false
#   readme {
#     # Required
#     content = "Image repository with _**x86_64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
#     format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
#   }

# }

resource "oci_artifacts_container_repository" "udp-health-check-server-1700_platform_linux-arm64" {
  # Required
  compartment_id = var.compartment_id
  display_name   = "udp-health-check-server-1700_platform_linux-arm64"

  # Optional
  # defined_tags  = { "K8S.Apps" = "Free" }
  # freeform_tags = { "K8S" = "Free Apps" }
  is_immutable = false
  is_public    = false
  readme {
    # Required
    content = "Image repository with _**arm64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
    format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
  }

}

# resource "oci_artifacts_container_repository" "udp-health-check-server-1710_platform_linux-x86_64" {
#   # Required
#   compartment_id = var.compartment_id
#   display_name   = "udp-health-check-server-1710_platform_linux-x86_64"

#   # Optional
#   # defined_tags  = { "K8S.Apps" = "Free" }
#   # freeform_tags = { "K8S" = "Free Apps" }
#   is_immutable = false
#   is_public    = false
#   readme {
#     # Required
#     content = "Image repository with _**x86_64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
#     format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
#   }

# }

resource "oci_artifacts_container_repository" "udp-health-check-server-1710_platform_linux-arm64" {
  # Required
  compartment_id = var.compartment_id
  display_name   = "udp-health-check-server-1710_platform_linux-arm64"

  # Optional
  # defined_tags  = { "K8S.Apps" = "Free" }
  # freeform_tags = { "K8S" = "Free Apps" }
  is_immutable = false
  is_public    = false
  readme {
    # Required
    content = "Image repository with _**arm64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
    format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
  }

}

# Namespace: adailsilva-apps applications
# resource "oci_artifacts_container_repository" "spring-boot-app_platform_linux-x86_64" {
#   # Required
#   compartment_id = var.compartment_id
#   display_name   = "spring-boot-app_platform_linux-x86_64"

#   # Optional
#   # defined_tags  = { "K8S.Apps" = "Free" }
#   # freeform_tags = { "K8S" = "Free Apps" }
#   is_immutable = false
#   is_public    = false
#   readme {
#     # Required
#     content = "Image repository with _**x86_64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
#     format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
#   }

# }

resource "oci_artifacts_container_repository" "spring-boot-app_platform_linux-arm64" {
  # Required
  compartment_id = var.compartment_id
  display_name   = "spring-boot-app_platform_linux-arm64"

  # Optional
  # defined_tags  = { "K8S.Apps" = "Free" }
  # freeform_tags = { "K8S" = "Free Apps" }
  is_immutable = false
  is_public    = false
  readme {
    # Required
    content = "Image repository with _**arm64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
    format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
  }

}

# resource "oci_artifacts_container_repository" "cardscontrol-backend_platform_linux-x86_64" {
#   # Required
#   compartment_id = var.compartment_id
#   display_name   = "cardscontrol-backend_platform_linux-x86_64"

#   # Optional
#   # defined_tags  = { "K8S.Apps" = "Free" }
#   # freeform_tags = { "K8S" = "Free Apps" }
#   is_immutable = false
#   is_public    = false
#   readme {
#     # Required
#     content = "Image repository with _**x86_64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
#     format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
#   }

# }

resource "oci_artifacts_container_repository" "cardscontrol-backend_platform_linux-arm64" {
  # Required
  compartment_id = var.compartment_id
  display_name   = "cardscontrol-backend_platform_linux-arm64"

  # Optional
  # defined_tags  = { "K8S.Apps" = "Free" }
  # freeform_tags = { "K8S" = "Free Apps" }
  is_immutable = false
  is_public    = false
  readme {
    # Required
    content = "Image repository with _**arm64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
    format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
  }

}

# resource "oci_artifacts_container_repository" "cardscontrol-frontend_platform_linux-x86_64" {
#   # Required
#   compartment_id = var.compartment_id
#   display_name   = "cardscontrol-frontend_platform_linux-x86_64"

#   # Optional
#   # defined_tags  = { "K8S.Apps" = "Free" }
#   # freeform_tags = { "K8S" = "Free Apps" }
#   is_immutable = false
#   is_public    = false
#   readme {
#     # Required
#     content = "Image repository with _**x86_64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
#     format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
#   }

# }

resource "oci_artifacts_container_repository" "cardscontrol-frontend_platform_linux-arm64" {
  # Required
  compartment_id = var.compartment_id
  display_name   = "cardscontrol-frontend_platform_linux-arm64"

  # Optional
  # defined_tags  = { "K8S.Apps" = "Free" }
  # freeform_tags = { "K8S" = "Free Apps" }
  is_immutable = false
  is_public    = false
  readme {
    # Required
    content = "Image repository with _**arm64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
    format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
  }

}

# resource "oci_artifacts_container_repository" "stockcontrol-backend_platform_linux-x86_64" {
#   # Required
#   compartment_id = var.compartment_id
#   display_name   = "stockcontrol-backend_platform_linux-x86_64"

#   # Optional
#   # defined_tags  = { "K8S.Apps" = "Free" }
#   # freeform_tags = { "K8S" = "Free Apps" }
#   is_immutable = false
#   is_public    = false
#   readme {
#     # Required
#     content = "Image repository with _**x86_64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
#     format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
#   }

# }

resource "oci_artifacts_container_repository" "stockcontrol-backend_platform_linux-arm64" {
  # Required
  compartment_id = var.compartment_id
  display_name   = "stockcontrol-backend_platform_linux-arm64"

  # Optional
  # defined_tags  = { "K8S.Apps" = "Free" }
  # freeform_tags = { "K8S" = "Free Apps" }
  is_immutable = false
  is_public    = false
  readme {
    # Required
    content = "Image repository with _**arm64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
    format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
  }

}

# resource "oci_artifacts_container_repository" "stockcontrol-frontend_platform_linux-x86_64" {
#   # Required
#   compartment_id = var.compartment_id
#   display_name   = "stockcontrol-frontend_platform_linux-x86_64"

#   # Optional
#   # defined_tags  = { "K8S.Apps" = "Free" }
#   # freeform_tags = { "K8S" = "Free Apps" }
#   is_immutable = false
#   is_public    = false
#   readme {
#     # Required
#     content = "Image repository with _**x86_64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
#     format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
#   }

# }

resource "oci_artifacts_container_repository" "stockcontrol-frontend_platform_linux-arm64" {
  # Required
  compartment_id = var.compartment_id
  display_name   = "stockcontrol-frontend_platform_linux-arm64"

  # Optional
  # defined_tags  = { "K8S.Apps" = "Free" }
  # freeform_tags = { "K8S" = "Free Apps" }
  is_immutable = false
  is_public    = false
  readme {
    # Required
    content = "Image repository with _**arm64 architecture**_ for k8s-on-arm-oci-always-free Cluster."
    format  = "text/markdown" #"text/plain" # Supported formats are text/plain and text/markdown.
  }

}