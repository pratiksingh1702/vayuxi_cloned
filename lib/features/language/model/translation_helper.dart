import 'package:untitled2/features/language/service/translator.dart';

abstract class TranslationHelper {
  final Translator translator;

  TranslationHelper(this.translator);

  // Common method to get translation
  String t(String key) => translator.t(key);

  // Common translation keys (available in all modules)

  String get saveButton => t('save_button');
  String get submitButton => t('submit_button');
  String get cancelButton => t('cancel_button');
  String get deleteButton => t('delete_button');
  String get editButton => t('edit_button');
  String get viewButton => t('view_button');
  String get addButton => t('add_button');
  String get confirmButton => t('confirm_button');
  String get selectLabel => t('select_label');
  String get searchLabel => t('search_label');
  String get noResults => t('no_results_label');
  String get loading => t('loading_label');
  String get errorOccurred => t('error_occurred');
}

// Home Module Helper
class HomeTranslationHelper extends TranslationHelper {
  HomeTranslationHelper(super.translator);

  // Titles
  String get dailyEntryTitle => t('daily_entry_title');
  String get setupTitle => t('setup_title');
  String get reportTitle => t('report_title');
  String get moreTitle => t('more_title');

  // Bottom Navigation
  String get bottomNavDailyEntry => t('bottom_nav_daily_entry');
  String get bottomNavSetup => t('bottom_nav_setup');
  String get bottomNavReport => t('bottom_nav_report');
  String get bottomNavMore => t('bottom_nav_more');

  // Module Cards
  String get attendanceCard => t('attendance_card');
  String get dailyProgressCard => t('daily_progress_card');
  String get expenseCard => t('expense_card');
  String get inventoryEntryCard => t('inventory_entry_card');
  String get siteDetailsCard => t('site_details_card');
  String get rateCard => t('rate_card');
  String get manpowerDetailsCard => t('manpower_details_card');
  String get createTeamCard => t('create_team_card');
  String get dprSetupCard => t('dpr_setup_card');
  String get inventorySetupCard => t('inventory_setup_card');
  String get summaryAnalysisCard => t('summary_analysis_card');
  String get salarySlipCard => t('salary_slip_card');
  String get dprSheetsCard => t('dpr_sheets_card');
  String get expenseSheetCard => t('expense_sheet_card');
  String get attendanceSheetCard => t('attendance_sheet_card');
  String get inventorySummaryCard => t('inventory_summary_card');
  String get profileCard => t('profile_card');
  String get subscriptionCard => t('subscription_card');
  String get upcomingUpdateCard => t('upcoming_update_card');
  String get themeCard => t('theme_card');
  String get languageCard => t('language_card');
  String get helpCard => t('help_card');

  // Other Home Strings
  String get advertiseBannerText => t('advertise_banner_text');
  String get selectSiteLabel => t('select_site_label');
  String get siteNamePlaceholder => t('site_name_placeholder');
  String get selectTeamLabel => t('select_team_label');
  String get teamNamePlaceholder => t('team_name_placeholder');
  String get askAnythingHint => t('ask_anything_hint');
}

// Report Module Helper
class ReportTranslationHelper extends TranslationHelper {
  ReportTranslationHelper(super.translator);

  // Titles
  String get plSummaryTitle => t('title_pl_summary');
  String get profitReportTitle => t('title_profit_report');
  String get inventoryReportTitle => t('title_inventory_report');
  String get dprSheetTitle => t('title_dpr_sheet');
  String get salarySlipTitle => t('title_salary_slip');

  // Labels
  String get inputTextLabel => t('label_input_text');
  String get siteLabel => t('label_site');
  String get lossPercentageLabel => t('label_loss_percentage');
  String get monthOctoberLabel => t('label_month_october');
  String get profitablePeriodLabel => t('label_profitable_period');
  String get netProfitLabel => t('label_net_profit');
  String get incomeVsExpensesLabel => t('label_income_vs_expenses');
  String get financialDistributionLabel => t('label_financial_distribution');
  String get fromLabel => t('label_from');
  String get toLabel => t('label_to');
  String get dateLabel => t('label_date');
  String get materialUsedLabel => t('label_material_used');
  String get itemLabel => t('label_item');
  String get quantityLabel => t('label_quantity');
  String get uomLabel => t('label_uom');
  String get remarkLabel => t('label_remark');
  String get fullNameLabel => t('label_full_name');
  String get employeeCodeLabel => t('label_employee_code');
  String get monthLabel => t('label_month');
  String get yearLabel => t('label_year');

  // Buttons
  String get downloadButton => t('button_download');
  String get viewButton => t('button_view');
  String get downloadSheetButton => t('button_download_sheet');
  String get saveSubmitButton => t('button_save_submit');
  String get downloadAllButton => t('button_download_all');

