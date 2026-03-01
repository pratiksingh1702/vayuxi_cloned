enum TemplateModel {
  inventory,
  site,
  manpower,
  rate,
}

extension TemplateModelX on TemplateModel {
  String get apiValue {
    switch (this) {
      case TemplateModel.inventory:
        return "inventory";
      case TemplateModel.site:
        return "site";
      case TemplateModel.manpower:
        return "manpower";

      case TemplateModel.rate:
        return "rate";
    }
  }

  String get fileName {
    switch (this) {
      case TemplateModel.inventory:
        return "inventory_template.csv";

      case TemplateModel.site:
        return "site_template.xlsx";
      case TemplateModel.manpower:
        return "manpower_template.xlsx";
      case TemplateModel.rate:
        return "rate_template.csv";
    }
  }

  String get title {
    switch (this) {
      case TemplateModel.inventory:
        return "Inventory Template";
      case TemplateModel.site:
        return "Site Template";
      case TemplateModel.manpower:
        return "Manpower Template";
      case TemplateModel.rate:
        return "Rate Template";
    }
  }
}
