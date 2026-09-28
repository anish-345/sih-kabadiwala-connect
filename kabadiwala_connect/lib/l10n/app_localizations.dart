import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  String get appTitle;
  String get selectLanguage;
  String get selectRole;
  String get roleCollector;
  String get roleRecycler;
  String get scanMaterial;
  String get enterWeight;
  String get priceBoard;
  String get todaysRates;
  String get earnings;
  String get safety;
  String get createLot;
  String get confirmHandover;
  String get scanQr;
  String get takeDualPhoto;
  String get fraudWarning;
  String get fraudFlag;
  String get eprBonus;
  String get ncmmIncentive;
  String get estimatedValue;
  String get informalRate;
  String get formalRate;
  String get netPrice;
  String get lotId;
  String get category;
  String get subCategory;
  String get conditionGrade;
  String get weight;
  String get amount;
  String get status;
  String get pending;
  String get completed;
  String get cancelled;
  String get verified;
  String get loading;
  String get error;
  String get success;
  String get ok;
  String get cancel;
  String get next;
  String get back;
  String get confirm;
  String get share;
  String get download;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(_lookupAppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations _lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'hi':
      return _AppLocalizationsHi(locale);
    case 'mr':
      return _AppLocalizationsMr(locale);
    default:
      return _AppLocalizationsEn(locale);
  }
}

class _AppLocalizationsEn extends AppLocalizations {
  _AppLocalizationsEn(super.locale);

  @override String get appTitle => 'Kabadiwala Connect';
  @override String get selectLanguage => 'Select Language';
  @override String get selectRole => 'I am a...';
  @override String get roleCollector => 'Scrap Collector';
  @override String get roleRecycler => 'Authorized Recycler';
  @override String get scanMaterial => 'Scan Material';
  @override String get enterWeight => 'Enter Weight (kg)';
  @override String get priceBoard => 'Price Board';
  @override String get todaysRates => "Today's Rates";
  @override String get earnings => 'Earnings';
  @override String get safety => 'Safety Guide';
  @override String get createLot => 'Create Lot';
  @override String get confirmHandover => 'Confirm Handover';
  @override String get scanQr => 'Scan QR Code';
  @override String get takeDualPhoto => 'Take Handover Photo';
  @override String get fraudWarning => 'Unusual weight-to-size ratio — please recheck';
  @override String get fraudFlag => 'Suspicious transaction — please verify';
  @override String get eprBonus => 'EPR Credit';
  @override String get ncmmIncentive => 'NCMM Incentive';
  @override String get estimatedValue => 'Estimated Value';
  @override String get informalRate => 'Market Rate';
  @override String get formalRate => 'Recycler Rate';
  @override String get netPrice => 'Net Offered Price';
  @override String get lotId => 'Lot ID';
  @override String get category => 'Category';
  @override String get subCategory => 'Sub-Category';
  @override String get conditionGrade => 'Condition';
  @override String get weight => 'Weight';
  @override String get amount => 'Amount';
  @override String get status => 'Status';
  @override String get pending => 'Pending';
  @override String get completed => 'Completed';
  @override String get cancelled => 'Cancelled';
  @override String get verified => 'Verified';
  @override String get loading => 'Loading…';
  @override String get error => 'Error';
  @override String get success => 'Success';
  @override String get ok => 'OK';
  @override String get cancel => 'Cancel';
  @override String get next => 'Next';
  @override String get back => 'Back';
  @override String get confirm => 'Confirm';
  @override String get share => 'Share';
  @override String get download => 'Download Receipt';
}

class _AppLocalizationsHi extends AppLocalizations {
  _AppLocalizationsHi(super.locale);

