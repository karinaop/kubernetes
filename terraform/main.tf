terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "2.25"
    }
  }
}

provider "azurerm" {
    skip_provider_registration = true
    features {
    }
}

resource "azurerm_resource_group" "rg-karina" {
    location = "eastus"
    name = "rg-karina"
}

resource "azurerm_container_registry" "acr-karina" {
  name                = "karinak8scr"
  resource_group_name = azurerm_resource_group.rg-karina.name
  location            = azurerm_resource_group.rg-karina.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks-karina" {
  name                = "aks-karina"
  location            = azurerm_resource_group.rg-karina.location
  resource_group_name = azurerm_resource_group.rg-karina.name
  dns_prefix          = "aks-karina"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2_v2"
  }

  service_principal {
    client_id = var.client
    client_secret = var.secret
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }
  }

  tags = {
    Environment = "Production"
  }
}

data "azuread_service_principal" "aks_principal" {
    application_id = var.client
}

resource "azurerm_role_assignment" "acrpull-karina" {
  scope = azurerm_container_registry.acr-karina.id
  role_definition_name = "AcrPull"
  principal_id = data.azuread_service_principal.aks_principal.id
  skip_service_principal_aad_check = true
}

variable "client" {
}

variable "secret" {
}
