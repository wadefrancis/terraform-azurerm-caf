# naming convention
resource "azurecaf_name" "s2s_gateway" {
  count = var.virtual_hub_config.deploy_s2s ? 1 : 0

  name          = try(var.virtual_hub_config.s2s_config.name, null)
  resource_type = "azurerm_virtual_network_gateway"
  prefixes      = var.global_settings.prefixes
  random_length = var.global_settings.random_length
  clean_input   = true
  passthrough   = var.global_settings.passthrough
  use_slug      = var.global_settings.use_slug
}

## create the VPN S2S if var.vwan.s2s_gateway is set to true
resource "azurerm_vpn_gateway" "s2s_gateway" {
  depends_on = [azurerm_virtual_hub.vwan_hub]
  count      = var.virtual_hub_config.deploy_s2s ? 1 : 0

  name                = azurecaf_name.s2s_gateway.0.result
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
  virtual_hub_id      = azurerm_virtual_hub.vwan_hub.id

  scale_unit = var.virtual_hub_config.s2s_config.scale_unit

  dynamic "bgp_settings" {
    for_each = lookup(var.virtual_hub_config.s2s_config, "bgp_settings", {}) != {} ? [1] : []

    content {
      asn         = var.virtual_hub_config.s2s_config.bgp_settings.asn
      peer_weight = var.virtual_hub_config.s2s_config.bgp_settings.peer_weight
    }
  }

  timeouts {
    create = "60m"
    delete = "120m"
  }
}