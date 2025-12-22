import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Hotel Booking'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get loginWithGoogle;

  /// No description provided for @loginWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Login with Facebook'**
  String get loginWithFacebook;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @searchHotels.
  ///
  /// In en, this message translates to:
  /// **'Search Hotels'**
  String get searchHotels;

  /// No description provided for @popularDestinations.
  ///
  /// In en, this message translates to:
  /// **'Popular Destinations'**
  String get popularDestinations;

  /// No description provided for @featuredHotels.
  ///
  /// In en, this message translates to:
  /// **'Featured Hotels'**
  String get featuredHotels;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter full name'**
  String get fullNameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get phoneRequired;

  /// No description provided for @hotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get hotels;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @hotelManagement.
  ///
  /// In en, this message translates to:
  /// **'Hotel Management'**
  String get hotelManagement;

  /// No description provided for @roomManagement.
  ///
  /// In en, this message translates to:
  /// **'Room Management'**
  String get roomManagement;

  /// No description provided for @bookingManagement.
  ///
  /// In en, this message translates to:
  /// **'Booking Management'**
  String get bookingManagement;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @promotionManagement.
  ///
  /// In en, this message translates to:
  /// **'Promotion Management'**
  String get promotionManagement;

  /// No description provided for @addHotel.
  ///
  /// In en, this message translates to:
  /// **'Add Hotel'**
  String get addHotel;

  /// No description provided for @addRoom.
  ///
  /// In en, this message translates to:
  /// **'Add Room'**
  String get addRoom;

  /// No description provided for @addPromotion.
  ///
  /// In en, this message translates to:
  /// **'Add Promotion'**
  String get addPromotion;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @editHotel.
  ///
  /// In en, this message translates to:
  /// **'Edit Hotel'**
  String get editHotel;

  /// No description provided for @editRoom.
  ///
  /// In en, this message translates to:
  /// **'Edit Room'**
  String get editRoom;

  /// No description provided for @editPromotion.
  ///
  /// In en, this message translates to:
  /// **'Edit Promotion'**
  String get editPromotion;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @deleteHotel.
  ///
  /// In en, this message translates to:
  /// **'Delete Hotel'**
  String get deleteHotel;

  /// No description provided for @deleteRoom.
  ///
  /// In en, this message translates to:
  /// **'Delete Room'**
  String get deleteRoom;

  /// No description provided for @deletePromotion.
  ///
  /// In en, this message translates to:
  /// **'Delete Promotion'**
  String get deletePromotion;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get areYouSureDelete;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @pleaseCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get pleaseCheckConnection;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get accountSecurity;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @savedItems.
  ///
  /// In en, this message translates to:
  /// **'Saved Items'**
  String get savedItems;

  /// No description provided for @myReviews.
  ///
  /// In en, this message translates to:
  /// **'My Reviews'**
  String get myReviews;

  /// No description provided for @bookingHistory.
  ///
  /// In en, this message translates to:
  /// **'Booking History'**
  String get bookingHistory;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed to English'**
  String get languageChanged;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @chooseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Choose Currency'**
  String get chooseCurrency;

  /// No description provided for @priceDisplay.
  ///
  /// In en, this message translates to:
  /// **'Price Display'**
  String get priceDisplay;

  /// No description provided for @perNight.
  ///
  /// In en, this message translates to:
  /// **'Per night'**
  String get perNight;

  /// No description provided for @perStay.
  ///
  /// In en, this message translates to:
  /// **'Per entire stay'**
  String get perStay;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @hotelOwner.
  ///
  /// In en, this message translates to:
  /// **'Hotel Owner'**
  String get hotelOwner;

  /// No description provided for @registerHotel.
  ///
  /// In en, this message translates to:
  /// **'Register Hotel'**
  String get registerHotel;

  /// No description provided for @myHotels.
  ///
  /// In en, this message translates to:
  /// **'My Hotels'**
  String get myHotels;

  /// No description provided for @manageHotels.
  ///
  /// In en, this message translates to:
  /// **'Manage Hotels'**
  String get manageHotels;

  /// No description provided for @hotelDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get hotelDashboard;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @vipStatus.
  ///
  /// In en, this message translates to:
  /// **'VIP Status'**
  String get vipStatus;

  /// No description provided for @vipBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get vipBronze;

  /// No description provided for @vipSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get vipSilver;

  /// No description provided for @vipGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get vipGold;

  /// No description provided for @vipPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get vipPlatinum;

  /// No description provided for @unreadMessages.
  ///
  /// In en, this message translates to:
  /// **'Unread Messages'**
  String get unreadMessages;

  /// No description provided for @unreadReviews.
  ///
  /// In en, this message translates to:
  /// **'Unread Reviews'**
  String get unreadReviews;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @aboutUsTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUsTitle;

  /// No description provided for @aboutUsDescription.
  ///
  /// In en, this message translates to:
  /// **'Hotel Booking is a leading hotel reservation app, providing convenient and reliable booking experience.'**
  String get aboutUsDescription;

  /// No description provided for @ourMission.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get ourMission;

  /// No description provided for @ourMissionText.
  ///
  /// In en, this message translates to:
  /// **'To provide customers with the best booking experience at reasonable prices and high-quality service.'**
  String get ourMissionText;

  /// No description provided for @ourVision.
  ///
  /// In en, this message translates to:
  /// **'Our Vision'**
  String get ourVision;

  /// No description provided for @ourVisionText.
  ///
  /// In en, this message translates to:
  /// **'To become the most trusted hotel booking platform in Vietnam.'**
  String get ourVisionText;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @phoneContact.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneContact;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @helpCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenterTitle;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faq;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get feedbackTitle;

  /// No description provided for @feedbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Feedback Message'**
  String get feedbackMessage;

  /// No description provided for @feedbackCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get feedbackCategory;

  /// No description provided for @feedbackGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get feedbackGeneral;

  /// No description provided for @feedbackBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get feedbackBooking;

  /// No description provided for @feedbackPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get feedbackPayment;

  /// No description provided for @feedbackTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get feedbackTechnical;

  /// No description provided for @feedbackOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackOther;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent successfully'**
  String get feedbackSent;

  /// No description provided for @feedbackError.
  ///
  /// In en, this message translates to:
  /// **'Error sending feedback'**
  String get feedbackError;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter title'**
  String get pleaseEnterTitle;

  /// No description provided for @pleaseEnterMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter message'**
  String get pleaseEnterMessage;

  /// No description provided for @faqHowToBook.
  ///
  /// In en, this message translates to:
  /// **'How to book a room?'**
  String get faqHowToBook;

  /// No description provided for @faqHowToBookAnswer.
  ///
  /// In en, this message translates to:
  /// **'1. Search for hotels by location and date\n2. Choose a suitable room\n3. Fill in information and confirm\n4. Pay and receive booking confirmation'**
  String get faqHowToBookAnswer;

  /// No description provided for @faqCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Can I cancel my booking?'**
  String get faqCancelBooking;

  /// No description provided for @faqCancelBookingAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can cancel your booking in \'Booking History\'. Cancellation policy depends on each hotel.'**
  String get faqCancelBookingAnswer;

  /// No description provided for @faqPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'What payment methods are accepted?'**
  String get faqPaymentMethod;

  /// No description provided for @faqPaymentMethodAnswer.
  ///
  /// In en, this message translates to:
  /// **'We accept credit cards, debit cards, e-wallets and bank transfers.'**
  String get faqPaymentMethodAnswer;

  /// No description provided for @faqChangeBooking.
  ///
  /// In en, this message translates to:
  /// **'How to change booking information?'**
  String get faqChangeBooking;

  /// No description provided for @faqChangeBookingAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please contact customer support via email or hotline for assistance with changing information.'**
  String get faqChangeBookingAnswer;

  /// No description provided for @faqRefund.
  ///
  /// In en, this message translates to:
  /// **'What is the refund policy?'**
  String get faqRefund;

  /// No description provided for @faqRefundAnswer.
  ///
  /// In en, this message translates to:
  /// **'Refund policy depends on each hotel\'s terms. Usually within 5-7 business days after cancellation.'**
  String get faqRefundAnswer;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @messagesFromHotel.
  ///
  /// In en, this message translates to:
  /// **'Messages from Hotel'**
  String get messagesFromHotel;

  /// No description provided for @savedCards.
  ///
  /// In en, this message translates to:
  /// **'My Saved Cards'**
  String get savedCards;

  /// No description provided for @manageMyHotels.
  ///
  /// In en, this message translates to:
  /// **'Manage My Hotels'**
  String get manageMyHotels;

  /// No description provided for @registerNewHotel.
  ///
  /// In en, this message translates to:
  /// **'Register New Hotel'**
  String get registerNewHotel;

  /// No description provided for @priceDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Price Display'**
  String get priceDisplayTitle;

  /// No description provided for @priceDisplayPerNight.
  ///
  /// In en, this message translates to:
  /// **'Per night'**
  String get priceDisplayPerNight;

  /// No description provided for @priceDisplayPerStay.
  ///
  /// In en, this message translates to:
  /// **'Per entire stay'**
  String get priceDisplayPerStay;

  /// No description provided for @chooseDistance.
  ///
  /// In en, this message translates to:
  /// **'Choose Distance'**
  String get chooseDistance;

  /// No description provided for @receiveEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive Email Notifications'**
  String get receiveEmailNotifications;

  /// No description provided for @accountSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettingsTitle;

  /// No description provided for @supportAndFeedback.
  ///
  /// In en, this message translates to:
  /// **'Support & Feedback'**
  String get supportAndFeedback;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirm;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountMessage;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
