import 'package:shared_preferences/shared_preferences.dart';
import 'en_strings.dart';

/// Strings for the application with dynamic language support
class SiStrings {
  SiStrings._();

  static String _languageCode = 'si';
  static const String _langKey = 'app_language';

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

  // ==================== PARAMETERIZED ====================
  static String greetHello(String firstName) =>
      isSinhala ? 'Hello, $firstName' : 'Hello, $firstName';

  static String pendingCount(int count) =>
      isSinhala ? '$count රැඳී ඇත' : '$count pending';
}