  // Dialog Options
  String get dialogAttendanceSheet => t('dialog_attendance_sheet');
  String get dialogShare => t('dialog_share');
  String get dialogDownload => t('dialog_download');
  String get dialogCancel => t('dialog_cancel');

  // Messages
  String get sheetDownloadedMessage => t('message_sheet_downloaded');
  String get salarySlipDownloadedMessage => t('message_salary_slip_downloaded');

  // Sheet Types
  String get measurementSheet => t('label_measurement_sheet');
  String get calculationSheet => t('label_calculation_sheet');
  String get summarySheet => t('label_summary_sheet');
  String get invoiceSheet => t('label_invoice');
  String get descriptionSheet => t('label_description_sheet');

  // Categories
  String get selectCategoryTitle => t('title_select_category');
  String get downloadIndividual => t('label_download_individual');
  String get downloadSiteWise => t('label_download_site_wise');
  String get selectRangeTitle => t('title_select_range');
}

// Setup Module Helper
class SetupTranslationHelper extends TranslationHelper {
  SetupTranslationHelper(super.translator);

  // Titles
  String get dprSetupTitle => t('setup_dpr.dpr_title');
  String get manpowerTitle => t('setup_manpower_team_inventory.manpower_title');
  String get teamTitle => t('setup_manpower_team_inventory.team_title');
  String get inventoryTitle => t('setup_manpower_team_inventory.inventory_title');
  String get siteTitle => t('setup_site_and_rate.site_title');
  String get rateTitle => t('setup_site_and_rate.rate_title');

  // Common Setup Strings
  String get viewDetailsTitle => t('view_details_title');
  String get editDetailsTitle => t('edit_details_title');
  String get addDetailsButton => t('add_details_button');
  String get viewSheetButton => t('view_sheet_button');
  String get noRecordFound => t('no_record_found');
  String get resetButton => t('reset_button');
  String get uploadPhotoLabel => t('upload_photo_label');
  String get selectFileLabel => t('select_file_label');

  // DPR Setup
  String get selectCategoryTitle => t('setup_dpr.select_category_title');
  String get categoryMoc => t('setup_dpr.category_moc');
  String get categoryFloor => t('setup_dpr.category_floor');
  String get categoryDpr => t('setup_dpr.category_dpr');
  String get allMaterialTitle => t('setup_dpr.all_material_title');
  String get addMaterialTitle => t('setup_dpr.add_material_title');
  String get editMaterialTitle => t('setup_dpr.edit_material_title');

  // Site and Rate
  String get viewSiteDetailsTitle => t('setup_site_and_rate.view_site_details_title');
  String get editSiteDetailsTitle => t('setup_site_and_rate.edit_site_details_title');
  String get deleteSiteTitle => t('setup_site_and_rate.delete_site_title');
  String get addSiteDetailsTitle => t('setup_site_and_rate.add_site_details_title');
  String get viewRateDetailsTitle => t('setup_site_and_rate.view_rate_details_title');
  String get editRateDetailsTitle => t('setup_site_and_rate.edit_rate_details_title');
}

// Daily Entry Module Helper
class DailyEntryTranslationHelper extends TranslationHelper {
  DailyEntryTranslationHelper(super.translator);

  // -------------------- TITLES --------------------
  String get selectSiteTitle => t('select_site_title');
  String get selectTeamTitle => t('select_team_title');
  String get recordAttendanceTitle => t('record_attendance_title');
  String get editAttendanceTitle => t('edit_attendance_title');
  String get dailyReportTitle => t('daily_report_title');
  String get expenseCategoryTitle => t('expense_category_title');
  String get inventoryUsageTitle => t('inventory_usage_title');

  // -------------------- STATUS --------------------
  String get editingStatus => t('editing_status');

  // -------------------- BUTTONS --------------------
  String get saveAttendanceButton => t('save_attendance_button');
  String get backButton => t('back_button');
  String get showButton => t('show_button');
  String get saveSubmitButton => t('save_submit_button');
  String get recordUsageButton => t('record_usage_button');

  // -------------------- DATE / DPR --------------------
  String get chooseDateToEdit => t('choose_date_to_edit');
  String get selectDprLabel => t('select_dpr_label');

  // -------------------- INPUT TITLES --------------------
  String get chooseMocTitle => t('choose_moc_title');
  String get chooseFloorTitle => t('choose_floor_title');
  String get enterSizeTitle => t('enter_size_title');

  // -------------------- INPUT LABELS --------------------
  String get selectInchLabel => t('select_inch_label');
  String get enterSizeLabel => t('enter_size_label');
  String get workDescriptionLabel => t('work_description_label');
  String get dateLabel => t('date_label');
  String get descriptionLabel => t('description_label');
  String get invoiceNumberLabel => t('invoice_number_label');
  String get quantityLabel => t('quantity_label');
  String get uomLabel => t('uom_label');
  String get rateLabel => t('rate_label');
  String get amountLabel => t('amount_label');
  String get remarkOptionalLabel => t('remark_optional_label');
  String get selectEmployeeLabel => t('select_employee_label');

