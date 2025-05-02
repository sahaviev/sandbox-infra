locals {
  service_labels = merge(
    {
      service = "${var.name_prefix}-service-selector"
    },
    var.labels
  )
}
