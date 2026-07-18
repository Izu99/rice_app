import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'en_strings.dart';

/// Strings for the application with dynamic language support
class SiStrings {
  SiStrings._();

  static String _languageCode = 'si';
  static const String _langKey = 'app_language';

  /// Bumped on every language change. Screens kept alive by go_router's
  /// StatefulNavigationShell (the bottom-nav tabs) don't naturally rebuild
  /// when SiStrings changes elsewhere, so app.dart listens to this to force
  /// a full remount of the routed tree whenever the language is switched.
  static final ValueNotifier<int> languageVersion = ValueNotifier<int>(0);

  /// Initialize language from shared preferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_langKey) ?? 'si';
  }

  /// Change language and persist to disk
  static Future<void> setLanguage(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
    languageVersion.value++;
  }

  /// Toggle between English and Sinhala
  static Future<void> toggleLanguage() async {
    final nextLang = isSinhala ? 'en' : 'si';
    await setLanguage(nextLang);
  }

  static bool get isSinhala => _languageCode == 'si';

  // Helper to get the right string
  static String _get(String si, String en) => isSinhala ? si : en;

  // ==================== COMMON ACTIONS ====================
  static String get buy => _get('මිලදී ගැනීම්', EnStrings.buy);
  static String get sell => _get('විකිණීම්', EnStrings.sell);
  static String get stock => _get('තොග', EnStrings.stock);
  static String get expenses => _get('වියදම්', EnStrings.expenses);
  static String get reports => _get('වාර්තා', EnStrings.reports);
  static String get analytics => _get('විශ්ලේෂණ', EnStrings.analytics);
  static String get customers => _get('ගනුදෙනුකරුවන්', EnStrings.customers);
  static String get profile => _get('ගිණුම', EnStrings.profile);
  static String get logout => _get('ඉවත් වන්න', EnStrings.logout);
  static String get login => _get('ඇතුළු වන්න', EnStrings.login);
  static String get welcomeBack =>
      _get('නැවත සාදරයෙන් පිළිගනිමු', EnStrings.welcomeBack);
  static String get signInToContinue =>
      _get('ඉදිරියට යාමට ඇතුළු වන්න', EnStrings.signInToContinue);
  static String get usernameOrPhone =>
      _get('දුරකථන අංකය හෝ විද්‍යුත් තැපෑල', EnStrings.usernameOrPhone);
  static String get password => _get('මුරපදය', EnStrings.password);
  static String get rememberMe => _get('මතක තබා ගන්න', EnStrings.rememberMe);
  static String get forgotPassword =>
      _get('මුරපදය අමතකද?', EnStrings.forgotPassword);
  static String get resetPassword =>
      _get('මුරපදය නැවත සකසන්න', EnStrings.resetPassword);
  static String get enterPhoneForOtp => _get(
      'OTP කේතය ලබා ගැනීමට ඔබගේ දුරකථන අංකය ඇතුළත් කරන්න',
      EnStrings.enterPhoneForOtp);
  static String get paddy => _get('වී', EnStrings.paddy);
  static String get rice => _get('සහල්', EnStrings.rice);
  static String get phoneNumber => _get('දුරකථන අංකය', EnStrings.phoneNumber);
  static String get sendOtp => _get('OTP යවන්න', EnStrings.sendOtp);
  static String get enterOtp =>
      _get('OTP කේතය ඇතුළත් කරන්න', EnStrings.enterOtp);
  static String get verify => _get('තහවුරු කරන්න', EnStrings.verify);
  static String get newPassword => _get('නව මුරපදය', EnStrings.newPassword);
  static String get confirmPassword =>
      _get('මුරපදය නැවත ඇතුළත් කරන්න', EnStrings.confirmPassword);
  static String get version => _get('අනුවාදය', EnStrings.version);
  static String get history => _get('ඉතිහාසය', EnStrings.history);
  static String get registerNow =>
      _get('ලියාපදිංචි වන්න', EnStrings.registerNow);
  static String get registerPrompt =>
      _get('නව මෝලක් ලියාපදිංචි කිරීමට?', EnStrings.registerPrompt);
  static String get alreadyHaveCompany =>
      _get('දැනටමත් ලියාපදිංචි වී තිබේද?', EnStrings.alreadyHaveCompany);
  static String get registerCompany =>
      _get('මෝල ලියාපදිංචි කිරීම', EnStrings.registerCompany);
  static String get or => _get('හෝ', EnStrings.or);
  static String get signInWithGoogle =>
      _get('Google සමඟින් ඇතුල් වන්න', EnStrings.signInWithGoogle);

  // ==================== DASHBOARD / HOME ====================
  static String get todaySummary =>
      _get('අද දින සාරාංශය', EnStrings.todaySummary);
  static String get quickActions =>
      _get('කඩිනම් ක්‍රියාකාරකම්', EnStrings.quickActions);
  static String get weeklyActivity =>
      _get('සතිපතා විශ්ලේෂණය', EnStrings.weeklyActivity);
  static String get stockOverview =>
      _get('තොග විශ්ලේෂණය', EnStrings.stockOverview);
  static String get thisMonth => _get('මෙම මාසය', EnStrings.thisMonth);
  static String get recentTransactions =>
      _get('මෑත ගනුදෙනු', EnStrings.recentTransactions);
  static String get recentExpenses =>
      _get('මෑත වියදම්', EnStrings.recentExpenses);
  static String get viewAll => _get('සියල්ල බලන්න', EnStrings.viewAll);
  static String get loading => _get('පූරණය වෙමින් පවතී...', EnStrings.loading);
  static String get paddyStock => _get('වී තොගය', EnStrings.paddyStock);
  static String get riceStock => _get('සහල් තොගය', EnStrings.riceStock);
  static String get lowStockWarning =>
      _get('අඩු තොග පවතී', EnStrings.lowStockWarning);
  static String get reviewSale =>
      _get('ඇණවුම පරීක්ෂා කිරීම', EnStrings.reviewSale);
  static String get buyer => _get('පාරිභෝගිකයා (මිලදී ගන්නා)', EnStrings.buyer);
  static String get sellDetails =>
      _get('විකුණුම් විස්තර', EnStrings.sellDetails);
  static String get sellingPrice =>
      _get('විකුණුම් මිල', EnStrings.sellingPrice);
  static String get totalWeightToSell =>
      _get('විකුණන මුළු බර', EnStrings.totalWeightToSell);
  static String get completeSale =>
      _get('විකිණීම සම්පූර්ණ කරන්න', EnStrings.completeSale);
  static String get saleComplete =>
      _get('විකිණීම සාර්ථකයි!', EnStrings.saleComplete);
  static String get newSale => _get('නව විකිණීමක්', EnStrings.newSale);
  static String get backToHome =>
      _get('නැවත මුල් පිටුවට', EnStrings.backToHome);
  static String get cartSummary =>
      _get('කාඩ්පතේ සාරාංශය', EnStrings.cartSummary);
  static String get items => _get('අයිතම', EnStrings.items);
  static String get continueToCheckout =>
      _get('ගෙවීමට ඉදිරියට යන්න', EnStrings.continueToCheckout);
  static String get discardChanges =>
      _get('වෙනස්කම් ඉවත් කරන්නද?', EnStrings.discardChanges);
  static String get refreshStock =>
      _get('තොග නැවුම් කරන්න', EnStrings.refreshStock);
  static String get clearAll => _get('සියල්ල ඉවත් කරන්න', EnStrings.clearAll);
  static String get cartIsEmpty => _get('කාඩ්පත හිස් ය', EnStrings.cartIsEmpty);
  static String get bags => _get('මලු', EnStrings.bags);
  static String get available => _get('තිබෙන ප්‍රමාණය', EnStrings.available);
  static String get low => _get('අඩුයි', EnStrings.low);
  static String get all => _get('සියල්ල', EnStrings.all);
  static String get checkout => _get('ගෙවන්න', EnStrings.checkout);
  static String get searchStock =>
      _get('තොගය සොයන්න...', EnStrings.searchStock);
  static String get sortByName =>
      _get('නම අනුව පෙළගස්වන්න', EnStrings.sortByName);
  static String get sortByQuantity =>
      _get('ප්‍රමාණය අනුව පෙළගස්වන්න', EnStrings.sortByQuantity);
  static String get recentlyAdded =>
      _get('මෑතකදී එක් කළ', EnStrings.recentlyAdded);

  // ==================== ANALYTICS ====================
  static String get totalRevenue => _get('මුළු ආදායම', EnStrings.totalRevenue);
  static String get paddyPurchases =>
      _get('වී මිලදී ගැනීම්', EnStrings.paddyPurchases);
  static String get netProfit => _get('ශුද්ධ ලාභය', EnStrings.netProfit);
  static String get customerBase =>
      _get('පාරිභෝගිකයින්', EnStrings.customerBase);
  static String get salesVsPurchases =>
      _get('විකිණීම් සහ මිලදී ගැනීම්', EnStrings.salesVsPurchases);
  static String get last7Days => _get('පසුගිය දින 7', EnStrings.last7Days);
  static String get stockDistribution =>
      _get('තොග බෙදා හැරීම', EnStrings.stockDistribution);
  static String get performanceMetrics =>
      _get('කාර්ය දර්ශක', EnStrings.performanceMetrics);
  static String get millingOutput =>
      _get('කෙටීමේ ප්‍රතිදානය', EnStrings.millingOutput);
  static String get wasteRatio =>
      _get('අපතේ යාමේ අනුපාතය', EnStrings.wasteRatio);
  static String get inventoryValue =>
      _get('මුළු තොගයේ වටිනාකම', EnStrings.inventoryValue);
  static String get lowStockAlerts =>
      _get('අඩු තොග අනතුරු ඇඟවීම්', EnStrings.lowStockAlerts);
  static String get totalItemsCount =>
      _get('මුළු අයිතම ගණන', EnStrings.totalItemsCount);
  static String get filter => _get('පෙරහන', EnStrings.filter);
  static String get refresh => _get('නැවුම් කරන්න', EnStrings.refresh);

  // ==================== BUY / SELL ====================
  static String get addToStock => _get('තොගයට එක්කරන්න', EnStrings.addToStock);
  static String get addBatchToList =>
      _get('ලැයිස්තුවට එක් කරන්න', EnStrings.addBatchToList);
  static String get currentListItems =>
      _get('වත්මන් ලැයිස්තුවේ අයිතම', EnStrings.currentListItems);
  static String get unconfirmedWeights =>
      _get('තහවුරු නොකළ බර ප්‍රමාණයන්', EnStrings.unconfirmedWeights);
  static String get unaddedItemTitle =>
      _get('එකතු නොකළ අයිතමයක්', EnStrings.unaddedItemTitle);
  static String get unaddedItemMessage => _get(
      'ඔබ ඉහත ඇතුළත් කළ අයිතම විස්තර තවම ලැයිස්තුවට එකතු කර නැත. ඉදිරියට ගියහොත් එම දත්ත නැති වනු ඇත.',
      EnStrings.unaddedItemMessage);
  static String get unaddedItemConfirm =>
      _get('ඉදිරියට යන්න', EnStrings.unaddedItemConfirm);
  static String get unaddedItemCancel =>
      _get('ආපසු යන්න', EnStrings.unaddedItemCancel);
  static String get buyPaddy => _get('වී මිලදී ගැනීම', EnStrings.buyPaddy);
  static String get sellRice => _get('සහල් විකිණීම', EnStrings.sellRice);
  static String get selectCustomer =>
      _get('ගනුදෙනුකරු තෝරන්න', EnStrings.selectCustomer);
  static String get amount => _get('මුදල', EnStrings.amount);
  static String get weight => _get('බර', EnStrings.weight);
  static String get quantity => _get('ප්‍රමාණය', EnStrings.quantity);
  static String get price => _get('මිල', EnStrings.price);
  static String get total => _get('එකතුව', EnStrings.total);
  static String get variety => _get('වර්ගය', EnStrings.variety);
  static String get date => _get('දිනය', EnStrings.date);
  static String get searchHint =>
      _get('නම හෝ දුරකථන අංකයෙන් සොයන්න...', EnStrings.searchHint);
  static String get noCustomersFound =>
      _get('ගනුදෙනුකරුවන් හමු නොවීය', EnStrings.noCustomersFound);
  static String get addNewCustomer =>
      _get('නව ගනුදෙනුකරුවෙකු එක් කරන්න', EnStrings.addNewCustomer);
  static String get buyingFrom =>
      _get('මිලදී ගන්නේ කාගෙන්ද?', EnStrings.buyingFrom);
  static String get searchOrSelect =>
      _get('සොයන්න හෝ ලැයිස්තුවෙන් තෝරන්න', EnStrings.searchOrSelect);
  static String get viewProfile => _get('ගිණුම බලන්න', EnStrings.viewProfile);
  static String get name => _get('නම', EnStrings.name);
  static String get balance => _get('ශේෂය', EnStrings.balance);
  static String get totalReceivable =>
      _get('මුළු ලැබිය යුතු මුදල', EnStrings.totalReceivable);
  static String get totalPayable =>
      _get('මුළු ගෙවිය යුතු මුදල', EnStrings.totalPayable);

  // ==================== STATUS / NOTIFICATIONS ====================
  static String get success => _get('සාර්ථකයි', EnStrings.success);
  static String get error => _get('දෝෂයකි', EnStrings.error);
  static String get warning => _get('අවවාදයයි', EnStrings.warning);
  static String get syncSuccess =>
      _get('sync කිරීම සාර්ථකයි', EnStrings.syncSuccess);
  static String get syncing => _get('sync වෙමින් පවතී...', EnStrings.syncing);
  static String get pending => _get('රැඳී ඇත', EnStrings.pending);

  // ==================== DIALOGS ====================
  static String get confirm => _get('තහවුරු කරන්න', EnStrings.confirm);
  static String get cancel => _get('අවලංගු කරන්න', EnStrings.cancel);
  static String get delete => _get('මකා දමන්න', EnStrings.delete);
  static String get save => _get('සුරකින්න', EnStrings.save);
  static String get update => _get('යාවත්කාලීන කරන්න', EnStrings.update);
  static String get yes => _get('ඔව්', EnStrings.yes);
  static String get no => _get('නැත', EnStrings.no);
  static String get change => _get('වෙනස් කරන්න', EnStrings.change);
  static String get accountNotFound => _get(
      'ගිණුමක් හමු නොවීය. ලියාපදිංචි වීමට කරුණාකර පරිපාලක අමතන්න.',
      EnStrings.accountNotFound);

  // ==================== NAVIGATION ====================
  static String get home => _get('මුල් පිටුව', EnStrings.home);
  static String get dashboard => _get('ප්‍රධාන පිටුව', EnStrings.dashboard);
  static String get marketplace => _get('වෙළෙඳ පොළ', EnStrings.marketplace);
  static String get records => _get('වාර්තා', EnStrings.records);
  static String get reportsAndTools =>
      _get('වාර්තා සහ මෙවලම්', EnStrings.reportsAndTools);
  static String get transactions => _get('ගනුදෙනු', EnStrings.transactions);
  static String get milling => _get('කෙටීම', EnStrings.milling);
  static String get addPrice => _get('මිල එකතු කරන්න', EnStrings.addPrice);
  static String get dailyReport =>
      _get('දිනපතා\nවාර්තාව', EnStrings.dailyReport);
  static String get prices => _get('මිල ගණන්', EnStrings.prices);
  static String get searchFeatures =>
      _get('විශේෂාංග සොයන්න...', EnStrings.searchFeatures);

  // ==================== PROFILE ====================
  static String get profileTitle => _get('ගිණුම', EnStrings.profileTitle);
  static String get accountSettingsSubtitle =>
      _get('ගිණුම සහ සැකසුම්', EnStrings.accountSettingsSubtitle);
  static String get editProfile =>
      _get('ගිණුම යාවත්කාලීන කරන්න', EnStrings.editProfile);
  static String get editProfileSubtitle =>
      _get('නම, ඊමේල්, ඡායාරූපය වෙනස් කරන්න', EnStrings.editProfileSubtitle);
  static String get changePassword =>
      _get('මුරපදය වෙනස් කරන්න', EnStrings.changePassword);
  static String get changePasswordSubtitle =>
      _get('ඔබගේ මුරපදය යාවත්කාලීන කරන්න', EnStrings.changePasswordSubtitle);
  static String get companyInfo => _get('ආයතනයේ විස්තර', EnStrings.companyInfo);
  static String get companyInfoSubtitle =>
      _get('ආයතනයේ තොරතුරු', EnStrings.companyInfoSubtitle);
  static String get companyInfoUnavailable =>
      _get('ආයතනයේ විස්තර ලබා ගත නොහැක', EnStrings.companyInfoUnavailable);
  static String get darkMode => _get('අඳුරු තේමාව', EnStrings.darkMode);
  static String get darkModeSubtitle =>
      _get('Dark Mode සක්‍රීය කරන්න', EnStrings.darkModeSubtitle);
  static String get notificationsLabel =>
      _get('දැනුම්දීම්', EnStrings.notificationsLabel);
  static String get biometricLogin =>
      _get('Biometric Login', EnStrings.biometricLogin);
  static String get biometricSubtitle => _get(
      'ඇඟිලි සලකුණු/මුහුණ හඳුනාගැනීම භාවිතා කරන්න',
      EnStrings.biometricSubtitle);
  static String get language => _get('භාෂාව', EnStrings.language);
  static String get helpFaq => _get('උදව් සහ නිතර අසන පැණ', EnStrings.helpFaq);
  static String get helpSubtitle =>
      _get('සහාය ලබා ගන්න', EnStrings.helpSubtitle);
  static String get termsPrivacy =>
      _get('කොන්දේසි සහ රහස්‍යතාව', EnStrings.termsPrivacy);
  static String get termsSubtitle =>
      _get('අපගේ ප්‍රතිපත්ති කියවන්න', EnStrings.termsSubtitle);
  static String get sendFeedback =>
      _get('ප්‍රතිචාර එවන්න', EnStrings.sendFeedback);
  static String get feedbackSubtitle =>
      _get('අපව වැඩිදියුණු කිරීමට උදව් වන්න', EnStrings.feedbackSubtitle);
  static String get logoutSubtitle =>
      _get('ඔබගේ ගිණුමෙන් ඉවත් වන්න', EnStrings.logoutSubtitle);
  static String get lastSynced =>
      _get('අවසන් වරට sync කළේ:', EnStrings.lastSynced);
  static String get updateProfile =>
      _get('ගිණුම යාවත්කාලීන කිරීම', EnStrings.updateProfile);
  static String get email => _get('විද්‍යුත් තැපෑල', EnStrings.email);
  static String get currentPassword =>
      _get('වත්මන් මුරපදය', EnStrings.currentPassword);
  static String get passwordsDoNotMatch =>
      _get('මුරපද එකිනෙකට නොගැලපේ', EnStrings.passwordsDoNotMatch);
  static String get companyName => _get('ආයතනයේ නම', EnStrings.companyName);
  static String get address => _get('ලිපිනය', EnStrings.address);
  static String get district => _get('දිස්ත්‍රික්කය', EnStrings.district);
  static String get registrationNumber =>
      _get('ලියාපදිංචි අංකය', EnStrings.registrationNumber);
  static String get taxNumber => _get('බදු අංකය', EnStrings.taxNumber);
  static String get website => _get('වෙබ් අඩවිය', EnStrings.website);
  static String get secondaryPhone =>
      _get('අතිරේක දුරකථන අංකය', EnStrings.secondaryPhone);
  static String get selectLanguage =>
      _get('භාෂාව තෝරන්න', EnStrings.selectLanguage);
  static String get roleAdmin => _get('පරිපාලක', EnStrings.roleAdmin);
  static String get roleOperator => _get('ක්‍රියාකරු', EnStrings.roleOperator);
  static String get roleUser => _get('පරිශීලකයා', EnStrings.roleUser);
  static String get notEntered => _get('ඇතුළත් කර නැත', EnStrings.notEntered);
  static String get todayProfit => _get('අද දිනයේ ලාභය', EnStrings.todayProfit);
  static String get erpVersion =>
      _get('රයිස් මිල් ERP v1.0', EnStrings.erpVersion);
  static String get profit => _get('ලාභය', EnStrings.profit);
  static String get reportPeriod =>
      _get('වාර්තා කාල පරිමාණය', EnStrings.reportPeriod);
  static String get startDate => _get('ආරම්භ දිනය', EnStrings.startDate);
  static String get endDate => _get('අවසාන දිනය', EnStrings.endDate);
  static String get selectDate => _get('තෝරන්න', EnStrings.selectDate);
  static String get periodSummary =>
      _get('කාල පරිමාණ සාරාංශය', EnStrings.periodSummary);
  static String get totalCount => _get('මුළු ගණන', EnStrings.totalCount);
  static String get totalAmount => _get('මුළු මුදල', EnStrings.totalAmount);
  static String get printingReport =>
      _get('වාර්තා මුද්‍රණය', EnStrings.printingReport);
  static String get downloadingPdf =>
      _get('PDF බාගත කරමින්', EnStrings.downloadingPdf);
  static String get downloadingExcel =>
      _get('Excel බාගත කරමින්', EnStrings.downloadingExcel);
  static String get fromDateToDate => _get('සිට', EnStrings.fromDateToDate);
  static String get toDate => _get('දක්වා', EnStrings.toDate);

  // ==================== STOCK ====================
  static String get liveStock => _get('වත්මන් තොග', EnStrings.liveStock);
  static String get paddyStockVarieties =>
      _get('වී තොග වර්ග', EnStrings.paddyStockVarieties);
  static String get riceStockVarieties =>
      _get('සහල් තොග වර්ග', EnStrings.riceStockVarieties);

  // ==================== EXPENSES ====================
  static String get addExpense =>
      _get('වියදමක් එක් කරන්න', EnStrings.addExpense);
  static String get operationalExpenses =>
      _get('මෙහෙයුම් වියදම්', EnStrings.operationalExpenses);
  static String get totalMonthlyExpenses =>
      _get('මෙම මාසයේ මුළු වියදම', EnStrings.totalMonthlyExpenses);
  static String get hasNote => _get('සටහනක් ඇත', EnStrings.hasNote);
  static String get noExpensesFound =>
      _get('වියදම් කිසිවක් හමු නොවීය', EnStrings.noExpensesFound);
  static String get deleteExpenseConfirm =>
      _get('වියදම මකා දමන්නද?', EnStrings.deleteExpenseConfirm);
  static String get expenseRecord =>
      _get('වියදම් වාර්තාව', EnStrings.expenseRecord);

  // ==================== TRANSACTIONS ====================
  static String get transactionDetails =>
      _get('ගනුදෙනු විස්තර', EnStrings.transactionDetails);
  static String get purchaseOrder =>
      _get('මිලදී ගැනීමේ ඇණවුම', EnStrings.purchaseOrder);
  static String get salesInvoice =>
      _get('විකිණීමේ ඉන්වොයිසය', EnStrings.salesInvoice);
  static String get customerInformation =>
      _get('ගනුදෙනුකරු විස්තර', EnStrings.customerInformation);
  static String get itemsList => _get('අයිතම ලැයිස්තුව', EnStrings.itemsList);
  static String get totalWeight => _get('මුළු බර', EnStrings.totalWeight);

  // ==================== CUSTOMERS ====================
  static String get addCustomer =>
      _get('ගනුදෙනුකරු එකතු කරන්න', EnStrings.addCustomer);
  static String get editCustomer =>
      _get('ගනුදෙනුකරු සංස්කරණය', EnStrings.editCustomer);
  static String get newCustomer => _get('නව ගනුදෙනුකරු', EnStrings.newCustomer);
  static String get customersAll => _get('සියල්ල', EnStrings.customersAll);
  static String get customersSellers =>
      _get('සැපයුම්කරුවන්', EnStrings.customersSellers);
  static String get customersBuyers =>
      _get('ගැනුම්කරුවන්', EnStrings.customersBuyers);
  static String get sortByLabel => _get('අනුපිළිවෙල', EnStrings.sortByLabel);
  static String get filterLabel => _get('පෙරහන', EnStrings.filterLabel);
  static String get sortByTitle =>
      _get('පිළිවෙල සකසන්න', EnStrings.sortByTitle);
  static String get sortByDateAdded =>
      _get('එක් කළ දිනය අනුව', EnStrings.sortByDateAdded);
  static String get sortByBalanceLabel =>
      _get('ශේෂය අනුව', EnStrings.sortByBalanceLabel);
  static String get sortByNameLabel =>
      _get('නම අනුව', EnStrings.sortByNameLabel);
  static String get filtersTitle => _get('පෙරහන්', EnStrings.filtersTitle);
  static String get balanceLabel => _get('ශේෂය', EnStrings.balanceLabel);
  static String get withBalance =>
      _get('ශේෂයක් සහිත', EnStrings.withBalance);
  static String get receivable => _get('ලැබිය යුතු', EnStrings.receivable);
  static String get payable => _get('ගෙවිය යුතු', EnStrings.payable);
  static String get customerRole =>
      _get('ගනුදෙනුකරුගේ භූමිකාව', EnStrings.customerRole);
  static String get buyerLabel => _get('ගැනුම්කරු', EnStrings.buyerLabel);
  static String get sellerLabel => _get('විකුණුම්කරු', EnStrings.sellerLabel);
  static String get applyFilters =>
      _get('තහවුරු කරන්න', EnStrings.applyFilters);
  static String get errorLoadingCustomers =>
      _get('දෝෂයක් සිදු විය', EnStrings.errorLoadingCustomers);
  static String get tryAgain => _get('නැවත උත්සාහ කරන්න', EnStrings.tryAgain);
  static String get noResultsFound =>
      _get('ප්‍රතිඵල නැත', EnStrings.noResultsFound);
  static String get tryDifferentSearch =>
      _get('සෙවුම් පද වෙනස් කර නැවත උත්සාහ කරන්න',
          EnStrings.tryDifferentSearch);
  static String get clearFiltersAction =>
      _get('පෙරහන් ඉවත් කරන්න', EnStrings.clearFiltersAction);
  static String get noCustomersYet =>
      _get('ගනුදෙනුකරුවන් නැත', EnStrings.noCustomersYet);
  static String get addFirstCustomer =>
      _get('පළමු ගනුදෙනුකරු එක් කර ආරම්භ කරන්න', EnStrings.addFirstCustomer);

  // ==================== REPORTS ====================
  static String get dateRange => _get('දිනය පරාසය', EnStrings.dateRange);
  static String get day => _get('දිනය', EnStrings.day);
  static String get week => _get('සතිය', EnStrings.week);
  static String get month => _get('මාසය', EnStrings.month);
  static String get dailyReportTitle =>
      _get('දිනපතා වාර්තාව', EnStrings.dailyReportTitle);
  static String get customerReport =>
      _get('ගනුදෙනුකරු වාර්තාව', EnStrings.customerReport);
  static String get stockReport => _get('තොග වාර්තාව', EnStrings.stockReport);

  // ==================== LANDING SCREEN ====================
  static String get landingTagline => _get(
      'ඔබගේ සහල් මෝල නවීන කළමනාකරණ පද්ධතියක් සමඟ කාර්යක්ෂමව කළමනාකරණය කරන්න.',
      'Manage your rice mill efficiently with our modern management system.');
  static String get detailedDashboard =>
      _get('විස්තරාත්මක උපකරණ පුවරුව', 'Detailed Dashboard');
  static String get goToSummary => _get('සාරාංශයට යන්න', 'Go to Summary');

  // ==================== PRICE MANAGEMENT ====================
  static String get enterPriceDetails => _get('මිල ඇතුළත් කරන්න', 'Enter price details');
  static String get yourDistrict => _get('ඔබගේ දිස්ත්‍රික්කය', 'Your District');
  static String get notSet => _get('සකසා නැත', 'Not Set');
  static String get commodityType => _get('භාණ්ඩ වර්ගය', 'Commodity Type');
  static String get paddyLabel => _get('වී', 'Paddy');
  static String get riceLabel => _get('සහල්', 'Rice');
  static String get selectVariety => _get('ප්‍රභේදය තෝරන්න', 'Select variety');
  static String get minimumPriceRs => _get('අවම මිල (රු.)', 'Minimum Price (Rs.)');
  static String get maximumPriceOptionalRs =>
      _get('උපරිම මිල (රු.) — විකල්පයි', 'Maximum Price (Rs.) — Optional');
  static String get maxPriceHint =>
      _get('උදා. 118 (තනි මිලක් නම් හිස්ව තබන්න)', 'e.g., 118 (leave blank for single price)');
  static String get priceRequired => _get('මිල අවශ්‍යයි', 'Price is required');
  static String get enterValidNumber => _get('වලංගු අංකයක් ඇතුළත් කරන්න', 'Enter a valid number');
  static String get maxGreaterThanMin =>
      _get('උපරිම මිල අවම මිලට වඩා වැඩි විය යුතුය', 'Max must be greater than min price');
  static String get qualityGrade => _get('තත්ත්ව ශ්‍රේණිය', 'Quality Grade');
  static String get premium => _get('උසස්', 'Premium');
  static String get standard => _get('සාමාන්‍ය', 'Standard');
  static String get basic => _get('මූලික', 'Basic');
  static String get notesOptional => _get('සටහන් (විකල්පයි)', 'Notes (Optional)');
  static String get notesHint =>
      _get('මෙම මිල පිළිබඳ අමතර විස්තර', 'Any additional details about this price');
  static String get validMinPriceRequired =>
      _get('කරුණාකර වලංගු අවම මිලක් ඇතුළත් කරන්න', 'Please enter a valid minimum price');
  static String get failedToAddPrice => _get('මිල එකතු කිරීම අසාර්ථකයි', 'Failed to add price');
  static String get failedToLoadPrices => _get('මිල පූරණය අසාර්ථකයි', 'Failed to load prices');
  static String get addingPrice => _get('මිල එකතු කරමින්...', 'Adding price...');
  static String get marketPrices => _get('වෙළඳපොළ මිල', 'Market Prices');
  static String get districtOverview => _get('දිස්ත්‍රික් දළ විශ්ලේෂණය', 'District Overview');
  static String get selectDistrictToView =>
      _get('විස්තරාත්මක මිල බැලීමට දිස්ත්‍රික්කයක් තෝරන්න', 'Select a district to view detailed prices');
  static String get searchDistrictHint => _get('දිස්ත්‍රික්කය සොයන්න...', 'Search district...');
  static String get noDistrictsFound => _get('දිස්ත්‍රික්ක හමු නොවීය', 'No districts found');
  static String get noMarketPricesYet => _get(
      'දැනට වෙළඳපොළ මිල නොමැත. පසුව නැවත පරීක්ෂා කරන්න.',
      'There are no market prices available at the moment. Please check back later.');
  static String get noPricesListed => _get('මිල ලැයිස්තු කර නොමැත', 'No prices listed');
  static String get totalVarieties => _get('මුළු ප්‍රභේද', 'Total Varieties');
  static String get removePriceTitle => _get('මිල ඉවත් කරන්නද?', 'Remove Price?');
  static String get removePriceContent => _get(
      'මෙය ඔබගේ මිල ලැයිස්තුව ඉවත් කරයි. අනෙක් පරිශීලකයින්ට එය තවදුරටත් නොපෙනේ. ඕනෑම වේලාවක යාවත්කාලීන මිලක් නැවත එකතු කළ හැක.',
      'This will remove your price listing. Other users will no longer see it. You can add a new updated price anytime.');
  static String get remove => _get('ඉවත් කරන්න', 'Remove');

  static String priceAddedMessage(String formattedPrice) =>
      _get('මිල එකතු කරන ලදී: $formattedPrice', 'Price added: $formattedPrice');
  static String displayingPricesIn(int count, String district) => _get(
      '$district හි මිල ලැයිස්තු $count ක් පෙන්වමින්', 'Displaying $count price listings in $district');
  static String noPricesInDistrictYet(String district) => _get(
      '$district සඳහා කිසිදු සමාගමක් මිල එකතු කර නොමැත. යාවත්කාලීන සඳහා පසුව නැවත පරීක්ෂා කරන්න.',
      'No companies have added prices for $district yet. Check back soon for updates.');
  static String noDistrictsMatching(String query) => _get(
      '"$query" ට ගැලපෙන දිස්ත්‍රික්කයක් හමු නොවීය. වෙනත් නමක් උත්සාහ කරන්න.',
      'We couldn\'t find any districts matching "$query". Try a different name.');
  static String listingsCount(int count) => _get('ලැයිස්තු $count', '$count Listings');
  static String updatedTimeAgo(String timeAgo) => _get('$timeAgo පෙර යාවත්කාලීන විය', 'Updated $timeAgo');
  static String get justNowLower => _get('දැන් පමණි', 'just now');
  static String minutesAgo(int m) => _get('මිනිත්තු $m කට පෙර', '${m}m ago');
  static String hoursAgo(int h) => _get('පැය $h කට පෙර', '${h}h ago');
  static String shortDaysAgo(int d) => _get('දින $d කට පෙර', '${d}d ago');
  static String pricesInDistrictTitle(String district) => _get('$district හි මිල', 'Prices in $district');
  static String pricesAvailableCount(int count) =>
      _get('මිල $count ක් තිබේ', '$count price${count == 1 ? '' : 's'} available');
  static String noPricesFoundIn(String district) => _get('$district හි මිල හමු නොවීය', 'No prices found in $district');

  // ==================== STORE ====================
  static String get liveMarketplace => _get('සජීවී වෙළඳපොළ', 'Live Marketplace');
  static String get listingsWord => _get('ලැයිස්තු', 'Listings');
  static String get companiesWord => _get('සමාගම්', 'Companies');
  static String get districtsWord => _get('දිස්ත්‍රික්ක', 'Districts');
  static String get listYourProductsTitle =>
      _get('ඔබගේ නිෂ්පාදන ලැයිස්තු කරන්න', 'List your products');
  static String get listYourProductsSubtitle => _get(
      'අනෙක් සමාගම්වලට බැලීමට ඔබගේ සහල් සහ වී නිෂ්පාදන ලැයිස්තු කරන්න.',
      'List your rice & paddy products for other companies to see.');
  static String get addListing => _get('ලැයිස්තුවක් එකතු කරන්න', 'Add Listing');
  static String get editListing => _get('ලැයිස්තුව සංස්කරණය', 'Edit Listing');
  static String get addNewListing => _get('නව ලැයිස්තුවක්', 'Add New Listing');
  static String get updateListing => _get('ලැයිස්තුව යාවත්කාලීන කරන්න', 'Update Listing');
  static String get postListing => _get('ලැයිස්තුව පළ කරන්න', 'Post Listing');
  static String get listingUpdated => _get('ලැයිස්තුව යාවත්කාලීන විය!', 'Listing updated!');
  static String get listingAddedSuccess => _get('ලැයිස්තුව සාර්ථකව එකතු විය!', 'Listing added successfully!');
  static String get failedToUpdate => _get('යාවත්කාලීන කිරීම අසාර්ථකයි', 'Failed to update');
  static String get failedToAddListing => _get('ලැයිස්තුව එකතු කිරීම අසාර්ථකයි', 'Failed to add listing');
  static String get removeListingTitle => _get('ලැයිස්තුව ඉවත් කරන්නද?', 'Remove Listing?');
  static String get removeListingContent => _get(
      'මෙම ලැයිස්තුව ඉවත් කරනු ලැබේ. අනෙක් සමාගම්වලට එය තවදුරටත් නොපෙනේ. ඕනෑම වේලාවක නැවත එකතු කළ හැක.',
      'This listing will be removed. Other companies will no longer see it. You can add a new one anytime.');
  static String get myListing => _get('මගේ ලැයිස්තුව', 'My Listing');
  static String get noListingsFound => _get('ලැයිස්තු හමු නොවීය', 'No listings found');
  static String get beFirstToList => _get('පළමුව ලැයිස්තු කරන්න!', 'Be the first to add a listing!');
  static String get searchListingHint =>
      _get('ප්‍රභේදය, සමාගම, දිස්ත්‍රික්කය සොයන්න...', 'Search variety, company, district...');
  static String get selectCategory => _get('කරුණාකර කාණ්ඩයක් තෝරන්න', 'Please select a category');
  static String get selectDistrictErr => _get('කරුණාකර දිස්ත්‍රික්කයක් තෝරන්න', 'Please select a district');
  static String get selectDistrict => _get('දිස්ත්‍රික්කය තෝරන්න', 'Select district');
  static String get category => _get('කාණ්ඩය', 'Category');
  static String get quantityKg => _get('ප්‍රමාණය (kg)', 'Quantity (kg)');
  static String get pricePerKgRs => _get('මිල / kg (රු.)', 'Price / kg (Rs.)');
  static String get districtLabel => _get('දිස්ත්‍රික්කය', 'District');
  static String get contactPhone => _get('දුරකථනය', 'Contact Phone');
  static String get descriptionOptional => _get('විස්තරය (විකල්පයි)', 'Description (Optional)');
  static String get required => _get('අවශ්‍යයි', 'Required');
  static String get enterValidPhone => _get('වලංගු දුරකථන අංකයක් ඇතුළත් කරන්න', 'Enter valid phone number');
  static String get cannotChange => _get('(වෙනස් කළ නොහැක)', '(cannot change)');
  static String get pricePerKg => _get('kg එකකට මිල', 'Price per kg');
  static String get availableQuantity => _get('තිබෙන ප්‍රමාණය', 'Available quantity');
  static String get totalValue => _get('මුළු අගය', 'Total value');
  static String get description => _get('විස්තරය', 'Description');
  static String get contact => _get('සම්බන්ධතාව', 'Contact');
  static String get copy => _get('පිටපත් කරන්න', 'Copy');
  static String get phoneCopied => _get('දුරකථන අංකය පිටපත් විය!', 'Phone number copied!');
  static String get today => _get('අද', 'Today');
  static String get yesterday => _get('ඊයේ', 'Yesterday');
  static String get riceBranFlour => _get('හාල් කුළු / පිටි', 'Rice Bran / Flour');
  static String get otherCategory => _get('වෙනත්', 'Other');

  static String daysAgo(int days) => _get('දින $days කට පෙර', '$days days ago');
  static String postedDaysAgo(int days) => _get(
      days == 0 ? 'අද පළ කරන ලදී' : days == 1 ? 'ඊයේ පළ කරන ලදී' : 'දින $days කට පෙර පළ කරන ලදී',
      days == 0 ? 'Posted today' : days == 1 ? 'Posted yesterday' : 'Posted $days days ago');

  // ==================== LEGAL ====================
  static String get aboutTitle => _get('පිළිබඳව', 'About');
  static String get aboutBody => _get('මෙම යෙදුම පිළිබඳව.', 'About this application.');
  static String get privacyTitle => _get('පෞද්ගලිකත්ව ප්‍රතිපත්තිය', 'Privacy Policy');
  static String get privacyBody =>
      _get('පෞද්ගලිකත්ව ප්‍රතිපත්ති අන්තර්ගතය මෙහි දිස්වනු ඇත.', 'Privacy policy content will appear here.');
  static String get termsTitle => _get('නියම සහ කොන්දේසි', 'Terms & Conditions');
  static String get termsBody => _get(
      'නියම සහ කොන්දේසි අන්තර්ගතය මෙහි දිස්වනු ඇත.', 'Terms and conditions content will appear here.');
  static String get dataDeletionTitle => _get('දත්ත මකා දැමීම', 'Data Deletion');
  static String get dataDeletionBody => _get(
      'දත්ත මකා දැමීමේ ඉල්ලීම් උපදෙස් මෙහි දිස්වනු ඇත.',
      'Data deletion request instructions will appear here.');
  static String get legalInfoTitle =>
      _get('නීතිමය තොරතුරු', EnStrings.legalInfoTitle);
  static String get legalInfoSubtitle =>
      _get('නියම, පෞද්ගලිකත්වය, පිළිබඳව', EnStrings.legalInfoSubtitle);
  static String get termsUsageSubtitle =>
      _get('මෙම යෙදුම සඳහා භාවිත කොන්දේසි', EnStrings.termsUsageSubtitle);
  static String get privacyPolicySubtitle =>
      _get('අපි ඔබේ දත්ත භාවිත කරන ආකාරය', EnStrings.privacyPolicySubtitle);
  static String get aboutMenuSubtitle =>
      _get('යෙදුම් තොරතුරු සහ සංවර්ධක විස්තර', EnStrings.aboutMenuSubtitle);
  static String get deleteAccountTitle =>
      _get('ගිණුම සහ දත්ත මකන්න', EnStrings.deleteAccountTitle);
  static String get deleteAccountSubtitle =>
      _get('ඔබේ ගිණුම ස්ථිරවම ඉවත් කරන්න', EnStrings.deleteAccountSubtitle);

  // ==================== PARAMETERIZED ====================
  static String greetHello(String firstName) =>
      isSinhala ? 'Hello, $firstName' : 'Hello, $firstName';

  static String pendingCount(int count) =>
      isSinhala ? '$count රැඳී ඇත' : '$count pending';
}