  // -------------------- TABS --------------------
  String get plantTab => t('plant_tab');
  String get locationTab => t('location_tab');
  String get mocTab => t('moc_tab');
  String get sizeTab => t('size_tab');
  String get equipmentTab => t('equipment_tab');
  String get pipeFittingsTab => t('pipe_fittings_tab');

  // -------------------- MATERIAL LABELS --------------------
  String get equipmentMaterialLabel => t('equipment_material_label');
  String get pipeFittingMaterialLabel => t('pipe_fitting_material_label');

  // -------------------- EXPENSE CATEGORIES --------------------
  String get materialToolsCategory => t('material_tools_category');
  String get travelCategory => t('travel_category');
  String get foodCategory => t('food_category');
  String get accommodationCategory => t('accommodation_category');
  String get advanceCategory => t('advance_category');
  String get miscellaneousCategory => t('miscellaneous_category');

  // -------------------- EXPENSE TITLES --------------------
  String get addMaterialExpenseTitle => t('add_material_expense_title');
  String get addTravelExpenseTitle => t('add_travel_expense_title');
  String get addFoodExpenseTitle => t('add_food_expense_title');
  String get addAccommodationExpenseTitle => t('add_accommodation_expense_title');
  String get advanceExpenseDetailsTitle => t('advance_expense_details_title');
  String get addMiscellaneousExpenseTitle => t('add_miscellaneous_expense_title');

  // -------------------- INVENTORY --------------------
  String get selectInventoryItemLabel => t('select_inventory_item_label');
  String get unitOfMeasureLabel => t('unit_of_measure_label');
  String get quantityToUseLabel => t('quantity_to_use_label');

  // -------------------- HARDWARE --------------------
  String get hardwareShopLabel => t('hardware_shop_label');
}

// Settings Module Helper
class SettingsTranslationHelper extends TranslationHelper {
  SettingsTranslationHelper(super.translator);

  // Titles
  String get moreTitle => t('setting_profile_and_subscription.page_title_more');
  String get plansBillingTitle => t('setting_profile_and_subscription.plans_billing_title');
  String get choosePlanTitle => t('setting_profile_and_subscription.choose_plan_title');
  String get themeSettingsTitle => t('setting_theme_language_help.title_theme_settings');
  String get chooseLanguageTitle => t('setting_theme_language_help.title_choose_language');

  // Menu Items
  String get menuProfile => t('setting_profile_and_subscription.menu_profile');
  String get menuSubscription => t('setting_profile_and_subscription.menu_subscription');
  String get menuUpcomingUpdate => t('setting_profile_and_subscription.menu_upcoming_update');
  String get menuTheme => t('setting_profile_and_subscription.menu_theme');
  String get menuLanguage => t('setting_profile_and_subscription.menu_language');
  String get menuHelp => t('setting_profile_and_subscription.menu_help');

  // Profile
  String get profileFullName => t('setting_profile_and_subscription.profile_full_name');
  String get profileEmail => t('setting_profile_and_subscription.profile_email');
  String get profilePhoneNumber => t('setting_profile_and_subscription.profile_phone_number');
  String get bankDetailsTitle => t('setting_profile_and_subscription.bank_details_title');

  // Buttons
  String get buttonLogout => t('setting_profile_and_subscription.button_logout');
  String get startTrial => t('setting_profile_and_subscription.start_trial');
  String get upgradeStandard => t('setting_profile_and_subscription.upgrade_standard');
  String get upgradePremium => t('setting_profile_and_subscription.upgrade_premium');
}

// Landing Screen Helper
class LandingTranslationHelper extends TranslationHelper {
  LandingTranslationHelper(super.translator);

  // Titles
  String get welcomeTitle => t('landing_screen.welcome_title');
  String get registerTitle => t('landing_screen.register_title');
  String get selectCategoryTitle => t('landing_screen.select_category_title');

  // Messages
  String get congratsConstructionMessage => t('landing_screen.congrats_construction_message');
  String get planWorkTitle => t('landing_screen.plan_work_title');
  String get workGuideTitle => t('landing_screen.work_guide_title');

  // Labels
  String get emailLabel => t('landing_screen.email_label');
  String get firstNameLabel => t('landing_screen.first_name_label');
  String get phoneNumberLabel => t('landing_screen.phone_number_label');
  String get gstinLabel => t('landing_screen.gstin_label');

  // Buttons
  String get loginButton => t('landing_screen.login_button');
  String get registerButton => t('landing_screen.register_button');
  String get loginAsManpowerButton => t('landing_screen.login_as_manpower_button');

  // Tabs
  String get loginTab => t('landing_screen.login_tab');
  String get registerTab => t('landing_screen.register_tab');
}