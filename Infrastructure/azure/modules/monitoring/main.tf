# =============================================================================
# AZURE MONITORING MODULE
# Log Analytics, Application Insights, Alerts
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

# ---------------------------------------------------------------------------
# Log Analytics Workspace
# ---------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.retention_in_days

  daily_quota_gb                     = var.daily_quota_gb
  internet_ingestion_enabled         = true
  internet_query_enabled             = true
  reservation_capacity_in_gb_per_day = var.log_analytics_sku == "CapacityReservation" ? var.reservation_capacity : null

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Log Analytics Solutions
# ---------------------------------------------------------------------------

resource "azurerm_log_analytics_solution" "container_insights" {
  count = var.enable_container_insights ? 1 : 0

  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.tags
}

resource "azurerm_log_analytics_solution" "security_insights" {
  count = var.enable_security_insights ? 1 : 0

  solution_name         = "SecurityInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Application Insights
# ---------------------------------------------------------------------------

resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = var.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = var.app_insights_type

  retention_in_days                     = var.app_insights_retention_days
  daily_data_cap_in_gb                  = var.app_insights_daily_cap_gb
  daily_data_cap_notifications_disabled = false
  disable_ip_masking                    = false
  sampling_percentage                   = var.app_insights_sampling_percentage

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Action Groups
# ---------------------------------------------------------------------------

resource "azurerm_monitor_action_group" "critical" {
  name                = "${var.prefix}-critical-ag"
  resource_group_name = var.resource_group_name
  short_name          = "Critical"

  dynamic "email_receiver" {
    for_each = var.alert_email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email
      use_common_alert_schema = true
    }
  }

  dynamic "sms_receiver" {
    for_each = var.alert_sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.alert_webhook_receivers
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = true
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_action_group" "warning" {
  name                = "${var.prefix}-warning-ag"
  resource_group_name = var.resource_group_name
  short_name          = "Warning"

  dynamic "email_receiver" {
    for_each = var.alert_email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email
      use_common_alert_schema = true
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Metric Alerts for AKS
# ---------------------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "aks_cpu" {
  count = var.enable_aks_alerts ? 1 : 0

  name                = "${var.prefix}-aks-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Alert when AKS CPU usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.warning.id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "aks_memory" {
  count = var.enable_aks_alerts ? 1 : 0

  name                = "${var.prefix}-aks-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Alert when AKS memory usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.warning.id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "aks_node_not_ready" {
  count = var.enable_aks_alerts ? 1 : 0

  name                = "${var.prefix}-aks-node-not-ready-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Alert when AKS nodes are not ready"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "kube_node_status_condition"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0

    dimension {
      name     = "status2"
      operator = "Include"
      values   = ["NotReady"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Metric Alerts for MySQL
# ---------------------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "mysql_cpu" {
  count = var.enable_mysql_alerts ? 1 : 0

  name                = "${var.prefix}-mysql-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.mysql_server_id]
  description         = "Alert when MySQL CPU usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.warning.id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "mysql_storage" {
  count = var.enable_mysql_alerts ? 1 : 0

  name                = "${var.prefix}-mysql-storage-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.mysql_server_id]
  description         = "Alert when MySQL storage is running low"
  severity            = 2
  frequency           = "PT15M"
  window_size         = "PT1H"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.warning.id
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Log Query Alerts
# ---------------------------------------------------------------------------

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "container_restarts" {
  count = var.enable_container_insights ? 1 : 0

  name                 = "${var.prefix}-container-restarts-alert"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "Alert when containers are restarting frequently"
  severity             = 2
  scopes               = [azurerm_log_analytics_workspace.main.id]
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"

  criteria {
    query = <<-QUERY
      KubePodInventory
      | where TimeGenerated > ago(15m)
      | where PodRestartCount > 5
      | summarize RestartCount = sum(PodRestartCount) by Name, Namespace
      | where RestartCount > 10
    QUERY

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.warning.id]
  }

  tags = var.tags

  depends_on = [
    azurerm_log_analytics_workspace.main,
    azurerm_log_analytics_solution.container_insights
  ]
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "error_logs" {
  count = var.enable_application_insights ? 1 : 0

  name                 = "${var.prefix}-error-logs-alert"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "Alert when there are many application errors"
  severity             = 2
  scopes               = [azurerm_log_analytics_workspace.main.id]
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"

  criteria {
    query = <<-QUERY
      AppExceptions
      | where TimeGenerated > ago(15m)
      | summarize ErrorCount = count() by AppRoleName
      | where ErrorCount > 50
    QUERY

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.warning.id]
  }

  tags = var.tags

  depends_on = [
    azurerm_log_analytics_workspace.main,
    azurerm_application_insights.main
  ]

  lifecycle {
    ignore_changes = [
      target_resource_types,
    ]
  }
}

# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------

resource "azurerm_portal_dashboard" "main" {
  count = var.create_dashboard ? 1 : 0

  name                = "${var.prefix}-dashboard"
  resource_group_name = var.resource_group_name
  location            = var.location
  dashboard_properties = templatefile("${path.module}/dashboard.json.tpl", {
    subscription_id     = var.subscription_id
    resource_group_name = var.resource_group_name
    workspace_id        = azurerm_log_analytics_workspace.main.id
    aks_cluster_id      = var.aks_cluster_id
  })

  tags = var.tags
}
