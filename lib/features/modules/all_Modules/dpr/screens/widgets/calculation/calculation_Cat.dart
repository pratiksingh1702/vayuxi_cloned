class CalculationCategory {
  final String id;
  final String label;
  final String description;
  final CategoryDetails fullDetails;

  CalculationCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.fullDetails,
  });
}

class CategoryDetails {
  final String title;
  final String formula;
  final List<RateItem> rateList;
  final List<String> howItWorks;
  final String example;

  CategoryDetails({
    required this.title,
    required this.formula,
    required this.rateList,
    required this.howItWorks,
    required this.example,
  });
}

class RateItem {
  final String desc;
  final String uom;
  final String rate;

  RateItem({
    required this.desc,
    required this.uom,
    required this.rate,
  });
}

/// ⭐ GLOBAL LIST
final List<CalculationCategory> kCalculationCategories = [
  CalculationCategory(
    id: "A",
    label: "Per Item (Fixed Rate)",
    description: "Quantity × Fixed Rate",
    fullDetails: CategoryDetails(
      title: "Option A: Quantity × Rate",
      formula: "Total Cost = Quantity × Rate",
      rateList: [
        RateItem(
          desc: "Structure Fabrication & Erection",
          uom: "kg",
          rate: "₹105",
        ),
      ],
      howItWorks: [
        "Every unit has a fixed cost",
        "Total = Quantity × Rate",
      ],
      example: "20 kg × ₹105 = ₹2100",
    ),
  ),
  CalculationCategory(
    id: "B",
    label: "Per Item × Measurement",
    description: "Qty × Size × Rate",
    fullDetails: CategoryDetails(
      title: "Option B: Qty × Size × Rate",
      formula: "Total = Qty × Size × Rate",
      rateList: [
        RateItem(
          desc: "Pipe Erection",
          uom: "inch dia",
          rate: "₹50",
        ),
      ],
      howItWorks: [
        "Cost depends on pipe length (Qty)",
        "Cost depends on pipe size (inch dia)",
      ],
      example: "10 × 2 × 50 = ₹1000",
    ),
  ),
  CalculationCategory(
    id: "C",
    label: "Per Item × Rate by Range",
    description: "Rate varies by range",
    fullDetails: CategoryDetails(
      title: "Option C: Rate × Range",
      formula: "Total = Qty × Selected Rate",
      rateList: [
        RateItem(desc: "Pump Erection (0–5 HP)", uom: "HP", rate: "₹1000"),
        RateItem(desc: "Pump Erection (6–10 HP)", uom: "HP", rate: "₹2000"),
      ],
      howItWorks: [
        "Rate depends on HP bracket",
      ],
      example: "4 Pumps (7 HP) → 2000 × 4 = ₹8000",
    ),
  ),
];
