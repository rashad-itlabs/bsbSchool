import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
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
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

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
    Locale('az'),
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @addChildAdded.
  ///
  /// In az, this message translates to:
  /// **'Şagird hesabınıza əlavə edildi'**
  String get addChildAdded;

  /// No description provided for @addChildAnotherText.
  ///
  /// In az, this message translates to:
  /// **'Övladınızın qəbul nömrəsini daxil edin — şagird hesabınıza bağlanacaq və bütün məlumatlarını buradan izləyəcəksiniz.'**
  String get addChildAnotherText;

  /// No description provided for @addChildEnterNumber.
  ///
  /// In az, this message translates to:
  /// **'Qəbul nömrəsini daxil edin'**
  String get addChildEnterNumber;

  /// No description provided for @addChildField.
  ///
  /// In az, this message translates to:
  /// **'Qəbul nömrəsi'**
  String get addChildField;

  /// No description provided for @addChildHint.
  ///
  /// In az, this message translates to:
  /// **'Övladınızın sistem ID-si'**
  String get addChildHint;

  /// No description provided for @addChildOtherAccount.
  ///
  /// In az, this message translates to:
  /// **'Başqa hesabla daxil ol'**
  String get addChildOtherAccount;

  /// No description provided for @addChildSubmit.
  ///
  /// In az, this message translates to:
  /// **'Əlavə et'**
  String get addChildSubmit;

  /// No description provided for @addChildText.
  ///
  /// In az, this message translates to:
  /// **'Hesabınıza hələ şagird bağlanmayıb. Davam etmək üçün övladınızın qəbul nömrəsini daxil edin.'**
  String get addChildText;

  /// No description provided for @addChildTextNamed.
  ///
  /// In az, this message translates to:
  /// **'{name}, hesabınıza hələ şagird bağlanmayıb. Davam etmək üçün övladınızın qəbul nömrəsini daxil edin.'**
  String addChildTextNamed(String name);

  /// No description provided for @addChildTitle.
  ///
  /// In az, this message translates to:
  /// **'Şagirdinizi əlavə edin'**
  String get addChildTitle;

  /// No description provided for @addChildWhere1.
  ///
  /// In az, this message translates to:
  /// **'Şagird vəsiqəsinin üzərində'**
  String get addChildWhere1;

  /// No description provided for @addChildWhere2.
  ///
  /// In az, this message translates to:
  /// **'Məktəbin verdiyi qəbul sənədində'**
  String get addChildWhere2;

  /// No description provided for @addChildWhere3.
  ///
  /// In az, this message translates to:
  /// **'Məktəbin katibliyindən soruşa bilərsiniz'**
  String get addChildWhere3;

  /// No description provided for @addChildWhereTitle.
  ///
  /// In az, this message translates to:
  /// **'Qəbul nömrəsi haradadır?'**
  String get addChildWhereTitle;

  /// No description provided for @amountEnterValid.
  ///
  /// In az, this message translates to:
  /// **'Məbləği düzgün yazın'**
  String get amountEnterValid;

  /// No description provided for @amountRange.
  ///
  /// In az, this message translates to:
  /// **'Məbləğ {min}–{max} ₼ aralığında olmalıdır'**
  String amountRange(String min, String max);

  /// No description provided for @appTitle.
  ///
  /// In az, this message translates to:
  /// **'BSB School'**
  String get appTitle;

  /// No description provided for @attendanceAbsent.
  ///
  /// In az, this message translates to:
  /// **'Qayıb'**
  String get attendanceAbsent;

  /// No description provided for @attendanceEmpty.
  ///
  /// In az, this message translates to:
  /// **'Qeyd tapılmadı'**
  String get attendanceEmpty;

  /// No description provided for @attendanceLate.
  ///
  /// In az, this message translates to:
  /// **'Gecikmə'**
  String get attendanceLate;

  /// No description provided for @attendanceLateTag.
  ///
  /// In az, this message translates to:
  /// **'Gecikib'**
  String get attendanceLateTag;

  /// No description provided for @attendanceLesson.
  ///
  /// In az, this message translates to:
  /// **'Dərs'**
  String get attendanceLesson;

  /// No description provided for @attendanceMonthOverview.
  ///
  /// In az, this message translates to:
  /// **'{month} ayı üzrə icmal'**
  String attendanceMonthOverview(String month);

  /// No description provided for @attendancePresent.
  ///
  /// In az, this message translates to:
  /// **'Gəlib'**
  String get attendancePresent;

  /// No description provided for @attendanceRate.
  ///
  /// In az, this message translates to:
  /// **'İştirak'**
  String get attendanceRate;

  /// No description provided for @attendanceRecent.
  ///
  /// In az, this message translates to:
  /// **'Son qeydlər'**
  String get attendanceRecent;

  /// No description provided for @attendanceTitle.
  ///
  /// In az, this message translates to:
  /// **'Davamiyyət'**
  String get attendanceTitle;

  /// No description provided for @balanceAmountField.
  ///
  /// In az, this message translates to:
  /// **'Məbləğ (AZN)'**
  String get balanceAmountField;

  /// No description provided for @balanceCurrent.
  ///
  /// In az, this message translates to:
  /// **'Mövcud balans'**
  String get balanceCurrent;

  /// No description provided for @balanceCustomAmount.
  ///
  /// In az, this message translates to:
  /// **'Xüsusi məbləğ'**
  String get balanceCustomAmount;

  /// No description provided for @balanceInvalidAmount.
  ///
  /// In az, this message translates to:
  /// **'Düzgün məbləğ daxil edin'**
  String get balanceInvalidAmount;

  /// No description provided for @balanceLabel.
  ///
  /// In az, this message translates to:
  /// **'Balans'**
  String get balanceLabel;

  /// No description provided for @balanceQuickTopUp.
  ///
  /// In az, this message translates to:
  /// **'Sürətli artırma'**
  String get balanceQuickTopUp;

  /// No description provided for @balanceTopUp.
  ///
  /// In az, this message translates to:
  /// **'Balansı artır'**
  String get balanceTopUp;

  /// No description provided for @bookDeleteText.
  ///
  /// In az, this message translates to:
  /// **'Kitab telefondan və \"{location}\" bölməsindən silinəcək. İnternet olduqda yenidən oxuya bilərsiniz.'**
  String bookDeleteText(String location);

  /// No description provided for @bookDeleteTitle.
  ///
  /// In az, this message translates to:
  /// **'Yüklənmiş faylı sil?'**
  String get bookDeleteTitle;

  /// No description provided for @bookDeleted.
  ///
  /// In az, this message translates to:
  /// **'Yüklənmiş fayl silindi'**
  String get bookDeleted;

  /// No description provided for @bookDownloadFailed.
  ///
  /// In az, this message translates to:
  /// **'Yükləmə alınmadı'**
  String get bookDownloadFailed;

  /// No description provided for @bookDownloaded.
  ///
  /// In az, this message translates to:
  /// **'Kitab \"{location}\" bölməsinə yükləndi'**
  String bookDownloaded(String location);

  /// No description provided for @bookDownloadedPartial.
  ///
  /// In az, this message translates to:
  /// **'Kitab yükləndi, ancaq \"{location}\" bölməsinə yazıla bilmədi'**
  String bookDownloadedPartial(String location);

  /// No description provided for @bookNoFile.
  ///
  /// In az, this message translates to:
  /// **'Bu kitabın faylı yoxdur'**
  String get bookNoFile;

  /// No description provided for @bookOpenFailed.
  ///
  /// In az, this message translates to:
  /// **'Kitab açılmadı: {reason}'**
  String bookOpenFailed(String reason);

  /// No description provided for @buffetOrder.
  ///
  /// In az, this message translates to:
  /// **'Sifariş et'**
  String get buffetOrder;

  /// No description provided for @buffetProductCount.
  ///
  /// In az, this message translates to:
  /// **'{count} məhsul'**
  String buffetProductCount(int count);

  /// No description provided for @cafeteriaDailyLimit.
  ///
  /// In az, this message translates to:
  /// **'Günlük limit'**
  String get cafeteriaDailyLimit;

  /// No description provided for @cafeteriaSpent.
  ///
  /// In az, this message translates to:
  /// **'Xərclənib'**
  String get cafeteriaSpent;

  /// No description provided for @cardExpiry.
  ///
  /// In az, this message translates to:
  /// **'Müddət'**
  String get cardExpiry;

  /// No description provided for @cardHolder.
  ///
  /// In az, this message translates to:
  /// **'Kart Sahibinin Adı'**
  String get cardHolder;

  /// No description provided for @cardHolderHint.
  ///
  /// In az, this message translates to:
  /// **'AD VƏ SOYAD'**
  String get cardHolderHint;

  /// No description provided for @cardNumberField.
  ///
  /// In az, this message translates to:
  /// **'Kartın nömrəsi'**
  String get cardNumberField;

  /// No description provided for @cardNumberLabel.
  ///
  /// In az, this message translates to:
  /// **'Kart nömrəsi'**
  String get cardNumberLabel;

  /// No description provided for @commonAll.
  ///
  /// In az, this message translates to:
  /// **'Hamısı'**
  String get commonAll;

  /// No description provided for @commonCancel.
  ///
  /// In az, this message translates to:
  /// **'Ləğv et'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In az, this message translates to:
  /// **'Bağla'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In az, this message translates to:
  /// **'Təsdiqlə'**
  String get commonConfirm;

  /// No description provided for @commonContinue.
  ///
  /// In az, this message translates to:
  /// **'Davam et'**
  String get commonContinue;

  /// No description provided for @commonCopy.
  ///
  /// In az, this message translates to:
  /// **'Kopyala'**
  String get commonCopy;

  /// No description provided for @commonDelete.
  ///
  /// In az, this message translates to:
  /// **'Sil'**
  String get commonDelete;

  /// No description provided for @commonError.
  ///
  /// In az, this message translates to:
  /// **'Xəta baş verdi'**
  String get commonError;

  /// No description provided for @commonErrorShort.
  ///
  /// In az, this message translates to:
  /// **'Xəta'**
  String get commonErrorShort;

  /// No description provided for @commonFilter.
  ///
  /// In az, this message translates to:
  /// **'Filtr'**
  String get commonFilter;

  /// No description provided for @commonHide.
  ///
  /// In az, this message translates to:
  /// **'Gizlət'**
  String get commonHide;

  /// No description provided for @commonNo.
  ///
  /// In az, this message translates to:
  /// **'Xeyr'**
  String get commonNo;

  /// No description provided for @commonNoData.
  ///
  /// In az, this message translates to:
  /// **'Məlumat tapılmadı'**
  String get commonNoData;

  /// No description provided for @commonRetry.
  ///
  /// In az, this message translates to:
  /// **'Yenidən cəhd et'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In az, this message translates to:
  /// **'Yadda saxla'**
  String get commonSave;

  /// No description provided for @commonSearch.
  ///
  /// In az, this message translates to:
  /// **'Axtar'**
  String get commonSearch;

  /// No description provided for @commonSelectStudent.
  ///
  /// In az, this message translates to:
  /// **'Şagird seç'**
  String get commonSelectStudent;

  /// No description provided for @commonShow.
  ///
  /// In az, this message translates to:
  /// **'Göstər'**
  String get commonShow;

  /// No description provided for @commonYes.
  ///
  /// In az, this message translates to:
  /// **'Bəli'**
  String get commonYes;

  /// No description provided for @copiedToClipboard.
  ///
  /// In az, this message translates to:
  /// **'{label} kopyalandı'**
  String copiedToClipboard(String label);

  /// No description provided for @credentialActive.
  ///
  /// In az, this message translates to:
  /// **'Aktiv'**
  String get credentialActive;

  /// No description provided for @credentialPaymentId.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş ID'**
  String get credentialPaymentId;

  /// No description provided for @credentialSwitchTo.
  ///
  /// In az, this message translates to:
  /// **'Bu şagirdə keç'**
  String get credentialSwitchTo;

  /// No description provided for @credentialSwitching.
  ///
  /// In az, this message translates to:
  /// **'Dəyişdirilir…'**
  String get credentialSwitching;

  /// No description provided for @credentialUsername.
  ///
  /// In az, this message translates to:
  /// **'Username'**
  String get credentialUsername;

  /// No description provided for @dailyUsage.
  ///
  /// In az, this message translates to:
  /// **'Günlük: {used}/{limit}'**
  String dailyUsage(String used, String limit);

  /// No description provided for @dashGreeting.
  ///
  /// In az, this message translates to:
  /// **'{name} 👋'**
  String dashGreeting(String name);

  /// No description provided for @dashNewsFailed.
  ///
  /// In az, this message translates to:
  /// **'Xəbərlər yüklənmədi'**
  String get dashNewsFailed;

  /// No description provided for @dashSeeAll.
  ///
  /// In az, this message translates to:
  /// **'Hamısına bax'**
  String get dashSeeAll;

  /// No description provided for @downloadsFiles.
  ///
  /// In az, this message translates to:
  /// **'Fayllar'**
  String get downloadsFiles;

  /// No description provided for @downloadsFolder.
  ///
  /// In az, this message translates to:
  /// **'Yükləmələr'**
  String get downloadsFolder;

  /// No description provided for @dueDateLabel.
  ///
  /// In az, this message translates to:
  /// **'Son tarix: {date}'**
  String dueDateLabel(String date);

  /// No description provided for @dueDateOverdueLabel.
  ///
  /// In az, this message translates to:
  /// **'Son tarix: {date} · gecikib'**
  String dueDateOverdueLabel(String date);

  /// No description provided for @errAttendanceLoad.
  ///
  /// In az, this message translates to:
  /// **'Davamiyyət yüklənmədi'**
  String get errAttendanceLoad;

  /// No description provided for @errBalanceUpdate.
  ///
  /// In az, this message translates to:
  /// **'Balans yenilənmədi'**
  String get errBalanceUpdate;

  /// No description provided for @errBuffetCardLoad.
  ///
  /// In az, this message translates to:
  /// **'Bufet kartı yüklənmədi'**
  String get errBuffetCardLoad;

  /// No description provided for @errCache.
  ///
  /// In az, this message translates to:
  /// **'Keş xətası baş verdi'**
  String get errCache;

  /// No description provided for @errChildNotSwitched.
  ///
  /// In az, this message translates to:
  /// **'Şagird dəyişdirilmədi'**
  String get errChildNotSwitched;

  /// No description provided for @errChildNotYours.
  ///
  /// In az, this message translates to:
  /// **'Bu şagird sizin hesabınıza aid deyil'**
  String get errChildNotYours;

  /// No description provided for @errChildNotYoursShort.
  ///
  /// In az, this message translates to:
  /// **'Bu şagird hesabınıza aid deyil'**
  String get errChildNotYoursShort;

  /// No description provided for @errEventsLoad.
  ///
  /// In az, this message translates to:
  /// **'Tədbirlər yüklənmədi'**
  String get errEventsLoad;

  /// No description provided for @errExamLoad.
  ///
  /// In az, this message translates to:
  /// **'İmtahan nəticələri yüklənmədi'**
  String get errExamLoad;

  /// No description provided for @errExtraFeesLoad.
  ///
  /// In az, this message translates to:
  /// **'Əlavə ödənişlər yüklənmədi'**
  String get errExtraFeesLoad;

  /// No description provided for @errHomeworkLoad.
  ///
  /// In az, this message translates to:
  /// **'Tapşırıqlar yüklənmədi'**
  String get errHomeworkLoad;

  /// No description provided for @errInsufficientBalance.
  ///
  /// In az, this message translates to:
  /// **'Balans kifayət etmir'**
  String get errInsufficientBalance;

  /// No description provided for @errInvalid.
  ///
  /// In az, this message translates to:
  /// **'Yanlış əməliyyat'**
  String get errInvalid;

  /// No description provided for @errLibraryLoad.
  ///
  /// In az, this message translates to:
  /// **'Kitabxana məlumatları yüklənmədi'**
  String get errLibraryLoad;

  /// No description provided for @errNewsLoad.
  ///
  /// In az, this message translates to:
  /// **'Xəbərlər yüklənmədi'**
  String get errNewsLoad;

  /// No description provided for @errNoConnection.
  ///
  /// In az, this message translates to:
  /// **'Serverə qoşulmaq mümkün olmadı'**
  String get errNoConnection;

  /// No description provided for @errNoInternet.
  ///
  /// In az, this message translates to:
  /// **'İnternet bağlantısı yoxdur'**
  String get errNoInternet;

  /// No description provided for @errNotificationsLoad.
  ///
  /// In az, this message translates to:
  /// **'Bildirişlər yüklənmədi'**
  String get errNotificationsLoad;

  /// No description provided for @errOrderFailed.
  ///
  /// In az, this message translates to:
  /// **'Sifariş göndərilə bilmədi'**
  String get errOrderFailed;

  /// No description provided for @errPaymentGateway.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş sistemi ilə əlaqə qurulmadı'**
  String get errPaymentGateway;

  /// No description provided for @errPaymentLink.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş linki alınmadı'**
  String get errPaymentLink;

  /// No description provided for @errServer.
  ///
  /// In az, this message translates to:
  /// **'Server xətası baş verdi'**
  String get errServer;

  /// No description provided for @errSessionExpired.
  ///
  /// In az, this message translates to:
  /// **'Sessiya bitib, yenidən daxil olun'**
  String get errSessionExpired;

  /// No description provided for @errStudentNotFound.
  ///
  /// In az, this message translates to:
  /// **'Şagird tapılmadı'**
  String get errStudentNotFound;

  /// No description provided for @errTimetableLoad.
  ///
  /// In az, this message translates to:
  /// **'Dərs cədvəli yüklənmədi'**
  String get errTimetableLoad;

  /// No description provided for @errTokenMissing.
  ///
  /// In az, this message translates to:
  /// **'Token cavabda tapılmadı'**
  String get errTokenMissing;

  /// No description provided for @errTuitionLoad.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş məlumatları yüklənmədi'**
  String get errTuitionLoad;

  /// No description provided for @errUserNotFound.
  ///
  /// In az, this message translates to:
  /// **'Bu e-mail ilə istifadəçi tapılmadı'**
  String get errUserNotFound;

  /// No description provided for @errWrongCredentials.
  ///
  /// In az, this message translates to:
  /// **'E-mail və ya şifrə yanlışdır'**
  String get errWrongCredentials;

  /// No description provided for @eventsMore.
  ///
  /// In az, this message translates to:
  /// **'və daha {count} tədbir'**
  String eventsMore(int count);

  /// No description provided for @eventsNoneToday.
  ///
  /// In az, this message translates to:
  /// **'Bu gün üçün tədbir yoxdur'**
  String get eventsNoneToday;

  /// No description provided for @examAllResults.
  ///
  /// In az, this message translates to:
  /// **'Bütün nəticələr'**
  String get examAllResults;

  /// No description provided for @examBehaviourLabel.
  ///
  /// In az, this message translates to:
  /// **'Davranış: {value}'**
  String examBehaviourLabel(String value);

  /// No description provided for @examEffortLabel.
  ///
  /// In az, this message translates to:
  /// **'Səy: {value}'**
  String examEffortLabel(String value);

  /// No description provided for @examEmpty.
  ///
  /// In az, this message translates to:
  /// **'İmtahan nəticəsi tapılmadı'**
  String get examEmpty;

  /// No description provided for @examExam.
  ///
  /// In az, this message translates to:
  /// **'İmtahan'**
  String get examExam;

  /// No description provided for @examFilters.
  ///
  /// In az, this message translates to:
  /// **'Filtrlər'**
  String get examFilters;

  /// No description provided for @examGradeLabel.
  ///
  /// In az, this message translates to:
  /// **'Grade: {value}'**
  String examGradeLabel(String value);

  /// No description provided for @examGroup.
  ///
  /// In az, this message translates to:
  /// **'İmtahan qrupu'**
  String get examGroup;

  /// No description provided for @examNoMatch.
  ///
  /// In az, this message translates to:
  /// **'Seçilmiş filtrlərə uyğun nəticə yoxdur'**
  String get examNoMatch;

  /// No description provided for @examNoStudent.
  ///
  /// In az, this message translates to:
  /// **'Şagird təyin edilməyib'**
  String get examNoStudent;

  /// No description provided for @examNotGraded.
  ///
  /// In az, this message translates to:
  /// **'Qiymətləndirilməyib'**
  String get examNotGraded;

  /// No description provided for @examReset.
  ///
  /// In az, this message translates to:
  /// **'Sıfırla'**
  String get examReset;

  /// No description provided for @examResetFilters.
  ///
  /// In az, this message translates to:
  /// **'Filtrləri sıfırla'**
  String get examResetFilters;

  /// No description provided for @examResults.
  ///
  /// In az, this message translates to:
  /// **'Nəticələr'**
  String get examResults;

  /// No description provided for @examShowResults.
  ///
  /// In az, this message translates to:
  /// **'Nəticələri göstər ({count})'**
  String examShowResults(int count);

  /// No description provided for @examTitle.
  ///
  /// In az, this message translates to:
  /// **'İmtahan nəticələri'**
  String get examTitle;

  /// No description provided for @extraFeeAmount.
  ///
  /// In az, this message translates to:
  /// **'Məbləğ'**
  String get extraFeeAmount;

  /// No description provided for @extraFeeFallbackTitle.
  ///
  /// In az, this message translates to:
  /// **'Əlavə ödəniş'**
  String get extraFeeFallbackTitle;

  /// No description provided for @extraFeeNoDueDate.
  ///
  /// In az, this message translates to:
  /// **'Son tarix yoxdur'**
  String get extraFeeNoDueDate;

  /// No description provided for @extraFeePaid.
  ///
  /// In az, this message translates to:
  /// **'Ödənilmiş'**
  String get extraFeePaid;

  /// No description provided for @extraFeeRemaining.
  ///
  /// In az, this message translates to:
  /// **'Qalıq'**
  String get extraFeeRemaining;

  /// No description provided for @extraFeesAllDone.
  ///
  /// In az, this message translates to:
  /// **'Bütün əlavə ödənişlər tamamlanıb.'**
  String get extraFeesAllDone;

  /// No description provided for @extraFeesAllPaid.
  ///
  /// In az, this message translates to:
  /// **'Hamısı ödənilib'**
  String get extraFeesAllPaid;

  /// No description provided for @extraFeesCountLabel.
  ///
  /// In az, this message translates to:
  /// **'{count} əlavə ödəniş'**
  String extraFeesCountLabel(int count);

  /// No description provided for @extraFeesEmpty.
  ///
  /// In az, this message translates to:
  /// **'Əlavə ödəniş yoxdur'**
  String get extraFeesEmpty;

  /// No description provided for @extraFeesListTitle.
  ///
  /// In az, this message translates to:
  /// **'Əlavə ödənişlər'**
  String get extraFeesListTitle;

  /// No description provided for @extraFeesNoPayment.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş yoxdur'**
  String get extraFeesNoPayment;

  /// No description provided for @extraFeesOutstanding.
  ///
  /// In az, this message translates to:
  /// **'Qalıq borc'**
  String get extraFeesOutstanding;

  /// No description provided for @extraFeesOverdueCount.
  ///
  /// In az, this message translates to:
  /// **'Gecikmiş ödəniş'**
  String get extraFeesOverdueCount;

  /// No description provided for @extraFeesOverdueDebt.
  ///
  /// In az, this message translates to:
  /// **'Gecikmiş ödəniş var — {amount} borc qalıb.'**
  String extraFeesOverdueDebt(String amount);

  /// No description provided for @extraFeesOverdueHint.
  ///
  /// In az, this message translates to:
  /// **'Vaxtı keçib'**
  String get extraFeesOverdueHint;

  /// No description provided for @extraFeesPaidAmount.
  ///
  /// In az, this message translates to:
  /// **'Ödənilmiş məbləğ'**
  String get extraFeesPaidAmount;

  /// No description provided for @extraFeesPayEachSeparately.
  ///
  /// In az, this message translates to:
  /// **'Hər ödəniş ayrıca aparılır — aşağıdakı siyahıdan seçin.'**
  String get extraFeesPayEachSeparately;

  /// No description provided for @extraFeesPayableAmount.
  ///
  /// In az, this message translates to:
  /// **'Ödənilməli məbləğ: {amount}'**
  String extraFeesPayableAmount(String amount);

  /// No description provided for @extraFeesPendingCount.
  ///
  /// In az, this message translates to:
  /// **'{count} ödəniş gözləyir'**
  String extraFeesPendingCount(int count);

  /// No description provided for @extraFeesProgressDone.
  ///
  /// In az, this message translates to:
  /// **'{percent}% tamamlanıb'**
  String extraFeesProgressDone(int percent);

  /// No description provided for @extraFeesTotal.
  ///
  /// In az, this message translates to:
  /// **'Ümumi məbləğ'**
  String get extraFeesTotal;

  /// No description provided for @featureAttendance.
  ///
  /// In az, this message translates to:
  /// **'Davamiyyət'**
  String get featureAttendance;

  /// No description provided for @featureBuffet.
  ///
  /// In az, this message translates to:
  /// **'Bufet'**
  String get featureBuffet;

  /// No description provided for @featureCalendar.
  ///
  /// In az, this message translates to:
  /// **'Təqvim'**
  String get featureCalendar;

  /// No description provided for @featureExaminations.
  ///
  /// In az, this message translates to:
  /// **'İmtahanlar'**
  String get featureExaminations;

  /// No description provided for @featureHomework.
  ///
  /// In az, this message translates to:
  /// **'Ev tapşırığı'**
  String get featureHomework;

  /// No description provided for @featureLibrary.
  ///
  /// In az, this message translates to:
  /// **'Kitabxana'**
  String get featureLibrary;

  /// No description provided for @featureLiveLessons.
  ///
  /// In az, this message translates to:
  /// **'Onlayn dərslər'**
  String get featureLiveLessons;

  /// No description provided for @featureTimetable.
  ///
  /// In az, this message translates to:
  /// **'Dərs cədvəli'**
  String get featureTimetable;

  /// No description provided for @featureWeeklyPlan.
  ///
  /// In az, this message translates to:
  /// **'Həftəlik plan'**
  String get featureWeeklyPlan;

  /// No description provided for @fileCouldNotOpen.
  ///
  /// In az, this message translates to:
  /// **'Fayl açıla bilmədi'**
  String get fileCouldNotOpen;

  /// No description provided for @fileDownload.
  ///
  /// In az, this message translates to:
  /// **'Faylı yüklə'**
  String get fileDownload;

  /// No description provided for @foodCardEmpty.
  ///
  /// In az, this message translates to:
  /// **'Bufet kartı tapılmadı'**
  String get foodCardEmpty;

  /// No description provided for @foodCardTitle.
  ///
  /// In az, this message translates to:
  /// **'Bufet Kartım'**
  String get foodCardTitle;

  /// No description provided for @forgotDone.
  ///
  /// In az, this message translates to:
  /// **'Şifrəniz yeniləndi. Yeni şifrə ilə daxil ola bilərsiniz.'**
  String get forgotDone;

  /// No description provided for @forgotEmailField.
  ///
  /// In az, this message translates to:
  /// **'E-mail ünvanı'**
  String get forgotEmailField;

  /// No description provided for @forgotEmailInvalid.
  ///
  /// In az, this message translates to:
  /// **'E-mail ünvanı düzgün deyil'**
  String get forgotEmailInvalid;

  /// No description provided for @forgotEmailRequired.
  ///
  /// In az, this message translates to:
  /// **'E-mail ünvanını daxil edin'**
  String get forgotEmailRequired;

  /// No description provided for @forgotMinLength.
  ///
  /// In az, this message translates to:
  /// **'Şifrə ən azı {count} simvol olmalıdır.'**
  String forgotMinLength(int count);

  /// No description provided for @forgotNewPassword.
  ///
  /// In az, this message translates to:
  /// **'Yeni şifrə'**
  String get forgotNewPassword;

  /// No description provided for @forgotPasswordMismatch.
  ///
  /// In az, this message translates to:
  /// **'Şifrələr eyni deyil'**
  String get forgotPasswordMismatch;

  /// No description provided for @forgotPasswordRequired.
  ///
  /// In az, this message translates to:
  /// **'Yeni şifrəni daxil edin'**
  String get forgotPasswordRequired;

  /// No description provided for @forgotPasswordShort.
  ///
  /// In az, this message translates to:
  /// **'Şifrə ən azı {count} simvol olmalıdır'**
  String forgotPasswordShort(int count);

  /// No description provided for @forgotRepeatPassword.
  ///
  /// In az, this message translates to:
  /// **'Yeni şifrə (təkrar)'**
  String get forgotRepeatPassword;

  /// No description provided for @forgotSubmit.
  ///
  /// In az, this message translates to:
  /// **'Şifrəni yenilə'**
  String get forgotSubmit;

  /// No description provided for @forgotText.
  ///
  /// In az, this message translates to:
  /// **'Qeydiyyatdan keçdiyiniz e-mail ünvanını və yeni şifrənizi daxil edin. E-mail doğrudursa, şifrə dərhal yenilənəcək.'**
  String get forgotText;

  /// No description provided for @forgotTitle.
  ///
  /// In az, this message translates to:
  /// **'Şifrənin bərpası'**
  String get forgotTitle;

  /// No description provided for @historyCanteen.
  ///
  /// In az, this message translates to:
  /// **'Yeməkxana'**
  String get historyCanteen;

  /// No description provided for @historyIncome.
  ///
  /// In az, this message translates to:
  /// **'Mədaxil'**
  String get historyIncome;

  /// No description provided for @historyOther.
  ///
  /// In az, this message translates to:
  /// **'Digər'**
  String get historyOther;

  /// No description provided for @historyTitle.
  ///
  /// In az, this message translates to:
  /// **'Tarixçə'**
  String get historyTitle;

  /// No description provided for @historyTuition.
  ///
  /// In az, this message translates to:
  /// **'Təhsil'**
  String get historyTuition;

  /// No description provided for @homeSections.
  ///
  /// In az, this message translates to:
  /// **'Bölmələr'**
  String get homeSections;

  /// No description provided for @homeworkActive.
  ///
  /// In az, this message translates to:
  /// **'Aktiv'**
  String get homeworkActive;

  /// No description provided for @homeworkDaysLeft.
  ///
  /// In az, this message translates to:
  /// **'{days} gün qalıb'**
  String homeworkDaysLeft(int days);

  /// No description provided for @homeworkDuePrefix.
  ///
  /// In az, this message translates to:
  /// **'Son tarix: '**
  String get homeworkDuePrefix;

  /// No description provided for @homeworkInactive.
  ///
  /// In az, this message translates to:
  /// **'Deaktiv'**
  String get homeworkInactive;

  /// No description provided for @homeworkNoActive.
  ///
  /// In az, this message translates to:
  /// **'Aktiv tapşırıq yoxdur'**
  String get homeworkNoActive;

  /// No description provided for @homeworkNoClass.
  ///
  /// In az, this message translates to:
  /// **'Sinif təyin edilməyib'**
  String get homeworkNoClass;

  /// No description provided for @homeworkNoInactive.
  ///
  /// In az, this message translates to:
  /// **'Deaktiv tapşırıq yoxdur'**
  String get homeworkNoInactive;

  /// No description provided for @homeworkOverdue.
  ///
  /// In az, this message translates to:
  /// **'Gecikmiş'**
  String get homeworkOverdue;

  /// No description provided for @homeworkTitle.
  ///
  /// In az, this message translates to:
  /// **'Tapşırıqlar'**
  String get homeworkTitle;

  /// No description provided for @homeworkToday.
  ///
  /// In az, this message translates to:
  /// **'Bu gün'**
  String get homeworkToday;

  /// No description provided for @homeworkTomorrow.
  ///
  /// In az, this message translates to:
  /// **'Sabah'**
  String get homeworkTomorrow;

  /// No description provided for @hwDetailDescription.
  ///
  /// In az, this message translates to:
  /// **'Təsvir'**
  String get hwDetailDescription;

  /// No description provided for @hwDetailInfo.
  ///
  /// In az, this message translates to:
  /// **'Məlumat'**
  String get hwDetailInfo;

  /// No description provided for @hwDetailTitle.
  ///
  /// In az, this message translates to:
  /// **'Tapşırıq'**
  String get hwDetailTitle;

  /// No description provided for @hwDueDate.
  ///
  /// In az, this message translates to:
  /// **'Son tarix'**
  String get hwDueDate;

  /// No description provided for @hwGivenDate.
  ///
  /// In az, this message translates to:
  /// **'Verilmə tarixi'**
  String get hwGivenDate;

  /// No description provided for @hwGrading.
  ///
  /// In az, this message translates to:
  /// **'Qiymətləndirmə'**
  String get hwGrading;

  /// No description provided for @hwSection.
  ///
  /// In az, this message translates to:
  /// **'Bölmə'**
  String get hwSection;

  /// No description provided for @hwSubject.
  ///
  /// In az, this message translates to:
  /// **'Fənn'**
  String get hwSubject;

  /// No description provided for @hwTeacher.
  ///
  /// In az, this message translates to:
  /// **'Müəllim'**
  String get hwTeacher;

  /// No description provided for @languageAz.
  ///
  /// In az, this message translates to:
  /// **'Azərbaycan dili'**
  String get languageAz;

  /// No description provided for @languageEn.
  ///
  /// In az, this message translates to:
  /// **'İngilis dili'**
  String get languageEn;

  /// No description provided for @languagePickSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Bunu sonra tənzimləmələrdən dəyişə bilərsiniz.'**
  String get languagePickSubtitle;

  /// No description provided for @languagePickTitle.
  ///
  /// In az, this message translates to:
  /// **'Dilinizi seçin'**
  String get languagePickTitle;

  /// No description provided for @languageRu.
  ///
  /// In az, this message translates to:
  /// **'Rus dili'**
  String get languageRu;

  /// No description provided for @languageSystem.
  ///
  /// In az, this message translates to:
  /// **'Sistem dili'**
  String get languageSystem;

  /// No description provided for @lastPaymentLabel.
  ///
  /// In az, this message translates to:
  /// **'Son ödəniş: {date}'**
  String lastPaymentLabel(String date);

  /// No description provided for @libraryEmpty.
  ///
  /// In az, this message translates to:
  /// **'Kitab tapılmadı'**
  String get libraryEmpty;

  /// No description provided for @librarySchoolPaid.
  ///
  /// In az, this message translates to:
  /// **'£19.99 məktəb tərəfindən ödənilib'**
  String get librarySchoolPaid;

  /// No description provided for @librarySearch.
  ///
  /// In az, this message translates to:
  /// **'Axtarış...'**
  String get librarySearch;

  /// No description provided for @libraryTitle.
  ///
  /// In az, this message translates to:
  /// **'Kitabxana'**
  String get libraryTitle;

  /// No description provided for @libraryTitleWithClass.
  ///
  /// In az, this message translates to:
  /// **'Kitabxana • {className}'**
  String libraryTitleWithClass(String className);

  /// No description provided for @liveBadge.
  ///
  /// In az, this message translates to:
  /// **'Canlı'**
  String get liveBadge;

  /// No description provided for @liveJoin.
  ///
  /// In az, this message translates to:
  /// **'Dərsə qoşul'**
  String get liveJoin;

  /// No description provided for @liveLessonsTitle.
  ///
  /// In az, this message translates to:
  /// **'Canlı Dərslər'**
  String get liveLessonsTitle;

  /// No description provided for @liveRoomClosed.
  ///
  /// In az, this message translates to:
  /// **'Otaq hələ açılmayıb'**
  String get liveRoomClosed;

  /// No description provided for @liveStartingNow.
  ///
  /// In az, this message translates to:
  /// **'İndi başlayır'**
  String get liveStartingNow;

  /// No description provided for @liveUpcoming.
  ///
  /// In az, this message translates to:
  /// **'Gözlənilən dərslər'**
  String get liveUpcoming;

  /// No description provided for @loginCall.
  ///
  /// In az, this message translates to:
  /// **'Zəng et'**
  String get loginCall;

  /// No description provided for @loginCannotOpen.
  ///
  /// In az, this message translates to:
  /// **'Bu əməliyyat cihazda açıla bilmədi'**
  String get loginCannotOpen;

  /// No description provided for @loginEmail.
  ///
  /// In az, this message translates to:
  /// **'E-mail'**
  String get loginEmail;

  /// No description provided for @loginEnterCredentials.
  ///
  /// In az, this message translates to:
  /// **'E-mail və şifrəni daxil edin'**
  String get loginEnterCredentials;

  /// No description provided for @loginForgotPassword.
  ///
  /// In az, this message translates to:
  /// **'Şifrəni unutmusunuz?'**
  String get loginForgotPassword;

  /// No description provided for @loginNoAccount.
  ///
  /// In az, this message translates to:
  /// **'Hesabınız yoxdur?'**
  String get loginNoAccount;

  /// No description provided for @loginPassword.
  ///
  /// In az, this message translates to:
  /// **'Şifrə'**
  String get loginPassword;

  /// No description provided for @loginPasswordUpdated.
  ///
  /// In az, this message translates to:
  /// **'Şifrəniz yeniləndi. Yeni şifrə ilə daxil olun.'**
  String get loginPasswordUpdated;

  /// No description provided for @loginRegister.
  ///
  /// In az, this message translates to:
  /// **'Qeydiyyatdan keçin'**
  String get loginRegister;

  /// No description provided for @loginSendEmail.
  ///
  /// In az, this message translates to:
  /// **'E-mail göndər'**
  String get loginSendEmail;

  /// No description provided for @loginSubmit.
  ///
  /// In az, this message translates to:
  /// **'Daxil ol'**
  String get loginSubmit;

  /// No description provided for @loginSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Davam etmək üçün daxil olun'**
  String get loginSubtitle;

  /// No description provided for @loginSupport.
  ///
  /// In az, this message translates to:
  /// **'Dəstək ilə əlaqə'**
  String get loginSupport;

  /// No description provided for @loginSupportText.
  ///
  /// In az, this message translates to:
  /// **'Daxil ola bilmirsinizsə və ya sualınız varsa, bizimlə əlaqə saxlayın.'**
  String get loginSupportText;

  /// No description provided for @loginWelcome.
  ///
  /// In az, this message translates to:
  /// **'Xoş gəlmisiniz'**
  String get loginWelcome;

  /// No description provided for @navAttendance.
  ///
  /// In az, this message translates to:
  /// **'Davamiyyət'**
  String get navAttendance;

  /// No description provided for @navFoodCard.
  ///
  /// In az, this message translates to:
  /// **'Yemək kartı'**
  String get navFoodCard;

  /// No description provided for @navHome.
  ///
  /// In az, this message translates to:
  /// **'Ana səhifə'**
  String get navHome;

  /// No description provided for @navHomework.
  ///
  /// In az, this message translates to:
  /// **'Ev tapşırığı'**
  String get navHomework;

  /// No description provided for @navNotifications.
  ///
  /// In az, this message translates to:
  /// **'Bildirişlər'**
  String get navNotifications;

  /// No description provided for @navProfile.
  ///
  /// In az, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In az, this message translates to:
  /// **'Tənzimləmələr'**
  String get navSettings;

  /// No description provided for @navTimetable.
  ///
  /// In az, this message translates to:
  /// **'Dərs cədvəli'**
  String get navTimetable;

  /// No description provided for @navTuition.
  ///
  /// In az, this message translates to:
  /// **'Ödənişlər'**
  String get navTuition;

  /// No description provided for @newsNoBody.
  ///
  /// In az, this message translates to:
  /// **'Bu xəbər üçün əlavə mətn yoxdur'**
  String get newsNoBody;

  /// No description provided for @newsTitle.
  ///
  /// In az, this message translates to:
  /// **'Xəbər'**
  String get newsTitle;

  /// No description provided for @noTransactions.
  ///
  /// In az, this message translates to:
  /// **'Hələ əməliyyat yoxdur'**
  String get noTransactions;

  /// No description provided for @notifPrefAttendance.
  ///
  /// In az, this message translates to:
  /// **'Davamiyyət'**
  String get notifPrefAttendance;

  /// No description provided for @notifPrefAttendanceText.
  ///
  /// In az, this message translates to:
  /// **'Uşağın məktəbə gəlişi və dərsdən çıxışı barədə bildirişlər.'**
  String get notifPrefAttendanceText;

  /// No description provided for @notifPrefBuffet.
  ///
  /// In az, this message translates to:
  /// **'Bufet'**
  String get notifPrefBuffet;

  /// No description provided for @notifPrefBuffetText.
  ///
  /// In az, this message translates to:
  /// **'Uşağın bufetdə nəyə xərclədiyi barədə bildirişlər.'**
  String get notifPrefBuffetText;

  /// No description provided for @notifPrefExams.
  ///
  /// In az, this message translates to:
  /// **'İmtahanlar'**
  String get notifPrefExams;

  /// No description provided for @notifPrefExamsText.
  ///
  /// In az, this message translates to:
  /// **'Uşağın imtahan nəticələri və imtahana girilməsi barədə bildirişlər.'**
  String get notifPrefExamsText;

  /// No description provided for @notificationFallback.
  ///
  /// In az, this message translates to:
  /// **'Bildiriş'**
  String get notificationFallback;

  /// No description provided for @notificationsEmpty.
  ///
  /// In az, this message translates to:
  /// **'Hələ bildiriş yoxdur.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsTitle.
  ///
  /// In az, this message translates to:
  /// **'Bildirişlər'**
  String get notificationsTitle;

  /// No description provided for @otpIncomplete.
  ///
  /// In az, this message translates to:
  /// **'Kod {count} rəqəmdən ibarətdir'**
  String otpIncomplete(int count);

  /// No description provided for @otpInvalid.
  ///
  /// In az, this message translates to:
  /// **'Kod yanlışdır və ya vaxtı bitib'**
  String get otpInvalid;

  /// No description provided for @otpLeaveBody.
  ///
  /// In az, this message translates to:
  /// **'Hesabınız yaradıldı, lakin e-mail təsdiqlənməyib. Kodu daxil etmədən hesaba daxil ola bilməyəcəksiniz.'**
  String get otpLeaveBody;

  /// No description provided for @otpLeaveExit.
  ///
  /// In az, this message translates to:
  /// **'Çıx'**
  String get otpLeaveExit;

  /// No description provided for @otpLeaveStay.
  ///
  /// In az, this message translates to:
  /// **'Kodu daxil et'**
  String get otpLeaveStay;

  /// No description provided for @otpLeaveTitle.
  ///
  /// In az, this message translates to:
  /// **'Təsdiqi yarımçıq qoymaq?'**
  String get otpLeaveTitle;

  /// No description provided for @otpRequired.
  ///
  /// In az, this message translates to:
  /// **'Təsdiq kodunu daxil edin'**
  String get otpRequired;

  /// No description provided for @otpResend.
  ///
  /// In az, this message translates to:
  /// **'Kodu yenidən göndər'**
  String get otpResend;

  /// No description provided for @otpResendIn.
  ///
  /// In az, this message translates to:
  /// **'Kodu yenidən göndər ({seconds} s)'**
  String otpResendIn(int seconds);

  /// No description provided for @otpResent.
  ///
  /// In az, this message translates to:
  /// **'Yeni kod e-mail ünvanınıza göndərildi'**
  String get otpResent;

  /// No description provided for @otpSpamHint.
  ///
  /// In az, this message translates to:
  /// **'Kod gəlmədi? Spam qovluğunu da yoxlayın.'**
  String get otpSpamHint;

  /// No description provided for @otpSubtitle.
  ///
  /// In az, this message translates to:
  /// **'{email} ünvanına 6 rəqəmli təsdiq kodu göndərdik.'**
  String otpSubtitle(String email);

  /// No description provided for @otpTitle.
  ///
  /// In az, this message translates to:
  /// **'E-mail təsdiqi'**
  String get otpTitle;

  /// No description provided for @otpVerified.
  ///
  /// In az, this message translates to:
  /// **'E-mail təsdiqləndi'**
  String get otpVerified;

  /// No description provided for @otpVerify.
  ///
  /// In az, this message translates to:
  /// **'Təsdiqlə'**
  String get otpVerify;

  /// No description provided for @overdueWithDate.
  ///
  /// In az, this message translates to:
  /// **'Gecikib · {date}'**
  String overdueWithDate(String date);

  /// No description provided for @payAtBankPage.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş bank səhifəsində tamamlanır.'**
  String get payAtBankPage;

  /// No description provided for @payNow.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş et'**
  String get payNow;

  /// No description provided for @payWithAmount.
  ///
  /// In az, this message translates to:
  /// **'Ödə · {amount}'**
  String payWithAmount(String amount);

  /// No description provided for @paymentChecking.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş yoxlanılır'**
  String get paymentChecking;

  /// No description provided for @paymentCouldNotStart.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş başladıla bilmədi'**
  String get paymentCouldNotStart;

  /// No description provided for @paymentCurrentBalance.
  ///
  /// In az, this message translates to:
  /// **'Cari balans'**
  String get paymentCurrentBalance;

  /// No description provided for @paymentStatusUnavailable.
  ///
  /// In az, this message translates to:
  /// **'Ödənişin statusu alınmadı'**
  String get paymentStatusUnavailable;

  /// No description provided for @paymentUnconfirmed.
  ///
  /// In az, this message translates to:
  /// **'Bank ödənişi qəbul etdi, lakin statusu təsdiqlənmədi. Məbləğ bir neçə dəqiqə ərzində hesabınıza işlənəcək — siyahını yeniləyib yoxlayın.'**
  String get paymentUnconfirmed;

  /// No description provided for @purchaseLabel.
  ///
  /// In az, this message translates to:
  /// **'Alış'**
  String get purchaseLabel;

  /// No description provided for @recentTransactions.
  ///
  /// In az, this message translates to:
  /// **'Son əməliyyatlar'**
  String get recentTransactions;

  /// No description provided for @registerAdmissionNote.
  ///
  /// In az, this message translates to:
  /// **'Qəbul nömrəsi şagird vəsiqəsində və məktəbin verdiyi qəbul sənədində yazılıb.'**
  String get registerAdmissionNote;

  /// No description provided for @registerDone.
  ///
  /// In az, this message translates to:
  /// **'Qeydiyyat tamamlandı. İndi hesabınıza daxil ola bilərsiniz.'**
  String get registerDone;

  /// No description provided for @registerHaveAccount.
  ///
  /// In az, this message translates to:
  /// **'Artıq hesabınız var?'**
  String get registerHaveAccount;

  /// No description provided for @registerName.
  ///
  /// In az, this message translates to:
  /// **'Ad Soyad'**
  String get registerName;

  /// No description provided for @registerNameHint.
  ///
  /// In az, this message translates to:
  /// **'Ad və soyadınız'**
  String get registerNameHint;

  /// No description provided for @registerNameRequired.
  ///
  /// In az, this message translates to:
  /// **'Ad və soyadınızı daxil edin'**
  String get registerNameRequired;

  /// No description provided for @registerNameShort.
  ///
  /// In az, this message translates to:
  /// **'Ad və soyadı tam yazın'**
  String get registerNameShort;

  /// No description provided for @registerPasswordHide.
  ///
  /// In az, this message translates to:
  /// **'Şifrəni gizlə'**
  String get registerPasswordHide;

  /// No description provided for @registerPasswordRepeat.
  ///
  /// In az, this message translates to:
  /// **'Şifrə (təkrar)'**
  String get registerPasswordRepeat;

  /// No description provided for @registerPasswordRequired.
  ///
  /// In az, this message translates to:
  /// **'Şifrə təyin edin'**
  String get registerPasswordRequired;

  /// No description provided for @registerPasswordShow.
  ///
  /// In az, this message translates to:
  /// **'Şifrəni göstər'**
  String get registerPasswordShow;

  /// No description provided for @registerPhone.
  ///
  /// In az, this message translates to:
  /// **'Telefon'**
  String get registerPhone;

  /// No description provided for @registerPhoneHint.
  ///
  /// In az, this message translates to:
  /// **'+994 50 123 45 67'**
  String get registerPhoneHint;

  /// No description provided for @registerPhoneInvalid.
  ///
  /// In az, this message translates to:
  /// **'Telefon nömrəsi düzgün deyil'**
  String get registerPhoneInvalid;

  /// No description provided for @registerPhoneRequired.
  ///
  /// In az, this message translates to:
  /// **'Telefon nömrəsini daxil edin'**
  String get registerPhoneRequired;

  /// No description provided for @registerSectionAccount.
  ///
  /// In az, this message translates to:
  /// **'Hesab məlumatları'**
  String get registerSectionAccount;

  /// No description provided for @registerSectionChild.
  ///
  /// In az, this message translates to:
  /// **'Övladınız'**
  String get registerSectionChild;

  /// No description provided for @registerSubmit.
  ///
  /// In az, this message translates to:
  /// **'Qeydiyyatdan keç'**
  String get registerSubmit;

  /// No description provided for @registerSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Valideyn hesabı yaradın'**
  String get registerSubtitle;

  /// No description provided for @registerTerms.
  ///
  /// In az, this message translates to:
  /// **'İstifadə şərtləri və məxfilik siyasəti ilə razıyam'**
  String get registerTerms;

  /// No description provided for @registerTermsRequired.
  ///
  /// In az, this message translates to:
  /// **'Davam etmək üçün istifadə şərtlərini qəbul edin'**
  String get registerTermsRequired;

  /// No description provided for @registerTitle.
  ///
  /// In az, this message translates to:
  /// **'Qeydiyyat'**
  String get registerTitle;

  /// No description provided for @settingsAddChild.
  ///
  /// In az, this message translates to:
  /// **'Yeni şagird əlavə et'**
  String get settingsAddChild;

  /// No description provided for @settingsAddChildSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Başqa övladınızı bu hesaba bağlayın'**
  String get settingsAddChildSubtitle;

  /// No description provided for @settingsChildCredentials.
  ///
  /// In az, this message translates to:
  /// **'Bu e-mail və şifrə ilə övladınız tətbiqə öz hesabı ilə daxil ola bilər. Kopyalayıb ona göndərə bilərsiniz.'**
  String get settingsChildCredentials;

  /// No description provided for @settingsLanguage.
  ///
  /// In az, this message translates to:
  /// **'Dil'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Tətbiqin dili'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLightMode.
  ///
  /// In az, this message translates to:
  /// **'Gündüz rejimi'**
  String get settingsLightMode;

  /// No description provided for @settingsLightModeSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Açıq rəngli interfeys'**
  String get settingsLightModeSubtitle;

  /// No description provided for @settingsLogout.
  ///
  /// In az, this message translates to:
  /// **'Çıxış'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In az, this message translates to:
  /// **'Hesabdan çıxmaq istədiyinizə əminsiniz?'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsLogoutSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Tətbiqdən çıxın'**
  String get settingsLogoutSubtitle;

  /// No description provided for @settingsMyChild.
  ///
  /// In az, this message translates to:
  /// **'Övladımın məlumatları'**
  String get settingsMyChild;

  /// No description provided for @settingsMyChildren.
  ///
  /// In az, this message translates to:
  /// **'Övladlarım ({count})'**
  String settingsMyChildren(int count);

  /// No description provided for @settingsNotifications.
  ///
  /// In az, this message translates to:
  /// **'Bildiriş parametrləri'**
  String get settingsNotifications;

  /// No description provided for @settingsTitle.
  ///
  /// In az, this message translates to:
  /// **'Tənzimləmələr'**
  String get settingsTitle;

  /// No description provided for @statusOverdue.
  ///
  /// In az, this message translates to:
  /// **'Gecikib'**
  String get statusOverdue;

  /// No description provided for @statusOverdueSuffix.
  ///
  /// In az, this message translates to:
  /// **'{status} · gecikib'**
  String statusOverdueSuffix(String status);

  /// No description provided for @statusPaid.
  ///
  /// In az, this message translates to:
  /// **'Ödənilib'**
  String get statusPaid;

  /// No description provided for @statusPartial.
  ///
  /// In az, this message translates to:
  /// **'Qismən'**
  String get statusPartial;

  /// No description provided for @statusUnpaid.
  ///
  /// In az, this message translates to:
  /// **'Ödənilməyib'**
  String get statusUnpaid;

  /// No description provided for @supportEmailSubject.
  ///
  /// In az, this message translates to:
  /// **'BSB tətbiqi — dəstək sorğusu'**
  String get supportEmailSubject;

  /// No description provided for @tAccountSettings.
  ///
  /// In az, this message translates to:
  /// **'Hesab tənzimləmələri'**
  String get tAccountSettings;

  /// No description provided for @tActiveDay.
  ///
  /// In az, this message translates to:
  /// **'Aktiv gün'**
  String get tActiveDay;

  /// No description provided for @tActiveHomeworks.
  ///
  /// In az, this message translates to:
  /// **'Aktiv tapşırıqlar'**
  String get tActiveHomeworks;

  /// No description provided for @tAssignHomework.
  ///
  /// In az, this message translates to:
  /// **'Tapşırıq təyin et'**
  String get tAssignHomework;

  /// No description provided for @tAssignTask.
  ///
  /// In az, this message translates to:
  /// **'Tapşırığı təyin et'**
  String get tAssignTask;

  /// No description provided for @tAttachDoc.
  ///
  /// In az, this message translates to:
  /// **'Sənəd əlavə etmək üçün toxunun (PDF / XLS)'**
  String get tAttachDoc;

  /// No description provided for @tAttachmentFile.
  ///
  /// In az, this message translates to:
  /// **'Əlavə fayl'**
  String get tAttachmentFile;

  /// No description provided for @tAttendanceCounts.
  ///
  /// In az, this message translates to:
  /// **'Gəlib: {present} | Qayıb: {absent} | Gecikib: {late}'**
  String tAttendanceCounts(int present, int absent, int late);

  /// No description provided for @tAttendanceSaved.
  ///
  /// In az, this message translates to:
  /// **'Davamiyyət yadda saxlanıldı!'**
  String get tAttendanceSaved;

  /// No description provided for @tAverageScore.
  ///
  /// In az, this message translates to:
  /// **'Orta bal'**
  String get tAverageScore;

  /// No description provided for @tBehaviourShort.
  ///
  /// In az, this message translates to:
  /// **'DAV.'**
  String get tBehaviourShort;

  /// No description provided for @tChangePin.
  ///
  /// In az, this message translates to:
  /// **'PIN kodu dəyiş'**
  String get tChangePin;

  /// No description provided for @tChoosePdf.
  ///
  /// In az, this message translates to:
  /// **'PDF / şəkil seçmək üçün toxunun'**
  String get tChoosePdf;

  /// No description provided for @tClassGroup.
  ///
  /// In az, this message translates to:
  /// **'Sinif qrupu'**
  String get tClassGroup;

  /// No description provided for @tComments.
  ///
  /// In az, this message translates to:
  /// **'Şərhlər / Müşahidələr'**
  String get tComments;

  /// No description provided for @tCommentsHint.
  ///
  /// In az, this message translates to:
  /// **'Qeyd və ya əlavə məlumat yazın...'**
  String get tCommentsHint;

  /// No description provided for @tCurrentlyAssigned.
  ///
  /// In az, this message translates to:
  /// **'Hazırda təyin olunmuş'**
  String get tCurrentlyAssigned;

  /// No description provided for @tDate.
  ///
  /// In az, this message translates to:
  /// **'Tarix'**
  String get tDate;

  /// No description provided for @tDescriptionHint.
  ///
  /// In az, this message translates to:
  /// **'Tapşırığın təfərrüatları...'**
  String get tDescriptionHint;

  /// No description provided for @tDescriptionTasks.
  ///
  /// In az, this message translates to:
  /// **'Təsvir / Tapşırıqlar'**
  String get tDescriptionTasks;

  /// No description provided for @tDocAttached.
  ///
  /// In az, this message translates to:
  /// **'Sənəd əlavə edildi!'**
  String get tDocAttached;

  /// No description provided for @tDocUploaded.
  ///
  /// In az, this message translates to:
  /// **'Hesabat sənədi yükləndi.'**
  String get tDocUploaded;

  /// No description provided for @tDueDate.
  ///
  /// In az, this message translates to:
  /// **'Son tarix'**
  String get tDueDate;

  /// No description provided for @tDueLabel.
  ///
  /// In az, this message translates to:
  /// **'Son tarix: {date}'**
  String tDueLabel(String date);

  /// No description provided for @tEditAttendance.
  ///
  /// In az, this message translates to:
  /// **'Davamiyyəti redaktə et'**
  String get tEditAttendance;

  /// No description provided for @tEditingMode.
  ///
  /// In az, this message translates to:
  /// **'Redaktə rejimi aktivdir.'**
  String get tEditingMode;

  /// No description provided for @tEffortShort.
  ///
  /// In az, this message translates to:
  /// **'SƏY'**
  String get tEffortShort;

  /// No description provided for @tEnterHomeworkTitle.
  ///
  /// In az, this message translates to:
  /// **'Tapşırığın adını yazın!'**
  String get tEnterHomeworkTitle;

  /// No description provided for @tEnterReportTitle.
  ///
  /// In az, this message translates to:
  /// **'Hesabatın adını yazın!'**
  String get tEnterReportTitle;

  /// No description provided for @tExamType.
  ///
  /// In az, this message translates to:
  /// **'İmtahan növü'**
  String get tExamType;

  /// No description provided for @tFileAttached.
  ///
  /// In az, this message translates to:
  /// **'Fayl əlavə edildi!'**
  String get tFileAttached;

  /// No description provided for @tGradeShort.
  ///
  /// In az, this message translates to:
  /// **'QİY.'**
  String get tGradeShort;

  /// No description provided for @tGradedStatus.
  ///
  /// In az, this message translates to:
  /// **'Qiymətləndirmə vəziyyəti'**
  String get tGradedStatus;

  /// No description provided for @tGrades.
  ///
  /// In az, this message translates to:
  /// **'Qiymətlər'**
  String get tGrades;

  /// No description provided for @tGradesPublished.
  ///
  /// In az, this message translates to:
  /// **'Qiymətlər dərc olundu!'**
  String get tGradesPublished;

  /// No description provided for @tHomeworkAssigned.
  ///
  /// In az, this message translates to:
  /// **'Tapşırıq təyin edildi!'**
  String get tHomeworkAssigned;

  /// No description provided for @tHomeworkDeleted.
  ///
  /// In az, this message translates to:
  /// **'Tapşırıq silindi.'**
  String get tHomeworkDeleted;

  /// No description provided for @tHomeworkTitle.
  ///
  /// In az, this message translates to:
  /// **'Tapşırığın adı'**
  String get tHomeworkTitle;

  /// No description provided for @tHomeworkTitleHint.
  ///
  /// In az, this message translates to:
  /// **'məs. Kvadrat tənliklər üzrə çalışmalar'**
  String get tHomeworkTitleHint;

  /// No description provided for @tKsqGrades.
  ///
  /// In az, this message translates to:
  /// **'KSQ qiymətləri'**
  String get tKsqGrades;

  /// No description provided for @tLanguageSelection.
  ///
  /// In az, this message translates to:
  /// **'Dil seçimi'**
  String get tLanguageSelection;

  /// No description provided for @tLanguageSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Tətbiq interfeysinin dili'**
  String get tLanguageSubtitle;

  /// No description provided for @tLanguageUpdated.
  ///
  /// In az, this message translates to:
  /// **'Dil dəyişdirildi'**
  String get tLanguageUpdated;

  /// No description provided for @tLightTheme.
  ///
  /// In az, this message translates to:
  /// **'Açıq tema'**
  String get tLightTheme;

  /// No description provided for @tLogoutConfirm.
  ///
  /// In az, this message translates to:
  /// **'Sessiyadan çıxmaq istəyirsiniz?'**
  String get tLogoutConfirm;

  /// No description provided for @tLogoutSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Sessiyadan təhlükəsiz çıxın'**
  String get tLogoutSubtitle;

  /// No description provided for @tMaxPoints.
  ///
  /// In az, this message translates to:
  /// **'Maksimum: 100 bal'**
  String get tMaxPoints;

  /// No description provided for @tNextLesson.
  ///
  /// In az, this message translates to:
  /// **'Növbəti dərs'**
  String get tNextLesson;

  /// No description provided for @tNoLessonsToday.
  ///
  /// In az, this message translates to:
  /// **'Bu gün üçün dərs planlanmayıb.'**
  String get tNoLessonsToday;

  /// No description provided for @tNotifUpdated.
  ///
  /// In az, this message translates to:
  /// **'Bildiriş parametrləri yeniləndi'**
  String get tNotifUpdated;

  /// No description provided for @tPinLoading.
  ///
  /// In az, this message translates to:
  /// **'PIN dəyişmə ekranı açılır...'**
  String get tPinLoading;

  /// No description provided for @tPinSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Turniket və giriş üçün təhlükəsizlik PIN-i'**
  String get tPinSubtitle;

  /// No description provided for @tPostGrades.
  ///
  /// In az, this message translates to:
  /// **'İmtahan qiymətlərini yerləşdir'**
  String get tPostGrades;

  /// No description provided for @tPreferences.
  ///
  /// In az, this message translates to:
  /// **'Tərcihlər'**
  String get tPreferences;

  /// No description provided for @tPublishGrades.
  ///
  /// In az, this message translates to:
  /// **'Qiymətləri dərc et'**
  String get tPublishGrades;

  /// No description provided for @tPushNotifications.
  ///
  /// In az, this message translates to:
  /// **'Push bildirişlər'**
  String get tPushNotifications;

  /// No description provided for @tPushSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Qiymət xəbərdarlıqları, cədvəl yenilikləri'**
  String get tPushSubtitle;

  /// No description provided for @tRecentUploads.
  ///
  /// In az, this message translates to:
  /// **'Son yükləmələr'**
  String get tRecentUploads;

  /// No description provided for @tReportDocument.
  ///
  /// In az, this message translates to:
  /// **'Hesabat sənədi'**
  String get tReportDocument;

  /// No description provided for @tReportHintStudent.
  ///
  /// In az, this message translates to:
  /// **'məs. Samir Əliyev — davranış və iş rəyi'**
  String get tReportHintStudent;

  /// No description provided for @tReportHintWeekly.
  ///
  /// In az, this message translates to:
  /// **'məs. 14-cü həftə riyaziyyat üzrə irəliləyiş'**
  String get tReportHintWeekly;

  /// No description provided for @tReportSubmitted.
  ///
  /// In az, this message translates to:
  /// **'Hesabat göndərildi!'**
  String get tReportSubmitted;

  /// No description provided for @tReportTitle.
  ///
  /// In az, this message translates to:
  /// **'Hesabatın adı'**
  String get tReportTitle;

  /// No description provided for @tReports.
  ///
  /// In az, this message translates to:
  /// **'Hesabatlar'**
  String get tReports;

  /// No description provided for @tSaveAttendance.
  ///
  /// In az, this message translates to:
  /// **'Davamiyyəti yadda saxla'**
  String get tSaveAttendance;

  /// No description provided for @tSeeAll.
  ///
  /// In az, this message translates to:
  /// **'Hamısına bax'**
  String get tSeeAll;

  /// No description provided for @tStudentAttendance.
  ///
  /// In az, this message translates to:
  /// **'Şagird davamiyyəti'**
  String get tStudentAttendance;

  /// No description provided for @tStudentGrades.
  ///
  /// In az, this message translates to:
  /// **'Şagird qiymətləri'**
  String get tStudentGrades;

  /// No description provided for @tStudentInfo.
  ///
  /// In az, this message translates to:
  /// **'ŞAGİRD'**
  String get tStudentInfo;

  /// No description provided for @tStudentList.
  ///
  /// In az, this message translates to:
  /// **'Şagird siyahısı'**
  String get tStudentList;

  /// No description provided for @tStudentReportFor.
  ///
  /// In az, this message translates to:
  /// **'{name} üçün şagird hesabatı'**
  String tStudentReportFor(String name);

  /// No description provided for @tStudentReports.
  ///
  /// In az, this message translates to:
  /// **'Şagird hesabatları'**
  String get tStudentReports;

  /// No description provided for @tSubmissionHistory.
  ///
  /// In az, this message translates to:
  /// **'Göndərmə tarixçəsi'**
  String get tSubmissionHistory;

  /// No description provided for @tSubmitReport.
  ///
  /// In az, this message translates to:
  /// **'Hesabatı göndər'**
  String get tSubmitReport;

  /// No description provided for @tTargetStudent.
  ///
  /// In az, this message translates to:
  /// **'Hədəf şagird'**
  String get tTargetStudent;

  /// No description provided for @tTaskManagement.
  ///
  /// In az, this message translates to:
  /// **'Tapşırıq idarəetməsi'**
  String get tTaskManagement;

  /// No description provided for @tUploadReports.
  ///
  /// In az, this message translates to:
  /// **'Hesabat yüklə'**
  String get tUploadReports;

  /// No description provided for @tWeeklyReports.
  ///
  /// In az, this message translates to:
  /// **'Həftəlik hesabatlar'**
  String get tWeeklyReports;

  /// No description provided for @tWeeklyTimetable.
  ///
  /// In az, this message translates to:
  /// **'Həftəlik dərs cədvəli'**
  String get tWeeklyTimetable;

  /// No description provided for @tWelcomeBack.
  ///
  /// In az, this message translates to:
  /// **'Xoş gəldiniz,'**
  String get tWelcomeBack;

  /// No description provided for @timetableEmpty.
  ///
  /// In az, this message translates to:
  /// **'Bu gün üçün dərs yoxdur'**
  String get timetableEmpty;

  /// No description provided for @timetableGroupPrefix.
  ///
  /// In az, this message translates to:
  /// **'Qrup: '**
  String get timetableGroupPrefix;

  /// No description provided for @timetableTeacherLabel.
  ///
  /// In az, this message translates to:
  /// **'Müəllim: {name}'**
  String timetableTeacherLabel(String name);

  /// No description provided for @topUpCardSection.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş kartı'**
  String get topUpCardSection;

  /// No description provided for @tuitionAmountInvalid.
  ///
  /// In az, this message translates to:
  /// **'Məbləği düzgün daxil edin'**
  String get tuitionAmountInvalid;

  /// No description provided for @tuitionAmountOther.
  ///
  /// In az, this message translates to:
  /// **'Başqa məbləğ'**
  String get tuitionAmountOther;

  /// No description provided for @tuitionAmountOtherHint.
  ///
  /// In az, this message translates to:
  /// **'İstədiyiniz məbləği yazın'**
  String get tuitionAmountOtherHint;

  /// No description provided for @tuitionAmountSheetHint.
  ///
  /// In az, this message translates to:
  /// **'Təklif olunan məbləği seçin və ya özünüz yazın.'**
  String get tuitionAmountSheetHint;

  /// No description provided for @tuitionAmountSheetTitle.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş məbləği'**
  String get tuitionAmountSheetTitle;

  /// No description provided for @tuitionAmountTooSmall.
  ///
  /// In az, this message translates to:
  /// **'Məbləğ 0-dan böyük olmalıdır'**
  String get tuitionAmountTooSmall;

  /// No description provided for @tuitionColumnAmount.
  ///
  /// In az, this message translates to:
  /// **'ÖDƏNİŞ MƏBLƏĞİ'**
  String get tuitionColumnAmount;

  /// No description provided for @tuitionColumnDate.
  ///
  /// In az, this message translates to:
  /// **'ÖDƏNİŞ TARİXİ'**
  String get tuitionColumnDate;

  /// No description provided for @tuitionColumnStatus.
  ///
  /// In az, this message translates to:
  /// **'STATUS'**
  String get tuitionColumnStatus;

  /// No description provided for @tuitionCredit.
  ///
  /// In az, this message translates to:
  /// **'Artıq ödənilmiş məbləğ'**
  String get tuitionCredit;

  /// No description provided for @tuitionCreditAmount.
  ///
  /// In az, this message translates to:
  /// **'Hesabda artıq: {amount}'**
  String tuitionCreditAmount(String amount);

  /// No description provided for @tuitionCurrentMonth.
  ///
  /// In az, this message translates to:
  /// **'Cari ay üçün ödəniş'**
  String get tuitionCurrentMonth;

  /// No description provided for @tuitionDueNowAmount.
  ///
  /// In az, this message translates to:
  /// **'İndi ödənilməli: {amount}'**
  String tuitionDueNowAmount(String amount);

  /// No description provided for @tuitionHistoryTitle.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş tarixçəsi'**
  String get tuitionHistoryTitle;

  /// No description provided for @tuitionInstalmentsCount.
  ///
  /// In az, this message translates to:
  /// **'{count} taksit üzrə'**
  String tuitionInstalmentsCount(int count);

  /// No description provided for @tuitionLateFee.
  ///
  /// In az, this message translates to:
  /// **'Gecikmə cəriməsi'**
  String get tuitionLateFee;

  /// No description provided for @tuitionLateFeeHint.
  ///
  /// In az, this message translates to:
  /// **'Gecikmə üzrə'**
  String get tuitionLateFeeHint;

  /// No description provided for @tuitionNoDate.
  ///
  /// In az, this message translates to:
  /// **'Tarix yoxdur'**
  String get tuitionNoDate;

  /// No description provided for @tuitionNoDebt.
  ///
  /// In az, this message translates to:
  /// **'Borc yoxdur. Öncədən ödəniş edə bilərsiniz.'**
  String get tuitionNoDebt;

  /// No description provided for @tuitionNoLateFee.
  ///
  /// In az, this message translates to:
  /// **'Gecikmə yoxdur'**
  String get tuitionNoLateFee;

  /// No description provided for @tuitionNothingDueYet.
  ///
  /// In az, this message translates to:
  /// **'Vaxtı çatmış borc yoxdur.'**
  String get tuitionNothingDueYet;

  /// No description provided for @tuitionPayDueNow.
  ///
  /// In az, this message translates to:
  /// **'İndi ödənilməli'**
  String get tuitionPayDueNow;

  /// No description provided for @tuitionPayDueNowHint.
  ///
  /// In az, this message translates to:
  /// **'Vaxtı çatmış borc'**
  String get tuitionPayDueNowHint;

  /// No description provided for @tuitionPayFull.
  ///
  /// In az, this message translates to:
  /// **'Tam borc'**
  String get tuitionPayFull;

  /// No description provided for @tuitionPayFullHint.
  ///
  /// In az, this message translates to:
  /// **'Bütün qalıq borc'**
  String get tuitionPayFullHint;

  /// No description provided for @tuitionPaySection.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş bölməsi'**
  String get tuitionPaySection;

  /// No description provided for @tuitionRingLabel.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş'**
  String get tuitionRingLabel;

  /// No description provided for @tuitionScheduleClosed.
  ///
  /// In az, this message translates to:
  /// **'Cədvəl bağlanıb'**
  String get tuitionScheduleClosed;

  /// No description provided for @tuitionScheduleEmpty.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş cədvəli tapılmadı'**
  String get tuitionScheduleEmpty;

  /// No description provided for @tuitionScheduleTitle.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş Cədvəli'**
  String get tuitionScheduleTitle;

  /// No description provided for @tuitionTabExtra.
  ///
  /// In az, this message translates to:
  /// **'Əlavə ödənişlər'**
  String get tuitionTabExtra;

  /// No description provided for @tuitionTabTuition.
  ///
  /// In az, this message translates to:
  /// **'Təhsil haqqı'**
  String get tuitionTabTuition;

  /// No description provided for @tuitionTitle.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş cədvəli'**
  String get tuitionTitle;

  /// No description provided for @tuitionTotalDue.
  ///
  /// In az, this message translates to:
  /// **'Ümumi qalıq'**
  String get tuitionTotalDue;

  /// No description provided for @webviewLoadFailed.
  ///
  /// In az, this message translates to:
  /// **'Səhifə yüklənmədi'**
  String get webviewLoadFailed;

  /// No description provided for @webviewStopText.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş tamamlanmayıb. Səhifəni bağlamaq istəyirsiniz?'**
  String get webviewStopText;

  /// No description provided for @webviewStopTitle.
  ///
  /// In az, this message translates to:
  /// **'Ödənişi dayandırmaq'**
  String get webviewStopTitle;

  /// No description provided for @webviewTitle.
  ///
  /// In az, this message translates to:
  /// **'Ödəniş'**
  String get webviewTitle;

  /// No description provided for @weeklyLessonCount.
  ///
  /// In az, this message translates to:
  /// **'{count} dərs'**
  String weeklyLessonCount(int count);

  /// No description provided for @weeklyTeacherRoom.
  ///
  /// In az, this message translates to:
  /// **'{teacher} • Otaq {room}'**
  String weeklyTeacherRoom(String teacher, String room);
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['az', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppL10nAz();
    case 'en':
      return AppL10nEn();
    case 'ru':
      return AppL10nRu();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
