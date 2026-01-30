# modules/budget/main.tf

resource "azurerm_monitor_action_group" "budget_alert" {
  name                = "budget"
  resource_group_name = var.resource_group_name
  short_name          = "bugetalert"

  email_receiver {
    name          = "sendtoadmin"
    email_address = "tel.woolsey@gmail.com"
  }
}

resource "azurerm_consumption_budget_resource_group" "budget_notification" {
  name              = "notifications"
  resource_group_id = var.resource_group_id
  amount            = 50
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-02-01T00:00:00Z"
    end_date   = "2022-07-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 50.0
    operator       = "GraterThan"
    threshold_type = "Forecasted"

    contact_emails = azurerm_monitor_action_group.budget_alert.email_receiver
  }

  notification {
    enabled        = true
    threshold      = 80.0
    operator       = "GraterThan"
    threshold_type = "Forecasted"

    contact_emails = azurerm_monitor_action_group.budget_alert.email_receiver
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GraterThan"
    threshold_type = "Forecasted"

    contact_emails = azurerm_monitor_action_group.budget_alert.email_receiver
  }
}