  @override String get appTitle => 'कबाड़ीवाला कनेक्ट';
  @override String get selectLanguage => 'भाषा चुनें';
  @override String get selectRole => 'मैं हूँ...';
  @override String get roleCollector => 'कबाड़ी';
  @override String get roleRecycler => 'अधिकृत रिसाइकलर';
  @override String get scanMaterial => 'सामग्री स्कैन करें';
  @override String get enterWeight => 'वजन डालें (किलो)';
  @override String get priceBoard => 'भाव बोर्ड';
  @override String get todaysRates => 'आज के भाव';
  @override String get earnings => 'कमाई';
  @override String get safety => 'सुरक्षा';
  @override String get createLot => 'लॉट बनाएं';
  @override String get confirmHandover => 'हस्तांतरण की पुष्टि करें';
  @override String get scanQr => 'QR कोड स्कैन करें';
  @override String get takeDualPhoto => 'हस्तांतरण फोटो लें';
  @override String get fraudWarning => 'असामान्य वजन — कृपया जाँच करें';
  @override String get fraudFlag => 'संदिग्ध लेनदेन — सत्यापित करें';
  @override String get eprBonus => 'EPR बोनस';
  @override String get ncmmIncentive => 'NCMM प्रोत्साहन';
  @override String get estimatedValue => 'अनुमानित मूल्य';
  @override String get informalRate => 'बाज़ार दर';
  @override String get formalRate => 'रिसाइकलर दर';
  @override String get netPrice => 'शुद्ध प्रस्तावित मूल्य';
  @override String get lotId => 'लॉट आईडी';
  @override String get category => 'श्रेणी';
  @override String get subCategory => 'उप-श्रेणी';
  @override String get conditionGrade => 'स्थिति';
  @override String get weight => 'वजन';
  @override String get amount => 'राशि';
  @override String get status => 'स्थिति';
  @override String get pending => 'लंबित';
  @override String get completed => 'पूर्ण';
  @override String get cancelled => 'रद्द';
  @override String get verified => 'सत्यापित';
  @override String get loading => 'लोड हो रहा है…';
  @override String get error => 'त्रुटि';
  @override String get success => 'सफलता';
  @override String get ok => 'ठीक है';
  @override String get cancel => 'रद्द करें';
  @override String get next => 'अगला';
  @override String get back => 'पीछे';
  @override String get confirm => 'पुष्टि करें';
  @override String get share => 'साझा करें';
  @override String get download => 'रसीद डाउनलोड करें';
}

class _AppLocalizationsMr extends AppLocalizations {
  _AppLocalizationsMr(super.locale);

  @override String get appTitle => 'कबाडीवाला कनेक्ट';
  @override String get selectLanguage => 'भाषा निवडा';
  @override String get selectRole => 'मी आहे...';
  @override String get roleCollector => 'भंगार संकलक';
  @override String get roleRecycler => 'अधिकृत रिसायकलर';
  @override String get scanMaterial => 'सामग्री स्कॅन करा';
  @override String get enterWeight => 'वजन टाका (किलो)';
  @override String get priceBoard => 'भाव बोर्ड';
  @override String get todaysRates => 'आजचे भाव';
  @override String get earnings => 'कमाई';
  @override String get safety => 'सुरक्षा';
  @override String get createLot => 'लॉट तयार करा';
  @override String get confirmHandover => 'हस्तांतरणाची पुष्टी करा';
  @override String get scanQr => 'QR कोड स्कॅन करा';
  @override String get takeDualPhoto => 'हस्तांतरण फोटो घ्या';
  @override String get fraudWarning => 'असामान्य वजन — कृपया तपासा';
  @override String get fraudFlag => 'संशयास्पद व्यवहार — पडताळणी करा';
  @override String get eprBonus => 'EPR बोनस';
  @override String get ncmmIncentive => 'NCMM प्रोत्साहन';
  @override String get estimatedValue => 'अंदाजे मूल्य';
  @override String get informalRate => 'बाजार भाव';
  @override String get formalRate => 'रिसायकलर भाव';
  @override String get netPrice => 'निव्वळ प्रस्तावित भाव';
  @override String get lotId => 'लॉट आयडी';
  @override String get category => 'वर्ग';
  @override String get subCategory => 'उप-वर्ग';
  @override String get conditionGrade => 'स्थिती';
  @override String get weight => 'वजन';
  @override String get amount => 'रक्कम';
  @override String get status => 'स्थिती';
  @override String get pending => 'प्रलंबित';
  @override String get completed => 'पूर्ण';
  @override String get cancelled => 'रद्द';
  @override String get verified => 'पडताळणी झाली';
  @override String get loading => 'लोड होत आहे…';
  @override String get error => 'त्रुटी';
  @override String get success => 'यशस्वी';
  @override String get ok => 'ठीक आहे';
  @override String get cancel => 'रद्द करा';
  @override String get next => 'पुढे';
  @override String get back => 'मागे';
  @override String get confirm => 'पुष्टी करा';
  @override String get share => 'शेअर करा';
  @override String get download => 'पावती डाउनलोड करा';
}
