// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppL10nAz extends AppL10n {
  AppL10nAz([String locale = 'az']) : super(locale);

  @override
  String get addChildAdded => 'Şagird hesabınıza əlavə edildi';

  @override
  String get addChildAnotherText =>
      'Övladınızın qəbul nömrəsini daxil edin — şagird hesabınıza bağlanacaq və bütün məlumatlarını buradan izləyəcəksiniz.';

  @override
  String get addChildEnterNumber => 'Qəbul nömrəsini daxil edin';

  @override
  String get addChildField => 'Qəbul nömrəsi';

  @override
  String get addChildHint => 'Övladınızın sistem ID-si';

  @override
  String get addChildOtherAccount => 'Başqa hesabla daxil ol';

  @override
  String get addChildSubmit => 'Əlavə et';

  @override
  String get addChildText =>
      'Hesabınıza hələ şagird bağlanmayıb. Davam etmək üçün övladınızın qəbul nömrəsini daxil edin.';

  @override
  String addChildTextNamed(String name) {
    return '$name, hesabınıza hələ şagird bağlanmayıb. Davam etmək üçün övladınızın qəbul nömrəsini daxil edin.';
  }

  @override
  String get addChildTitle => 'Şagirdinizi əlavə edin';

  @override
  String get addChildWhere1 => 'Şagird vəsiqəsinin üzərində';

  @override
  String get addChildWhere2 => 'Məktəbin verdiyi qəbul sənədində';

  @override
  String get addChildWhere3 => 'Məktəbin katibliyindən soruşa bilərsiniz';

  @override
  String get addChildWhereTitle => 'Qəbul nömrəsi haradadır?';

  @override
  String get amountEnterValid => 'Məbləği düzgün yazın';

  @override
  String amountRange(String min, String max) {
    return 'Məbləğ $min–$max ₼ aralığında olmalıdır';
  }

  @override
  String get appTitle => 'BSB School';

  @override
  String get attendanceAbsent => 'Qayıb';

  @override
  String get attendanceEmpty => 'Qeyd tapılmadı';

  @override
  String get attendanceLate => 'Gecikmə';

  @override
  String get attendanceLateTag => 'Gecikib';

  @override
  String get attendanceMixed => 'Qarışıq';

  @override
  String get attendanceLesson => 'Dərs';

  @override
  String attendanceMonthOverview(String month) {
    return '$month ayı üzrə icmal';
  }

  @override
  String get attendancePresent => 'Gəlib';

  @override
  String get attendanceRate => 'İştirak';

  @override
  String get attendanceRecent => 'Son qeydlər';

  @override
  String get attendanceTitle => 'Davamiyyət';

  @override
  String get balanceAmountField => 'Məbləğ (AZN)';

  @override
  String get balanceCurrent => 'Mövcud balans';

  @override
  String get balanceCustomAmount => 'Xüsusi məbləğ';

  @override
  String get balanceInvalidAmount => 'Düzgün məbləğ daxil edin';

  @override
  String get balanceLabel => 'Balans';

  @override
  String get balanceQuickTopUp => 'Sürətli artırma';

  @override
  String get balanceTopUp => 'Balansı artır';

  @override
  String get balanceTopUps => 'Balans artımları';

  @override
  String bookDeleteText(String location) {
    return 'Kitab telefondan və \"$location\" bölməsindən silinəcək. İnternet olduqda yenidən oxuya bilərsiniz.';
  }

  @override
  String get bookDeleteTitle => 'Yüklənmiş faylı sil?';

  @override
  String get bookDeleted => 'Yüklənmiş fayl silindi';

  @override
  String get bookDownloadFailed => 'Yükləmə alınmadı';

  @override
  String bookDownloaded(String location) {
    return 'Kitab \"$location\" bölməsinə yükləndi';
  }

  @override
  String bookDownloadedPartial(String location) {
    return 'Kitab yükləndi, ancaq \"$location\" bölməsinə yazıla bilmədi';
  }

  @override
  String get bookNoFile => 'Bu kitabın faylı yoxdur';

  @override
  String bookOpenFailed(String reason) {
    return 'Kitab açılmadı: $reason';
  }

  @override
  String get buffetOrder => 'Sifariş et';

  @override
  String buffetProductCount(int count) {
    return '$count məhsul';
  }

  @override
  String get cafeteriaDailyLimit => 'Günlük limit';

  @override
  String get cafeteriaSpent => 'Xərclənib';

  @override
  String get cardExpiry => 'Müddət';

  @override
  String get cardHolder => 'Kart Sahibinin Adı';

  @override
  String get cardHolderHint => 'AD VƏ SOYAD';

  @override
  String get cardNumberField => 'Kartın nömrəsi';

  @override
  String get cardNumberLabel => 'Kart nömrəsi';

  @override
  String get commonAll => 'Hamısı';

  @override
  String get commonCancel => 'Ləğv et';

  @override
  String get commonClose => 'Bağla';

  @override
  String get commonConfirm => 'Təsdiqlə';

  @override
  String get commonContinue => 'Davam et';

  @override
  String get commonCopy => 'Kopyala';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonError => 'Xəta baş verdi';

  @override
  String get commonErrorShort => 'Xəta';

  @override
  String get commonFilter => 'Filtr';

  @override
  String get commonHide => 'Gizlət';

  @override
  String get commonNo => 'Xeyr';

  @override
  String get commonNoData => 'Məlumat tapılmadı';

  @override
  String get commonRetry => 'Yenidən cəhd et';

  @override
  String get commonSave => 'Yadda saxla';

  @override
  String get commonSearch => 'Axtar';

  @override
  String get commonSelectStudent => 'Şagird seç';

  @override
  String get commonShow => 'Göstər';

  @override
  String get commonYes => 'Bəli';

  @override
  String copiedToClipboard(String label) {
    return '$label kopyalandı';
  }

  @override
  String get credentialActive => 'Aktiv';

  @override
  String get credentialPaymentId => 'Ödəniş ID';

  @override
  String get credentialSwitchTo => 'Bu şagirdə keç';

  @override
  String get credentialSwitching => 'Dəyişdirilir…';

  @override
  String get credentialUsername => 'Username';

  @override
  String dailyUsage(String used, String limit) {
    return 'Günlük: $used/$limit';
  }

  @override
  String dashGreeting(String name) {
    return '$name 👋';
  }

  @override
  String get dashNewsFailed => 'Xəbərlər yüklənmədi';

  @override
  String get dashSeeAll => 'Hamısına bax';

  @override
  String get downloadsFiles => 'Fayllar';

  @override
  String get downloadsFolder => 'Yükləmələr';

  @override
  String dueDateLabel(String date) {
    return 'Son tarix: $date';
  }

  @override
  String dueDateOverdueLabel(String date) {
    return 'Son tarix: $date · gecikib';
  }

  @override
  String get errAttendanceLoad => 'Davamiyyət yüklənmədi';

  @override
  String get errBalanceUpdate => 'Balans yenilənmədi';

  @override
  String get errBuffetCardLoad => 'Bufet kartı yüklənmədi';

  @override
  String get errCache => 'Keş xətası baş verdi';

  @override
  String get errChildNotSwitched => 'Şagird dəyişdirilmədi';

  @override
  String get errChildNotYours => 'Bu şagird sizin hesabınıza aid deyil';

  @override
  String get errChildNotYoursShort => 'Bu şagird hesabınıza aid deyil';

  @override
  String get errEventsLoad => 'Tədbirlər yüklənmədi';

  @override
  String get errExamLoad => 'İmtahan nəticələri yüklənmədi';

  @override
  String get errExtraFeesLoad => 'Əlavə ödənişlər yüklənmədi';

  @override
  String get errHomeworkLoad => 'Tapşırıqlar yüklənmədi';

  @override
  String get errWeeklyFeedbackLoad => 'Həftəlik rəylər yüklənmədi';

  @override
  String get errInsufficientBalance => 'Balans kifayət etmir';

  @override
  String get errInvalid => 'Yanlış əməliyyat';

  @override
  String get errLibraryLoad => 'Kitabxana məlumatları yüklənmədi';

  @override
  String get errNewsLoad => 'Xəbərlər yüklənmədi';

  @override
  String get errNoConnection => 'Serverə qoşulmaq mümkün olmadı';

  @override
  String get errNoInternet => 'İnternet bağlantısı yoxdur';

  @override
  String get errNotificationsLoad => 'Bildirişlər yüklənmədi';

  @override
  String get errOrderFailed => 'Sifariş göndərilə bilmədi';

  @override
  String get errPaymentGateway => 'Ödəniş sistemi ilə əlaqə qurulmadı';

  @override
  String get errPaymentLink => 'Ödəniş linki alınmadı';

  @override
  String get errServer => 'Server xətası baş verdi';

  @override
  String get errSessionExpired => 'Sessiya bitib, yenidən daxil olun';

  @override
  String get errStudentNotFound => 'Şagird tapılmadı';

  @override
  String get errTimetableLoad => 'Dərs cədvəli yüklənmədi';

  @override
  String get errTokenMissing => 'Token cavabda tapılmadı';

  @override
  String get errTuitionLoad => 'Ödəniş məlumatları yüklənmədi';

  @override
  String get errUserNotFound => 'Bu e-mail ilə istifadəçi tapılmadı';

  @override
  String get errWrongCredentials => 'E-mail və ya şifrə yanlışdır';

  @override
  String eventsMore(int count) {
    return 'və daha $count tədbir';
  }

  @override
  String get eventsNoneToday => 'Bu gün üçün tədbir yoxdur';

  @override
  String get examAllResults => 'Bütün nəticələr';

  @override
  String examBehaviourLabel(String value) {
    return 'Davranış: $value';
  }

  @override
  String examEffortLabel(String value) {
    return 'Səy: $value';
  }

  @override
  String get examEmpty => 'İmtahan nəticəsi tapılmadı';

  @override
  String get examExam => 'İmtahan';

  @override
  String get examFilters => 'Filtrlər';

  @override
  String examGradeLabel(String value) {
    return 'Grade: $value';
  }

  @override
  String get examGroup => 'İmtahan qrupu';

  @override
  String get examNoMatch => 'Seçilmiş filtrlərə uyğun nəticə yoxdur';

  @override
  String get examNoStudent => 'Şagird təyin edilməyib';

  @override
  String get examNotGraded => 'Qiymətləndirilməyib';

  @override
  String get examReset => 'Sıfırla';

  @override
  String get examResetFilters => 'Filtrləri sıfırla';

  @override
  String get examResults => 'Nəticələr';

  @override
  String examShowResults(int count) {
    return 'Nəticələri göstər ($count)';
  }

  @override
  String get examTitle => 'İmtahan nəticələri';

  @override
  String get extraFeeAmount => 'Məbləğ';

  @override
  String get extraFeeFallbackTitle => 'Əlavə ödəniş';

  @override
  String get extraFeeNoDueDate => 'Son tarix yoxdur';

  @override
  String get extraFeePaid => 'Ödənilmiş';

  @override
  String get extraFeeRemaining => 'Qalıq';

  @override
  String get extraFeesAllDone => 'Bütün əlavə ödənişlər tamamlanıb.';

  @override
  String get extraFeesAllPaid => 'Hamısı ödənilib';

  @override
  String extraFeesCountLabel(int count) {
    return '$count əlavə ödəniş';
  }

  @override
  String get extraFeesEmpty => 'Əlavə ödəniş yoxdur';

  @override
  String get extraFeesListTitle => 'Əlavə ödənişlər';

  @override
  String get extraFeesNoPayment => 'Ödəniş yoxdur';

  @override
  String get extraFeesOutstanding => 'Qalıq borc';

  @override
  String get extraFeesOverdueCount => 'Gecikmiş ödəniş';

  @override
  String extraFeesOverdueDebt(String amount) {
    return 'Gecikmiş ödəniş var — $amount borc qalıb.';
  }

  @override
  String get extraFeesOverdueHint => 'Vaxtı keçib';

  @override
  String get extraFeesPaidAmount => 'Ödənilmiş məbləğ';

  @override
  String get extraFeesPayEachSeparately =>
      'Hər ödəniş ayrıca aparılır — aşağıdakı siyahıdan seçin.';

  @override
  String extraFeesPayableAmount(String amount) {
    return 'Ödənilməli məbləğ: $amount';
  }

  @override
  String extraFeesPendingCount(int count) {
    return '$count ödəniş gözləyir';
  }

  @override
  String extraFeesProgressDone(int percent) {
    return '$percent% tamamlanıb';
  }

  @override
  String get extraFeesTotal => 'Ümumi məbləğ';

  @override
  String get featureAttendance => 'Davamiyyət';

  @override
  String get featureBuffet => 'Bufet';

  @override
  String get featureCalendar => 'Təqvim';

  @override
  String get featureExaminations => 'İmtahanlar';

  @override
  String get featureHomework => 'Ev tapşırığı';

  @override
  String get featureLibrary => 'Kitabxana';

  @override
  String get featureLiveLessons => 'Onlayn dərslər';

  @override
  String get featureTimetable => 'Dərs cədvəli';

  @override
  String get featureWeeklyPlan => 'Həftəlik plan';

  @override
  String get featureWeeklyFeedback => 'Həftəlik rəy';

  @override
  String get fileCouldNotOpen => 'Fayl açıla bilmədi';

  @override
  String get fileDownload => 'Faylı yüklə';

  @override
  String get foodCardEmpty => 'Bufet kartı tapılmadı';

  @override
  String get foodCardTitle => 'Bufet Kartım';

  @override
  String get filterFrom => 'Başlanğıc';

  @override
  String get filterTo => 'Son';

  @override
  String get forgotBackToCode => 'Kodu yenidən daxil et';

  @override
  String get forgotChangeEmail => 'E-mail ünvanını dəyiş';

  @override
  String get forgotDone =>
      'Şifrəniz yeniləndi. Yeni şifrə ilə daxil ola bilərsiniz.';

  @override
  String get forgotEmailField => 'E-mail ünvanı';

  @override
  String get forgotEmailInvalid => 'E-mail ünvanı düzgün deyil';

  @override
  String get forgotEmailRequired => 'E-mail ünvanını daxil edin';

  @override
  String forgotMinLength(int count) {
    return 'Şifrə ən azı $count simvol olmalıdır.';
  }

  @override
  String get forgotNewPassword => 'Yeni şifrə';

  @override
  String get forgotPasswordMismatch => 'Şifrələr eyni deyil';

  @override
  String get forgotPasswordRequired => 'Yeni şifrəni daxil edin';

  @override
  String forgotPasswordShort(int count) {
    return 'Şifrə ən azı $count simvol olmalıdır';
  }

  @override
  String get forgotRepeatPassword => 'Yeni şifrə (təkrar)';

  @override
  String get forgotSendCode => 'Kodu göndər';

  @override
  String get forgotSetPasswordText =>
      'E-mail təsdiqləndi. İndi yeni şifrənizi təyin edin.';

  @override
  String get forgotSubmit => 'Şifrəni yenilə';

  @override
  String get forgotText =>
      'Qeydiyyatdan keçdiyiniz e-mail ünvanını daxil edin. Təsdiq kodunu həmin ünvana göndərəcəyik.';

  @override
  String get forgotTitle => 'Şifrənin bərpası';

  @override
  String get historyCanteen => 'Yeməkxana';

  @override
  String get historyIncome => 'Mədaxil';

  @override
  String get historyOther => 'Digər';

  @override
  String get historyTitle => 'Tarixçə';

  @override
  String get historyTuition => 'Təhsil';

  @override
  String get homeSections => 'Bölmələr';

  @override
  String get homeworkActive => 'Aktiv';

  @override
  String homeworkDaysLeft(int days) {
    return '$days gün qalıb';
  }

  @override
  String get homeworkDuePrefix => 'Son tarix: ';

  @override
  String get homeworkInactive => 'Deaktiv';

  @override
  String get homeworkNoActive => 'Aktiv tapşırıq yoxdur';

  @override
  String get homeworkNoClass => 'Sinif təyin edilməyib';

  @override
  String get homeworkNoInactive => 'Deaktiv tapşırıq yoxdur';

  @override
  String get homeworkOverdue => 'Gecikmiş';

  @override
  String get homeworkTitle => 'Tapşırıqlar';

  @override
  String get homeworkToday => 'Bu gün';

  @override
  String get homeworkTomorrow => 'Sabah';

  @override
  String get hwDetailDescription => 'Təsvir';

  @override
  String get hwDetailInfo => 'Məlumat';

  @override
  String get hwDetailTitle => 'Tapşırıq';

  @override
  String get hwDueDate => 'Son tarix';

  @override
  String get hwGivenDate => 'Verilmə tarixi';

  @override
  String get hwGrading => 'Qiymətləndirmə';

  @override
  String get hwSection => 'Bölmə';

  @override
  String get hwSubject => 'Fənn';

  @override
  String get hwTeacher => 'Müəllim';

  @override
  String get hwSubmitted => 'Təhvil verilib';

  @override
  String get hwSubmission => 'Təhvil';

  @override
  String get hwStatus => 'Status';

  @override
  String get hwMarkedAt => 'Qeyd edilib';

  @override
  String get hwGrade => 'Qiymət';

  @override
  String get hwNotes => 'Qeyd';

  @override
  String get hwTeacherComment => 'Müəllimin rəyi';

  @override
  String get hwSubmissionFile => 'Təhvil faylını yüklə';

  @override
  String get languageAz => 'Azərbaycan dili';

  @override
  String get languageEn => 'İngilis dili';

  @override
  String get languagePickSubtitle =>
      'Bunu sonra tənzimləmələrdən dəyişə bilərsiniz.';

  @override
  String get languagePickTitle => 'Dilinizi seçin';

  @override
  String get languageRu => 'Rus dili';

  @override
  String get languageSystem => 'Sistem dili';

  @override
  String lastPaymentLabel(String date) {
    return 'Son ödəniş: $date';
  }

  @override
  String get libraryEmpty => 'Kitab tapılmadı';

  @override
  String get librarySchoolPaid => '£19.99 məktəb tərəfindən ödənilib';

  @override
  String get librarySearch => 'Axtarış...';

  @override
  String get libraryTitle => 'Kitabxana';

  @override
  String libraryTitleWithClass(String className) {
    return 'Kitabxana • $className';
  }

  @override
  String get liveBadge => 'Canlı';

  @override
  String get liveJoin => 'Dərsə qoşul';

  @override
  String get liveLessonsTitle => 'Canlı Dərslər';

  @override
  String get liveRoomClosed => 'Otaq hələ açılmayıb';

  @override
  String get liveStartingNow => 'İndi başlayır';

  @override
  String get liveUpcoming => 'Gözlənilən dərslər';

  @override
  String get loginCall => 'Zəng et';

  @override
  String get loginCannotOpen => 'Bu əməliyyat cihazda açıla bilmədi';

  @override
  String get loginEmail => 'E-mail';

  @override
  String get loginEnterCredentials => 'E-mail və şifrəni daxil edin';

  @override
  String get loginForgotPassword => 'Şifrəni unutmusunuz?';

  @override
  String get loginNoAccount => 'Hesabınız yoxdur?';

  @override
  String get loginPassword => 'Şifrə';

  @override
  String get loginPasswordUpdated =>
      'Şifrəniz yeniləndi. Yeni şifrə ilə daxil olun.';

  @override
  String get loginRegister => 'Qeydiyyatdan keçin';

  @override
  String get loginSendEmail => 'E-mail göndər';

  @override
  String get loginSubmit => 'Daxil ol';

  @override
  String get loginSubtitle => 'Davam etmək üçün daxil olun';

  @override
  String get loginSupport => 'Dəstək ilə əlaqə';

  @override
  String get loginSupportText =>
      'Daxil ola bilmirsinizsə və ya sualınız varsa, bizimlə əlaqə saxlayın.';

  @override
  String get loginWelcome => 'Xoş gəlmisiniz';

  @override
  String get navAttendance => 'Davamiyyət';

  @override
  String get navFoodCard => 'Yemək kartı';

  @override
  String get navHome => 'Ana səhifə';

  @override
  String get navHomework => 'Ev tapşırığı';

  @override
  String get navNotifications => 'Bildirişlər';

  @override
  String get navProfile => 'Profil';

  @override
  String get navSettings => 'Tənzimləmələr';

  @override
  String get navTimetable => 'Dərs cədvəli';

  @override
  String get navTuition => 'Ödənişlər';

  @override
  String get newsNoBody => 'Bu xəbər üçün əlavə mətn yoxdur';

  @override
  String get newsTitle => 'Xəbər';

  @override
  String get noTopUps => 'Hələ balans artımı yoxdur';

  @override
  String get noTransactions => 'Hələ əməliyyat yoxdur';

  @override
  String get noTransactionsInRange => 'Bu tarixlərdə əməliyyat yoxdur';

  @override
  String get notifPrefAttendance => 'Davamiyyət';

  @override
  String get notifPrefAttendanceText =>
      'Uşağın məktəbə gəlişi və dərsdən çıxışı barədə bildirişlər.';

  @override
  String get notifPrefBuffet => 'Bufet';

  @override
  String get notifPrefBuffetText =>
      'Uşağın bufetdə nəyə xərclədiyi barədə bildirişlər.';

  @override
  String get notifPrefExams => 'İmtahanlar';

  @override
  String get notifPrefExamsText =>
      'Uşağın imtahan nəticələri və imtahana girilməsi barədə bildirişlər.';

  @override
  String get notifPrefHomework => 'Ev tapşırıqları';

  @override
  String get notifPrefHomeworkText =>
      'Uşağa verilən yeni ev tapşırıqları və onların son tarixi barədə bildirişlər.';

  @override
  String get notificationFallback => 'Bildiriş';

  @override
  String get notificationsEmpty => 'Hələ bildiriş yoxdur.';

  @override
  String get notificationsTitle => 'Bildirişlər';

  @override
  String otpIncomplete(int count) {
    return 'Kod $count rəqəmdən ibarətdir';
  }

  @override
  String get otpInvalid => 'Kod yanlışdır və ya vaxtı bitib';

  @override
  String get otpLeaveBody =>
      'Hesabınız yaradıldı, lakin e-mail təsdiqlənməyib. Kodu daxil etmədən hesaba daxil ola bilməyəcəksiniz.';

  @override
  String get otpLeaveExit => 'Çıx';

  @override
  String get otpLeaveStay => 'Kodu daxil et';

  @override
  String get otpLeaveTitle => 'Təsdiqi yarımçıq qoymaq?';

  @override
  String get otpRequired => 'Təsdiq kodunu daxil edin';

  @override
  String get otpResend => 'Kodu yenidən göndər';

  @override
  String otpResendIn(int seconds) {
    return 'Kodu yenidən göndər ($seconds s)';
  }

  @override
  String get otpResent => 'Yeni kod e-mail ünvanınıza göndərildi';

  @override
  String get otpSpamHint => 'Kod gəlmədi? Spam qovluğunu da yoxlayın.';

  @override
  String otpSubtitle(String email) {
    return '$email ünvanına 6 rəqəmli təsdiq kodu göndərdik.';
  }

  @override
  String get otpTitle => 'E-mail təsdiqi';

  @override
  String get otpVerified => 'E-mail təsdiqləndi';

  @override
  String get otpVerify => 'Təsdiqlə';

  @override
  String overdueWithDate(String date) {
    return 'Gecikib · $date';
  }

  @override
  String get payAtBankPage => 'Ödəniş bank səhifəsində tamamlanır.';

  @override
  String get payNow => 'Ödəniş et';

  @override
  String payWithAmount(String amount) {
    return 'Ödə · $amount';
  }

  @override
  String get paymentChecking => 'Ödəniş yoxlanılır';

  @override
  String get paymentCouldNotStart => 'Ödəniş başladıla bilmədi';

  @override
  String get paymentUnavailable => 'Hal-hazırda ödəniş etmək mümkün deyil';

  @override
  String get paymentCurrentBalance => 'Cari balans';

  @override
  String get paymentStatusUnavailable => 'Ödənişin statusu alınmadı';

  @override
  String get paymentUnconfirmed =>
      'Bank ödənişi qəbul etdi, lakin statusu təsdiqlənmədi. Məbləğ bir neçə dəqiqə ərzində hesabınıza işlənəcək — siyahını yeniləyib yoxlayın.';

  @override
  String get profileChildEmailSaved => 'Şagirdin e-mail ünvanı yeniləndi';

  @override
  String profileChildEmailText(String name) {
    return '$name bu ünvanla tətbiqə daxil olur. Dəyişdikdən sonra köhnə ünvan işləməyəcək.';
  }

  @override
  String get profileChildEmailTitle => 'Şagirdin e-mail ünvanı';

  @override
  String get profileCurrentPassword => 'Cari şifrə';

  @override
  String get profileCurrentPasswordRequired => 'Cari şifrənizi daxil edin';

  @override
  String get profileEdit => 'Məlumatlarımı redaktə et';

  @override
  String get profileEditSubtitle => 'Ad, e-mail və telefon';

  @override
  String get profileEmailNote =>
      'E-mail ünvanınızı dəyişsəniz, tətbiqə yeni ünvanla daxil olacaqsınız.';

  @override
  String get profileName => 'Ad, Soyad';

  @override
  String get profileNameRequired => 'Adınızı daxil edin';

  @override
  String get profilePassword => 'Şifrəni dəyiş';

  @override
  String get profilePasswordSaved => 'Şifrəniz yeniləndi';

  @override
  String get profilePasswordSubtitle => 'Hesaba giriş şifrəsi';

  @override
  String get profilePasswordText =>
      'Təhlükəsizlik üçün əvvəlcə cari şifrənizi təsdiqləyin.';

  @override
  String get profilePhone => 'Telefon';

  @override
  String get profileSaved => 'Məlumatlarınız yeniləndi';

  @override
  String get profileTitle => 'Məlumatlarım';

  @override
  String get purchaseLabel => 'Alış';

  @override
  String get receiptAmount => 'Məbləğ';

  @override
  String get receiptApproval => 'Təsdiq kodu';

  @override
  String get receiptCard => 'Kart';

  @override
  String get receiptClass => 'Sinif';

  @override
  String get receiptDate => 'Tarix';

  @override
  String get receiptDownload => 'Qəbzi PDF yüklə';

  @override
  String get receiptFailed => 'Ödəniş alınmadı';

  @override
  String get receiptFee => 'Komissiya';

  @override
  String get receiptFileBase => 'BSB-qebz';

  @override
  String get receiptFooter =>
      'Bu qəbz BSB School tətbiqində avtomatik yaradılıb və imza tələb etmir.';

  @override
  String get receiptIssuer => 'Bank';

  @override
  String get receiptMethod => 'Ödəniş üsulu';

  @override
  String get receiptNoDetails => 'Bu ödəniş üçün qəbz məlumatı yoxdur';

  @override
  String get receiptPaymentDetails => 'Ödəniş məlumatları';

  @override
  String get receiptPurpose => 'Təyinat';

  @override
  String get receiptReference => 'Əməliyyat nömrəsi';

  @override
  String get receiptRrn => 'RRN';

  @override
  String get receiptSaveFailed => 'Qəbz yüklənmədi';

  @override
  String receiptSaved(String location) {
    return 'Qəbz \"$location\" bölməsinə yükləndi';
  }

  @override
  String get receiptStatus => 'Status';

  @override
  String get receiptStudent => 'Şagird';

  @override
  String get receiptSuccess => 'Ödəniş uğurludur';

  @override
  String get receiptSystem => 'Ödəniş sistemi';

  @override
  String get receiptTitle => 'Ödəniş qəbzi';

  @override
  String get recentTransactions => 'Son əməliyyatlar';

  @override
  String get registerAdmissionNote =>
      'Qəbul nömrəsi şagird vəsiqəsində və məktəbin verdiyi qəbul sənədində yazılıb.';

  @override
  String get registerDone =>
      'Qeydiyyat tamamlandı. İndi hesabınıza daxil ola bilərsiniz.';

  @override
  String get registerHaveAccount => 'Artıq hesabınız var?';

  @override
  String get registerName => 'Ad Soyad';

  @override
  String get registerNameHint => 'Ad və soyadınız';

  @override
  String get registerNameRequired => 'Ad və soyadınızı daxil edin';

  @override
  String get registerNameShort => 'Ad və soyadı tam yazın';

  @override
  String get registerPasswordHide => 'Şifrəni gizlə';

  @override
  String get registerPasswordRepeat => 'Şifrə (təkrar)';

  @override
  String get registerPasswordRequired => 'Şifrə təyin edin';

  @override
  String get registerPasswordShow => 'Şifrəni göstər';

  @override
  String get registerPhone => 'Telefon';

  @override
  String get registerPhoneHint => '+994 50 123 45 67';

  @override
  String get registerPhoneInvalid => 'Telefon nömrəsi düzgün deyil';

  @override
  String get registerPhoneRequired => 'Telefon nömrəsini daxil edin';

  @override
  String get registerSectionAccount => 'Hesab məlumatları';

  @override
  String get registerSectionChild => 'Övladınız';

  @override
  String get registerSubmit => 'Qeydiyyatdan keç';

  @override
  String get registerSubtitle => 'Valideyn hesabı yaradın';

  @override
  String get registerTerms =>
      'İstifadə şərtləri və məxfilik siyasəti ilə razıyam';

  @override
  String get registerTermsRequired =>
      'Davam etmək üçün istifadə şərtlərini qəbul edin';

  @override
  String get registerTitle => 'Qeydiyyat';

  @override
  String get settingsAddChild => 'Yeni şagird əlavə et';

  @override
  String get settingsAddChildSubtitle => 'Başqa övladınızı bu hesaba bağlayın';

  @override
  String get settingsChildCredentials =>
      'Bu e-mail və şifrə ilə övladınız tətbiqə öz hesabı ilə daxil ola bilər. Kopyalayıb ona göndərə bilərsiniz.';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageSubtitle => 'Tətbiqin dili';

  @override
  String get settingsLightMode => 'Gündüz rejimi';

  @override
  String get settingsLightModeSubtitle => 'Açıq rəngli interfeys';

  @override
  String get settingsLogout => 'Çıxış';

  @override
  String get settingsLogoutConfirm => 'Hesabdan çıxmaq istədiyinizə əminsiniz?';

  @override
  String get settingsLogoutSubtitle => 'Tətbiqdən çıxın';

  @override
  String get settingsMyChild => 'Övladımın məlumatları';

  @override
  String settingsMyChildren(int count) {
    return 'Övladlarım ($count)';
  }

  @override
  String get settingsNotifications => 'Bildiriş parametrləri';

  @override
  String get settingsTitle => 'Tənzimləmələr';

  @override
  String get statusOverdue => 'Gecikib';

  @override
  String statusOverdueSuffix(String status) {
    return '$status · gecikib';
  }

  @override
  String get statusPaid => 'Ödənilib';

  @override
  String get statusPartial => 'Qismən';

  @override
  String get statusUnpaid => 'Ödənilməyib';

  @override
  String get supportEmailSubject => 'BSB tətbiqi — dəstək sorğusu';

  @override
  String get tAccountSettings => 'Hesab tənzimləmələri';

  @override
  String get tActiveDay => 'Aktiv gün';

  @override
  String get tActiveHomeworks => 'Aktiv tapşırıqlar';

  @override
  String get tAssignHomework => 'Tapşırıq təyin et';

  @override
  String get tAssignTask => 'Tapşırığı təyin et';

  @override
  String get tAttachDoc => 'Sənəd əlavə etmək üçün toxunun (PDF / XLS)';

  @override
  String get tAttachmentFile => 'Əlavə fayl';

  @override
  String tAttendanceCounts(int present, int absent, int late) {
    return 'Gəlib: $present | Qayıb: $absent | Gecikib: $late';
  }

  @override
  String get tAttendanceSaved => 'Davamiyyət yadda saxlanıldı!';

  @override
  String get tAverageScore => 'Orta bal';

  @override
  String get tBehaviourShort => 'DAV.';

  @override
  String get tChangePin => 'PIN kodu dəyiş';

  @override
  String get tChoosePdf => 'PDF / şəkil seçmək üçün toxunun';

  @override
  String get tClassGroup => 'Sinif qrupu';

  @override
  String get tComments => 'Şərhlər / Müşahidələr';

  @override
  String get tCommentsHint => 'Qeyd və ya əlavə məlumat yazın...';

  @override
  String get tCurrentlyAssigned => 'Hazırda təyin olunmuş';

  @override
  String get tDate => 'Tarix';

  @override
  String get tDescriptionHint => 'Tapşırığın təfərrüatları...';

  @override
  String get tDescriptionTasks => 'Təsvir / Tapşırıqlar';

  @override
  String get tDocAttached => 'Sənəd əlavə edildi!';

  @override
  String get tDocUploaded => 'Hesabat sənədi yükləndi.';

  @override
  String get tDueDate => 'Son tarix';

  @override
  String tDueLabel(String date) {
    return 'Son tarix: $date';
  }

  @override
  String get tEditAttendance => 'Davamiyyəti redaktə et';

  @override
  String get tEditingMode => 'Redaktə rejimi aktivdir.';

  @override
  String get tEffortShort => 'SƏY';

  @override
  String get tEnterHomeworkTitle => 'Tapşırığın adını yazın!';

  @override
  String get tEnterReportTitle => 'Hesabatın adını yazın!';

  @override
  String get tExamType => 'İmtahan növü';

  @override
  String get tFileAttached => 'Fayl əlavə edildi!';

  @override
  String get tGradeShort => 'QİY.';

  @override
  String get tGradedStatus => 'Qiymətləndirmə vəziyyəti';

  @override
  String get tGrades => 'Qiymətlər';

  @override
  String get tGradesPublished => 'Qiymətlər dərc olundu!';

  @override
  String get tHomeworkAssigned => 'Tapşırıq təyin edildi!';

  @override
  String get tHomeworkDeleted => 'Tapşırıq silindi.';

  @override
  String get tHomeworkTitle => 'Tapşırığın adı';

  @override
  String get tHomeworkTitleHint => 'məs. Kvadrat tənliklər üzrə çalışmalar';

  @override
  String get tKsqGrades => 'KSQ qiymətləri';

  @override
  String get tLanguageSelection => 'Dil seçimi';

  @override
  String get tLanguageSubtitle => 'Tətbiq interfeysinin dili';

  @override
  String get tLanguageUpdated => 'Dil dəyişdirildi';

  @override
  String get tLightTheme => 'Açıq tema';

  @override
  String get tLogoutConfirm => 'Sessiyadan çıxmaq istəyirsiniz?';

  @override
  String get tLogoutSubtitle => 'Sessiyadan təhlükəsiz çıxın';

  @override
  String get tMaxPoints => 'Maksimum: 100 bal';

  @override
  String get tNextLesson => 'Növbəti dərs';

  @override
  String get tNoLessonsToday => 'Bu gün üçün dərs planlanmayıb.';

  @override
  String get tNotifUpdated => 'Bildiriş parametrləri yeniləndi';

  @override
  String get tPinLoading => 'PIN dəyişmə ekranı açılır...';

  @override
  String get tPinSubtitle => 'Turniket və giriş üçün təhlükəsizlik PIN-i';

  @override
  String get tPostGrades => 'İmtahan qiymətlərini yerləşdir';

  @override
  String get tPreferences => 'Tərcihlər';

  @override
  String get tPublishGrades => 'Qiymətləri dərc et';

  @override
  String get tPushNotifications => 'Push bildirişlər';

  @override
  String get tPushSubtitle => 'Qiymət xəbərdarlıqları, cədvəl yenilikləri';

  @override
  String get tRecentUploads => 'Son yükləmələr';

  @override
  String get tReportDocument => 'Hesabat sənədi';

  @override
  String get tReportHintStudent => 'məs. Samir Əliyev — davranış və iş rəyi';

  @override
  String get tReportHintWeekly => 'məs. 14-cü həftə riyaziyyat üzrə irəliləyiş';

  @override
  String get tReportSubmitted => 'Hesabat göndərildi!';

  @override
  String get tReportTitle => 'Hesabatın adı';

  @override
  String get tReports => 'Hesabatlar';

  @override
  String get tSaveAttendance => 'Davamiyyəti yadda saxla';

  @override
  String get tSeeAll => 'Hamısına bax';

  @override
  String get tStudentAttendance => 'Şagird davamiyyəti';

  @override
  String get tStudentGrades => 'Şagird qiymətləri';

  @override
  String get tStudentInfo => 'ŞAGİRD';

  @override
  String get tStudentList => 'Şagird siyahısı';

  @override
  String tStudentReportFor(String name) {
    return '$name üçün şagird hesabatı';
  }

  @override
  String get tStudentReports => 'Şagird hesabatları';

  @override
  String get tSubmissionHistory => 'Göndərmə tarixçəsi';

  @override
  String get tSubmitReport => 'Hesabatı göndər';

  @override
  String get tTargetStudent => 'Hədəf şagird';

  @override
  String get tTaskManagement => 'Tapşırıq idarəetməsi';

  @override
  String get tUploadReports => 'Hesabat yüklə';

  @override
  String get tWeeklyReports => 'Həftəlik hesabatlar';

  @override
  String get tWeeklyTimetable => 'Həftəlik dərs cədvəli';

  @override
  String get tWelcomeBack => 'Xoş gəldiniz,';

  @override
  String get timetableEmpty => 'Bu gün üçün dərs yoxdur';

  @override
  String get timetableGroupPrefix => 'Qrup: ';

  @override
  String timetableTeacherLabel(String name) {
    return 'Müəllim: $name';
  }

  @override
  String get topUpCardSection => 'Ödəniş kartı';

  @override
  String get topUpLabel => 'Balans artımı';

  @override
  String get tuitionAmountInvalid => 'Məbləği düzgün daxil edin';

  @override
  String get tuitionAmountOther => 'Başqa məbləğ';

  @override
  String get tuitionAmountOtherHint => 'İstədiyiniz məbləği yazın';

  @override
  String get tuitionAmountSheetHint =>
      'Təklif olunan məbləği seçin və ya özünüz yazın.';

  @override
  String get tuitionAmountSheetTitle => 'Ödəniş məbləği';

  @override
  String get tuitionAmountTooSmall => 'Məbləğ 0-dan böyük olmalıdır';

  @override
  String get tuitionColumnAmount => 'ÖDƏNİŞ MƏBLƏĞİ';

  @override
  String get tuitionColumnDate => 'ÖDƏNİŞ TARİXİ';

  @override
  String get tuitionColumnStatus => 'STATUS';

  @override
  String get tuitionCredit => 'Artıq ödənilmiş məbləğ';

  @override
  String tuitionCreditAmount(String amount) {
    return 'Hesabda artıq: $amount';
  }

  @override
  String get tuitionCurrentMonth => 'Cari ay üçün ödəniş';

  @override
  String tuitionDueNowAmount(String amount) {
    return 'İndi ödənilməli: $amount';
  }

  @override
  String get tuitionHistoryTitle => 'Ödəniş tarixçəsi';

  @override
  String tuitionInstalmentsCount(int count) {
    return '$count taksit üzrə';
  }

  @override
  String get tuitionLateFee => 'Gecikmə cəriməsi';

  @override
  String get tuitionLateFeeHint => 'Gecikmə üzrə';

  @override
  String get tuitionNoDate => 'Tarix yoxdur';

  @override
  String get tuitionNoDebt => 'Borc yoxdur. Öncədən ödəniş edə bilərsiniz.';

  @override
  String get tuitionNoLateFee => 'Gecikmə yoxdur';

  @override
  String get tuitionNothingDueYet => 'Vaxtı çatmış borc yoxdur.';

  @override
  String get tuitionPayDueNow => 'İndi ödənilməli';

  @override
  String get tuitionPayDueNowHint => 'Vaxtı çatmış borc';

  @override
  String get tuitionPayFull => 'Tam borc';

  @override
  String get tuitionPayFullHint => 'Bütün qalıq borc';

  @override
  String get tuitionPaySection => 'Ödəniş bölməsi';

  @override
  String get tuitionRingLabel => 'Ödəniş';

  @override
  String get tuitionScheduleClosed => 'Cədvəl bağlanıb';

  @override
  String get tuitionScheduleEmpty => 'Ödəniş cədvəli tapılmadı';

  @override
  String get tuitionScheduleTitle => 'Ödəniş Cədvəli';

  @override
  String get tuitionTabExtra => 'Əlavə ödənişlər';

  @override
  String get tuitionTabTuition => 'Təhsil haqqı';

  @override
  String get tuitionTitle => 'Ödəniş cədvəli';

  @override
  String get tuitionTotalDue => 'Ümumi qalıq';

  @override
  String get underConstructionBadge => 'Tezliklə';

  @override
  String get underConstructionComingTitle => 'Tezliklə burada olacaq';

  @override
  String get underConstructionFeatureHistory => 'Qəbz və tarixçə';

  @override
  String get underConstructionFeatureHistoryHint =>
      'Bütün ödənişlər bir siyahıda';

  @override
  String get underConstructionFeaturePay => 'Kart ilə ödəniş';

  @override
  String get underConstructionFeaturePayHint =>
      'Təhsil haqqı və əlavə xidmətlər';

  @override
  String get underConstructionFeatureSchedule => 'Ödəniş cədvəli';

  @override
  String get underConstructionFeatureScheduleHint =>
      'Taksitlər və son ödəniş tarixləri';

  @override
  String get underConstructionNote =>
      'Bölmə hazır olan kimi tətbiqdə avtomatik açılacaq — sizin heç nə etməyinizə ehtiyac yoxdur.';

  @override
  String get underConstructionProgress => 'Hazırlanır';

  @override
  String get underConstructionSubtitle =>
      'Ödəniş bölməsi üzərində işləyirik. Tezliklə təhsil haqqını və əlavə xidmətləri birbaşa tətbiqdən ödəyə biləcəksiniz.';

  @override
  String get underConstructionTitle => 'Hazırlanma mərhələsindədir';

  @override
  String updateAvailableText(String version) {
    return '$version versiyası hazırdır. Yeniləsəniz, son dəyişikliklərdən istifadə edə biləcəksiniz.';
  }

  @override
  String get updateAvailableTitle => 'Yeni versiya mövcuddur';

  @override
  String get updateForcedText =>
      'Tətbiqin bu versiyası artıq dəstəklənmir. Davam etmək üçün ən son versiyanı quraşdırın.';

  @override
  String get updateForcedTitle => 'Yeniləmə tələb olunur';

  @override
  String get updateLater => 'Sonra';

  @override
  String get updateNow => 'İndi yenilə';

  @override
  String updateVersions(String current, String latest) {
    return 'Cari: $current · Son: $latest';
  }

  @override
  String get webviewLoadFailed => 'Səhifə yüklənmədi';

  @override
  String get webviewStopText =>
      'Ödəniş tamamlanmayıb. Səhifəni bağlamaq istəyirsiniz?';

  @override
  String get webviewStopTitle => 'Ödənişi dayandırmaq';

  @override
  String get webviewTitle => 'Ödəniş';

  @override
  String get weeklyFeedbackTitle => 'Həftəlik rəy';

  @override
  String get weeklyFeedbackWeeks => 'Tədris həftələri';

  @override
  String weeklyFeedbackWeek(int week) {
    return 'Həftə $week';
  }

  @override
  String get weeklyFeedbackNoneForWeek => 'Bu həftə üçün rəy yoxdur';

  @override
  String get weeklyFeedbackUnavailable => 'Həftəlik rəylər hələ əlçatan deyil';

  @override
  String get weeklyFeedbackHas => 'Rəy var';

  @override
  String weeklyFeedbackAboutStudent(String name) {
    return '$name haqqında';
  }

  @override
  String get weeklyFeedbackCurrent => 'Cari həftə';

  @override
  String get weeklyFeedbackFiles => 'Fayllar';

  @override
  String weeklyLessonCount(int count) {
    return '$count dərs';
  }

  @override
  String weeklyTeacherRoom(String teacher, String room) {
    return '$teacher • Otaq $room';
  }
}
