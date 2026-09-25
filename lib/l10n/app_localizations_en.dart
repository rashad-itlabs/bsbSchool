// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get addChildAdded => 'The student has been added to your account';

  @override
  String get addChildAnotherText =>
      'Enter your child\'s admission number — the student will be linked to your account and you can follow everything from here.';

  @override
  String get addChildEnterNumber => 'Enter the admission number';

  @override
  String get addChildField => 'Admission number';

  @override
  String get addChildHint => 'Your child\'s ID';

  @override
  String get addChildOtherAccount => 'Sign in with another account';

  @override
  String get addChildSubmit => 'Add';

  @override
  String get addChildText =>
      'No student is linked to your account yet. Enter your child\'s admission number to continue.';

  @override
  String addChildTextNamed(String name) {
    return '$name, no student is linked to your account yet. Enter your child\'s admission number to continue.';
  }

  @override
  String get addChildTitle => 'Add your student';

  @override
  String get addChildWhere1 => 'On the student card';

  @override
  String get addChildWhere2 => 'On the admission document from the school';

  @override
  String get addChildWhere3 => 'You can ask the school office';

  @override
  String get addChildWhereTitle => 'Where is the admission number?';

  @override
  String get amountEnterValid => 'Enter a valid amount';

  @override
  String amountRange(String min, String max) {
    return 'The amount must be between $min and $max ₼';
  }

  @override
  String get appTitle => 'BSB School';

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendanceEmpty => 'No records found';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceLateTag => 'Late';

  @override
  String get attendanceMixed => 'Mixed';

  @override
  String get attendanceLesson => 'Lesson';

  @override
  String attendanceMonthOverview(String month) {
    return 'Overview for $month';
  }

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceRate => 'Attendance';

  @override
  String get attendanceRecent => 'Recent records';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get balanceAmountField => 'Amount (AZN)';

  @override
  String get balanceCurrent => 'Available balance';

  @override
  String get balanceCustomAmount => 'Custom amount';

  @override
  String get balanceInvalidAmount => 'Enter a valid amount';

  @override
  String get balanceLabel => 'Balance';

  @override
  String get balanceQuickTopUp => 'Quick top-up';

  @override
  String get balanceTopUp => 'Top up balance';

  @override
  String get balanceTopUps => 'Balance top-ups';

  @override
  String bookDeleteText(String location) {
    return 'The book will be removed from the phone and from \"$location\". You can read it again when you are online.';
  }

  @override
  String get bookDeleteTitle => 'Delete the downloaded file?';

  @override
  String get bookDeleted => 'The downloaded file was deleted';

  @override
  String get bookDownloadFailed => 'The download failed';

  @override
  String bookDownloaded(String location) {
    return 'The book was saved to \"$location\"';
  }

  @override
  String bookDownloadedPartial(String location) {
    return 'The book was downloaded but could not be written to \"$location\"';
  }

  @override
  String get bookNoFile => 'This book has no file';

  @override
  String bookOpenFailed(String reason) {
    return 'The book could not be opened: $reason';
  }

  @override
  String get buffetOrder => 'Place order';

  @override
  String buffetProductCount(int count) {
    return '$count items';
  }

  @override
  String get cafeteriaDailyLimit => 'Daily limit';

  @override
  String get cafeteriaSpent => 'Spent';

  @override
  String get cardExpiry => 'Expiry';

  @override
  String get cardHolder => 'Cardholder name';

  @override
  String get cardHolderHint => 'FIRST AND LAST NAME';

  @override
  String get cardNumberField => 'Card number';

  @override
  String get cardNumberLabel => 'Card number';

  @override
  String get commonAll => 'All';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonErrorShort => 'Error';

  @override
  String get commonFilter => 'Filter';

  @override
  String get commonHide => 'Hide';

  @override
  String get commonNo => 'No';

  @override
  String get commonNoData => 'No data found';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonSelectStudent => 'Select student';

  @override
  String get commonShow => 'Show';

  @override
  String get commonYes => 'Yes';

  @override
  String copiedToClipboard(String label) {
    return '$label copied';
  }

  @override
  String get credentialActive => 'Active';

  @override
  String get credentialPaymentId => 'Payment ID';

  @override
  String get credentialSwitchTo => 'Switch to this student';

  @override
  String get credentialSwitching => 'Switching…';

  @override
  String get credentialUsername => 'Username';

  @override
  String dailyUsage(String used, String limit) {
    return 'Daily: $used/$limit';
  }

  @override
  String dashGreeting(String name) {
    return '$name 👋';
  }

  @override
  String get dashNewsFailed => 'News could not be loaded';

  @override
  String get dashSeeAll => 'See all';

  @override
  String get downloadsFiles => 'Files';

  @override
  String get downloadsFolder => 'Downloads';

  @override
  String dueDateLabel(String date) {
    return 'Due: $date';
  }

  @override
  String dueDateOverdueLabel(String date) {
    return 'Due: $date · overdue';
  }

  @override
  String get errAttendanceLoad => 'Attendance could not be loaded';

  @override
  String get errBalanceUpdate => 'The balance was not updated';

  @override
  String get errBuffetCardLoad => 'The canteen card could not be loaded';

  @override
  String get errCache => 'A cache error occurred';

  @override
  String get errChildNotSwitched => 'The student could not be switched';

  @override
  String get errChildNotYours => 'This student does not belong to your account';

  @override
  String get errChildNotYoursShort => 'This student is not on your account';

  @override
  String get errEventsLoad => 'Events could not be loaded';

  @override
  String get errExamLoad => 'Exam results could not be loaded';

  @override
  String get errExtraFeesLoad => 'Extra fees could not be loaded';

  @override
  String get errHomeworkLoad => 'Assignments could not be loaded';

  @override
  String get errWeeklyFeedbackLoad => 'Weekly feedback could not be loaded';

  @override
  String get errInsufficientBalance => 'Insufficient balance';

  @override
  String get errInvalid => 'Invalid operation';

  @override
  String get errLibraryLoad => 'Library data could not be loaded';

  @override
  String get errNewsLoad => 'News could not be loaded';

  @override
  String get errNoConnection => 'Could not reach the server';

  @override
  String get errNoInternet => 'No internet connection';

  @override
  String get errNotificationsLoad => 'Notifications could not be loaded';

  @override
  String get errOrderFailed => 'The order could not be sent';

  @override
  String get errPaymentGateway => 'Could not reach the payment provider';

  @override
  String get errPaymentLink => 'The payment link could not be obtained';

  @override
  String get errServer => 'A server error occurred';

  @override
  String get errSessionExpired =>
      'Your session has expired, please sign in again';

  @override
  String get errStudentNotFound => 'Student not found';

  @override
  String get errTimetableLoad => 'The timetable could not be loaded';

  @override
  String get errTokenMissing => 'No token in the response';

  @override
  String get errTuitionLoad => 'Payment data could not be loaded';

  @override
  String get errUserNotFound => 'No user found with this e-mail';

  @override
  String get errWrongCredentials => 'The e-mail or password is incorrect';

  @override
  String eventsMore(int count) {
    return 'and $count more events';
  }

  @override
  String get eventsNoneToday => 'No events today';

  @override
  String get examAllResults => 'All results';

  @override
  String examBehaviourLabel(String value) {
    return 'Behaviour: $value';
  }

  @override
  String examEffortLabel(String value) {
    return 'Effort: $value';
  }

  @override
  String get examEmpty => 'No exam results found';

  @override
  String get examExam => 'Exam';

  @override
  String get examFilters => 'Filters';

  @override
  String examGradeLabel(String value) {
    return 'Grade: $value';
  }

  @override
  String get examGroup => 'Exam group';

  @override
  String get examNoMatch => 'No results match the selected filters';

  @override
  String get examNoStudent => 'No student assigned';

  @override
  String get examNotGraded => 'Not graded';

  @override
  String get examReset => 'Reset';

  @override
  String get examResetFilters => 'Reset filters';

  @override
  String get examResults => 'Results';

  @override
  String examShowResults(int count) {
    return 'Show results ($count)';
  }

  @override
  String get examTitle => 'Exam results';

  @override
  String get extraFeeAmount => 'Amount';

  @override
  String get extraFeeFallbackTitle => 'Extra fee';

  @override
  String get extraFeeNoDueDate => 'No due date';

  @override
  String get extraFeePaid => 'Paid';

  @override
  String get extraFeeRemaining => 'Remaining';

  @override
  String get extraFeesAllDone => 'All extra fees are settled.';

  @override
  String get extraFeesAllPaid => 'All paid';

  @override
  String extraFeesCountLabel(int count) {
    return '$count extra fees';
  }

  @override
  String get extraFeesEmpty => 'No extra fees';

  @override
  String get extraFeesListTitle => 'Extra fees';

  @override
  String get extraFeesNoPayment => 'No payments';

  @override
  String get extraFeesOutstanding => 'Outstanding';

  @override
  String get extraFeesOverdueCount => 'Overdue';

  @override
  String extraFeesOverdueDebt(String amount) {
    return 'There is an overdue fee — $amount still owed.';
  }

  @override
  String get extraFeesOverdueHint => 'Past due';

  @override
  String get extraFeesPaidAmount => 'Amount paid';

  @override
  String get extraFeesPayEachSeparately =>
      'Each fee is paid separately — pick one from the list below.';

  @override
  String extraFeesPayableAmount(String amount) {
    return 'Amount due: $amount';
  }

  @override
  String extraFeesPendingCount(int count) {
    return '$count awaiting payment';
  }

  @override
  String extraFeesProgressDone(int percent) {
    return '$percent% complete';
  }

  @override
  String get extraFeesTotal => 'Total amount';

  @override
  String get featureAttendance => 'Attendance';

  @override
  String get featureBuffet => 'Canteen';

  @override
  String get featureCalendar => 'Calendar';

  @override
  String get featureExaminations => 'Examinations';

  @override
  String get featureHomework => 'Homework';

  @override
  String get featureLibrary => 'Library';

  @override
  String get featureLiveLessons => 'Online lessons';

  @override
  String get featureTimetable => 'Class timetable';

  @override
  String get featureWeeklyPlan => 'Weekly plan';

  @override
  String get featureWeeklyFeedback => 'Weekly feedback';

  @override
  String get fileCouldNotOpen => 'The file could not be opened';

  @override
  String get fileDownload => 'Download file';

  @override
  String get foodCardEmpty => 'No canteen card found';

  @override
  String get foodCardTitle => 'My canteen card';

  @override
  String get filterFrom => 'From';

  @override
  String get filterTo => 'To';

  @override
  String get forgotBackToCode => 'Re-enter the code';

  @override
  String get forgotChangeEmail => 'Change e-mail address';

  @override
  String get forgotDone =>
      'Your password has been updated. You can sign in with the new one.';

  @override
  String get forgotEmailField => 'E-mail address';

  @override
  String get forgotEmailInvalid => 'The e-mail address is not valid';

  @override
  String get forgotEmailRequired => 'Enter your e-mail address';

  @override
  String forgotMinLength(int count) {
    return 'The password must be at least $count characters.';
  }

  @override
  String get forgotNewPassword => 'New password';

  @override
  String get forgotPasswordMismatch => 'The passwords do not match';

  @override
  String get forgotPasswordRequired => 'Enter a new password';

  @override
  String forgotPasswordShort(int count) {
    return 'The password must be at least $count characters';
  }

  @override
  String get forgotRepeatPassword => 'New password (repeat)';

  @override
  String get forgotSendCode => 'Send code';

  @override
  String get forgotSetPasswordText =>
      'E-mail confirmed. Now set your new password.';

  @override
  String get forgotSubmit => 'Update password';

  @override
  String get forgotText =>
      'Enter your registered e-mail address. We will send a confirmation code to it.';

  @override
  String get forgotTitle => 'Reset password';

  @override
  String get historyCanteen => 'Canteen';

  @override
  String get historyIncome => 'Top-ups';

  @override
  String get historyOther => 'Other';

  @override
  String get historyTitle => 'History';

  @override
  String get historyTuition => 'Tuition';

  @override
  String get homeSections => 'Sections';

  @override
  String get homeworkActive => 'Active';

  @override
  String homeworkDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get homeworkDuePrefix => 'Due: ';

  @override
  String get homeworkInactive => 'Past';

  @override
  String get homeworkNoActive => 'No active assignments';

  @override
  String get homeworkNoClass => 'No class assigned';

  @override
  String get homeworkNoInactive => 'No past assignments';

  @override
  String get homeworkOverdue => 'Overdue';

  @override
  String get homeworkTitle => 'Assignments';

  @override
  String get homeworkToday => 'Today';

  @override
  String get homeworkTomorrow => 'Tomorrow';

  @override
  String get hwDetailDescription => 'Description';

  @override
  String get hwDetailInfo => 'Details';

  @override
  String get hwDetailTitle => 'Assignment';

  @override
  String get hwDueDate => 'Due date';

  @override
  String get hwGivenDate => 'Assigned on';

  @override
  String get hwGrading => 'Grading';

  @override
  String get hwSection => 'Section';

  @override
  String get hwSubject => 'Subject';

  @override
  String get hwTeacher => 'Teacher';

  @override
  String get hwSubmitted => 'Submitted';

  @override
  String get hwSubmission => 'Submission';

  @override
  String get hwStatus => 'Status';

  @override
  String get hwMarkedAt => 'Marked on';

  @override
  String get hwGrade => 'Grade';

  @override
  String get hwNotes => 'Notes';

  @override
  String get hwTeacherComment => 'Teacher\'s comment';

  @override
  String get hwSubmissionFile => 'Download submitted file';

  @override
  String get languageAz => 'Azerbaijani';

  @override
  String get languageEn => 'English';

  @override
  String get languagePickSubtitle => 'You can change this later in settings.';

  @override
  String get languagePickTitle => 'Choose your language';

  @override
  String get languageRu => 'Russian';

  @override
  String get languageSystem => 'System language';

  @override
  String lastPaymentLabel(String date) {
    return 'Last payment: $date';
  }

  @override
  String get libraryEmpty => 'No books found';

  @override
  String get librarySchoolPaid => '£19.99 paid by the school';

  @override
  String get librarySearch => 'Search...';

  @override
  String get libraryTitle => 'Library';

  @override
  String libraryTitleWithClass(String className) {
    return 'Library • $className';
  }

  @override
  String get liveBadge => 'Live';

  @override
  String get liveJoin => 'Join the lesson';

  @override
  String get liveLessonsTitle => 'Live lessons';

  @override
  String get liveRoomClosed => 'The room is not open yet';

  @override
  String get liveStartingNow => 'Starting now';

  @override
  String get liveUpcoming => 'Upcoming lessons';

  @override
  String get loginCall => 'Call';

  @override
  String get loginCannotOpen => 'This action could not be opened on the device';

  @override
  String get loginEmail => 'E-mail';

  @override
  String get loginEnterCredentials => 'Enter your e-mail and password';

  @override
  String get loginForgotPassword => 'Forgot your password?';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginPasswordUpdated =>
      'Your password has been updated. Sign in with the new one.';

  @override
  String get loginRegister => 'Sign up';

  @override
  String get loginSendEmail => 'Send e-mail';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get loginSupport => 'Contact support';

  @override
  String get loginSupportText =>
      'If you cannot sign in or have a question, get in touch with us.';

  @override
  String get loginWelcome => 'Welcome';

  @override
  String get navAttendance => 'Attendance';

  @override
  String get navFoodCard => 'Food card';

  @override
  String get navHome => 'Home';

  @override
  String get navHomework => 'Homework';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get navTimetable => 'Timetable';

  @override
  String get navTuition => 'Tuition';

  @override
  String get newsNoBody => 'There is no further text for this item';

  @override
  String get newsTitle => 'News';

  @override
  String get noTopUps => 'No top-ups yet';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noTransactionsInRange => 'No transactions in this period';

  @override
  String get notifPrefAttendance => 'Attendance';

  @override
  String get notifPrefAttendanceText =>
      'Notifications about your child arriving at and leaving school.';

  @override
  String get notifPrefBuffet => 'Canteen';

  @override
  String get notifPrefBuffetText =>
      'Notifications about what your child spends in the canteen.';

  @override
  String get notifPrefExams => 'Examinations';

  @override
  String get notifPrefExamsText =>
      'Notifications about your child\'s exam results and sittings.';

  @override
  String get notifPrefHomework => 'Homework';

  @override
  String get notifPrefHomeworkText =>
      'Notifications about new homework for your child and its due dates.';

  @override
  String get notificationFallback => 'Notification';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String otpIncomplete(int count) {
    return 'The code is $count digits long';
  }

  @override
  String get otpInvalid => 'The code is incorrect or has expired';

  @override
  String get otpLeaveBody =>
      'Your account has been created, but your e-mail is not verified. You will not be able to sign in without entering the code.';

  @override
  String get otpLeaveExit => 'Leave';

  @override
  String get otpLeaveStay => 'Enter the code';

  @override
  String get otpLeaveTitle => 'Leave the verification unfinished?';

  @override
  String get otpRequired => 'Enter the verification code';

  @override
  String get otpResend => 'Send the code again';

  @override
  String otpResendIn(int seconds) {
    return 'Send the code again ($seconds s)';
  }

  @override
  String get otpResent => 'A new code has been sent to your e-mail';

  @override
  String get otpSpamHint => 'Didn\'t get the code? Check your spam folder too.';

  @override
  String otpSubtitle(String email) {
    return 'We have sent a 6-digit verification code to $email.';
  }

  @override
  String get otpTitle => 'E-mail verification';

  @override
  String get otpVerified => 'Your e-mail has been verified';

  @override
  String get otpVerify => 'Verify';

  @override
  String overdueWithDate(String date) {
    return 'Overdue · $date';
  }

  @override
  String get payAtBankPage => 'The payment is completed on the bank\'s page.';

  @override
  String get payNow => 'Pay now';

  @override
  String payWithAmount(String amount) {
    return 'Pay · $amount';
  }

  @override
  String get paymentChecking => 'Checking the payment';

  @override
  String get paymentCouldNotStart => 'The payment could not be started';

  @override
  String get paymentUnavailable => 'Payments are not available at the moment';

  @override
  String get paymentCurrentBalance => 'Current balance';

  @override
  String get paymentStatusUnavailable => 'The payment status could not be read';

  @override
  String get paymentUnconfirmed =>
      'The bank accepted the payment but its status is not confirmed yet. The amount should be applied within a few minutes — refresh the list to check.';

  @override
  String get profileChildEmailSaved =>
      'The student\'s e-mail address has been updated';

  @override
  String profileChildEmailText(String name) {
    return '$name signs in with this address. The old one stops working once it is changed.';
  }

  @override
  String get profileChildEmailTitle => 'Student\'s e-mail address';

  @override
  String get profileCurrentPassword => 'Current password';

  @override
  String get profileCurrentPasswordRequired => 'Enter your current password';

  @override
  String get profileEdit => 'Edit my details';

  @override
  String get profileEditSubtitle => 'Name, e-mail and phone';

  @override
  String get profileEmailNote =>
      'If you change your e-mail address, you will sign in with the new one.';

  @override
  String get profileName => 'Full name';

  @override
  String get profileNameRequired => 'Enter your name';

  @override
  String get profilePassword => 'Change password';

  @override
  String get profilePasswordSaved => 'Your password has been updated';

  @override
  String get profilePasswordSubtitle => 'The password you sign in with';

  @override
  String get profilePasswordText =>
      'Confirm your current password first, for security.';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileSaved => 'Your details have been updated';

  @override
  String get profileTitle => 'My details';

  @override
  String get purchaseLabel => 'Purchase';

  @override
  String get receiptAmount => 'Amount';

  @override
  String get receiptApproval => 'Approval code';

  @override
  String get receiptCard => 'Card';

  @override
  String get receiptClass => 'Class';

  @override
  String get receiptDate => 'Date';

  @override
  String get receiptDownload => 'Download receipt as PDF';

  @override
  String get receiptFailed => 'Payment failed';

  @override
  String get receiptFee => 'Fee';

  @override
  String get receiptFileBase => 'BSB-receipt';

  @override
  String get receiptFooter =>
      'This receipt was generated automatically by the BSB School app and needs no signature.';

  @override
  String get receiptIssuer => 'Bank';

  @override
  String get receiptMethod => 'Payment method';

  @override
  String get receiptNoDetails => 'No receipt details for this payment';

  @override
  String get receiptPaymentDetails => 'Payment details';

  @override
  String get receiptPurpose => 'Purpose';

  @override
  String get receiptReference => 'Transaction reference';

  @override
  String get receiptRrn => 'RRN';

  @override
  String get receiptSaveFailed => 'Receipt could not be saved';

  @override
  String receiptSaved(String location) {
    return 'Receipt saved to \"$location\"';
  }

  @override
  String get receiptStatus => 'Status';

  @override
  String get receiptStudent => 'Student';

  @override
  String get receiptSuccess => 'Payment successful';

  @override
  String get receiptSystem => 'Payment system';

  @override
  String get receiptTitle => 'Payment receipt';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get registerAdmissionNote =>
      'The admission number is on the student card and on the admission document from the school.';

  @override
  String get registerDone =>
      'Registration complete. You can now sign in to your account.';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get registerName => 'Full name';

  @override
  String get registerNameHint => 'Your first and last name';

  @override
  String get registerNameRequired => 'Enter your first and last name';

  @override
  String get registerNameShort => 'Enter your full first and last name';

  @override
  String get registerPasswordHide => 'Hide password';

  @override
  String get registerPasswordRepeat => 'Password (repeat)';

  @override
  String get registerPasswordRequired => 'Choose a password';

  @override
  String get registerPasswordShow => 'Show password';

  @override
  String get registerPhone => 'Phone';

  @override
  String get registerPhoneHint => '+994 50 123 45 67';

  @override
  String get registerPhoneInvalid => 'The phone number is not valid';

  @override
  String get registerPhoneRequired => 'Enter your phone number';

  @override
  String get registerSectionAccount => 'Account details';

  @override
  String get registerSectionChild => 'Your child';

  @override
  String get registerSubmit => 'Sign up';

  @override
  String get registerSubtitle => 'Create a parent account';

  @override
  String get registerTerms =>
      'I agree to the terms of use and the privacy policy';

  @override
  String get registerTermsRequired => 'Accept the terms of use to continue';

  @override
  String get registerTitle => 'Registration';

  @override
  String get settingsAddChild => 'Add another student';

  @override
  String get settingsAddChildSubtitle =>
      'Link another of your children to this account';

  @override
  String get settingsChildCredentials =>
      'With this e-mail and password your child can sign in to the app with their own account. You can copy and send it to them.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'App language';

  @override
  String get settingsLightMode => 'Light mode';

  @override
  String get settingsLightModeSubtitle => 'Light coloured interface';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get settingsLogoutConfirm => 'Are you sure you want to sign out?';

  @override
  String get settingsLogoutSubtitle => 'Sign out of the app';

  @override
  String get settingsMyChild => 'My child\'s details';

  @override
  String settingsMyChildren(int count) {
    return 'My children ($count)';
  }

  @override
  String get settingsNotifications => 'Notification settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String statusOverdueSuffix(String status) {
    return '$status · overdue';
  }

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusPartial => 'Partly paid';

  @override
  String get statusUnpaid => 'Unpaid';

  @override
  String get supportEmailSubject => 'BSB app — support request';

  @override
  String get tAccountSettings => 'Account Settings';

  @override
  String get tActiveDay => 'Active Day';

  @override
  String get tActiveHomeworks => 'Active Homeworks';

  @override
  String get tAssignHomework => 'Assign Homework';

  @override
  String get tAssignTask => 'Assign Homework Task';

  @override
  String get tAttachDoc => 'Click to attach document (PDF / XLS)';

  @override
  String get tAttachmentFile => 'Attachment File';

  @override
  String tAttendanceCounts(int present, int absent, int late) {
    return 'Present: $present | Absent: $absent | Late: $late';
  }

  @override
  String get tAttendanceSaved => 'Attendance saved successfully!';

  @override
  String get tAverageScore => 'Average Score';

  @override
  String get tBehaviourShort => 'BEH.';

  @override
  String get tChangePin => 'Change PIN Code';

  @override
  String get tChoosePdf => 'Click to choose or drop PDF / Image';

  @override
  String get tClassGroup => 'Class Group';

  @override
  String get tComments => 'Comments / Observations';

  @override
  String get tCommentsHint => 'Provide notes or additional information...';

  @override
  String get tCurrentlyAssigned => 'Currently Assigned';

  @override
  String get tDate => 'Date';

  @override
  String get tDescriptionHint => 'Details of the homework assignment...';

  @override
  String get tDescriptionTasks => 'Description / Tasks';

  @override
  String get tDocAttached => 'Document attached successfully!';

  @override
  String get tDocUploaded => 'Report document uploaded successfully.';

  @override
  String get tDueDate => 'Due Date';

  @override
  String tDueLabel(String date) {
    return 'Due: $date';
  }

  @override
  String get tEditAttendance => 'Edit Attendance Records';

  @override
  String get tEditingMode => 'Editing mode active.';

  @override
  String get tEffortShort => 'EFF.';

  @override
  String get tEnterHomeworkTitle => 'Please enter homework title!';

  @override
  String get tEnterReportTitle => 'Please enter report title!';

  @override
  String get tExamType => 'Exam Type';

  @override
  String get tFileAttached => 'Mock file attached successfully!';

  @override
  String get tGradeShort => 'GRADE';

  @override
  String get tGradedStatus => 'Graded Status';

  @override
  String get tGrades => 'Grades';

  @override
  String get tGradesPublished => 'Grades published successfully!';

  @override
  String get tHomeworkAssigned => 'Homework assigned successfully!';

  @override
  String get tHomeworkDeleted => 'Homework deleted.';

  @override
  String get tHomeworkTitle => 'Homework Title';

  @override
  String get tHomeworkTitleHint => 'e.g. Quadratic Equations Practice';

  @override
  String get tKsqGrades => 'KSQ Grades';

  @override
  String get tLanguageSelection => 'Language Selection';

  @override
  String get tLanguageSubtitle => 'App interface language option';

  @override
  String get tLanguageUpdated => 'Language updated';

  @override
  String get tLightTheme => 'Light Theme';

  @override
  String get tLogoutConfirm => 'Exit the session securely?';

  @override
  String get tLogoutSubtitle => 'Exit the session securely';

  @override
  String get tMaxPoints => 'Max: 100 points';

  @override
  String get tNextLesson => 'Next Lesson';

  @override
  String get tNoLessonsToday => 'No lessons scheduled for today.';

  @override
  String get tNotifUpdated => 'Notification settings updated';

  @override
  String get tPinLoading => 'PIN change screen loading...';

  @override
  String get tPinSubtitle => 'Turnstile and gate access security PIN';

  @override
  String get tPostGrades => 'Post Exam Grades';

  @override
  String get tPreferences => 'Preferences';

  @override
  String get tPublishGrades => 'Publish Student Grades';

  @override
  String get tPushNotifications => 'Push Notifications';

  @override
  String get tPushSubtitle => 'Grade alerts, schedule updates';

  @override
  String get tRecentUploads => 'Recent uploads';

  @override
  String get tReportDocument => 'Report Document';

  @override
  String get tReportHintStudent => 'e.g. Samir Aliyev behavior & work feedback';

  @override
  String get tReportHintWeekly => 'e.g. Week 14 Mathematics Progress';

  @override
  String get tReportSubmitted => 'Report submitted successfully!';

  @override
  String get tReportTitle => 'Report Title';

  @override
  String get tReports => 'Reports';

  @override
  String get tSaveAttendance => 'Save Attendance Records';

  @override
  String get tSeeAll => 'See all';

  @override
  String get tStudentAttendance => 'Student Attendance';

  @override
  String get tStudentGrades => 'Student Grades';

  @override
  String get tStudentInfo => 'STUDENT INFO';

  @override
  String get tStudentList => 'Student List';

  @override
  String tStudentReportFor(String name) {
    return 'Student report for $name';
  }

  @override
  String get tStudentReports => 'Student Reports';

  @override
  String get tSubmissionHistory => 'Submission History';

  @override
  String get tSubmitReport => 'Submit Report Form';

  @override
  String get tTargetStudent => 'Target Student';

  @override
  String get tTaskManagement => 'Task Management';

  @override
  String get tUploadReports => 'Upload Reports';

  @override
  String get tWeeklyReports => 'Weekly Reports';

  @override
  String get tWeeklyTimetable => 'Weekly Timetable';

  @override
  String get tWelcomeBack => 'Welcome back,';

  @override
  String get timetableEmpty => 'No lessons for today';

  @override
  String get timetableGroupPrefix => 'Group: ';

  @override
  String timetableTeacherLabel(String name) {
    return 'Teacher: $name';
  }

  @override
  String get topUpCardSection => 'Payment card';

  @override
  String get topUpLabel => 'Balance top-up';

  @override
  String get tuitionAmountInvalid => 'Enter a valid amount';

  @override
  String get tuitionAmountOther => 'Other amount';

  @override
  String get tuitionAmountOtherHint => 'Enter any amount';

  @override
  String get tuitionAmountSheetHint =>
      'Pick a suggested amount or enter your own.';

  @override
  String get tuitionAmountSheetTitle => 'Payment amount';

  @override
  String get tuitionAmountTooSmall => 'The amount must be greater than 0';

  @override
  String get tuitionColumnAmount => 'AMOUNT';

  @override
  String get tuitionColumnDate => 'DUE DATE';

  @override
  String get tuitionColumnStatus => 'STATUS';

  @override
  String get tuitionCredit => 'Overpaid amount';

  @override
  String tuitionCreditAmount(String amount) {
    return 'Credit on account: $amount';
  }

  @override
  String get tuitionCurrentMonth => 'This month\'s payment';

  @override
  String tuitionDueNowAmount(String amount) {
    return 'Due now: $amount';
  }

  @override
  String get tuitionHistoryTitle => 'Payment history';

  @override
  String tuitionInstalmentsCount(int count) {
    return 'Across $count instalments';
  }

  @override
  String get tuitionLateFee => 'Late fee';

  @override
  String get tuitionLateFeeHint => 'For overdue amounts';

  @override
  String get tuitionNoDate => 'No date';

  @override
  String get tuitionNoDebt => 'No debt. You can pay in advance.';

  @override
  String get tuitionNoLateFee => 'No delay';

  @override
  String get tuitionNothingDueYet => 'Nothing is due yet.';

  @override
  String get tuitionPayDueNow => 'Due now';

  @override
  String get tuitionPayDueNowHint => 'Amount already due';

  @override
  String get tuitionPayFull => 'Full balance';

  @override
  String get tuitionPayFullHint => 'Everything still owed';

  @override
  String get tuitionPaySection => 'Payments';

  @override
  String get tuitionRingLabel => 'Paid';

  @override
  String get tuitionScheduleClosed => 'Schedule completed';

  @override
  String get tuitionScheduleEmpty => 'No payment schedule found';

  @override
  String get tuitionScheduleTitle => 'Payment schedule';

  @override
  String get tuitionTabExtra => 'Extra fees';

  @override
  String get tuitionTabTuition => 'Tuition';

  @override
  String get tuitionTitle => 'Payment schedule';

  @override
  String get tuitionTotalDue => 'Total outstanding';

  @override
  String get underConstructionBadge => 'Coming soon';

  @override
  String get underConstructionComingTitle => 'Coming to this screen';

  @override
  String get underConstructionFeatureHistory => 'Receipts and history';

  @override
  String get underConstructionFeatureHistoryHint => 'Every payment in one list';

  @override
  String get underConstructionFeaturePay => 'Card payments';

  @override
  String get underConstructionFeaturePayHint => 'Tuition and extra fees';

  @override
  String get underConstructionFeatureSchedule => 'Payment schedule';

  @override
  String get underConstructionFeatureScheduleHint =>
      'Instalments and due dates';

  @override
  String get underConstructionNote =>
      'The section opens in the app on its own as soon as it is ready — there is nothing for you to do.';

  @override
  String get underConstructionProgress => 'In progress';

  @override
  String get underConstructionSubtitle =>
      'We are building the payment section. Soon you will be able to pay tuition and extra fees straight from the app.';

  @override
  String get underConstructionTitle => 'Under Construction';

  @override
  String updateAvailableText(String version) {
    return 'Version $version is ready. Update to get the latest changes.';
  }

  @override
  String get updateAvailableTitle => 'A new version is available';

  @override
  String get updateForcedText =>
      'This version of the app is no longer supported. Install the latest one to continue.';

  @override
  String get updateForcedTitle => 'Update required';

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update now';

  @override
  String updateVersions(String current, String latest) {
    return 'Installed: $current · Latest: $latest';
  }

  @override
  String get webviewLoadFailed => 'The page could not be loaded';

  @override
  String get webviewStopText =>
      'The payment is not finished. Do you want to close the page?';

  @override
  String get webviewStopTitle => 'Stop the payment';

  @override
  String get webviewTitle => 'Payment';

  @override
  String get weeklyFeedbackTitle => 'Weekly feedback';

  @override
  String get weeklyFeedbackWeeks => 'School weeks';

  @override
  String weeklyFeedbackWeek(int week) {
    return 'Week $week';
  }

  @override
  String get weeklyFeedbackNoneForWeek => 'No feedback for this week';

  @override
  String get weeklyFeedbackUnavailable =>
      'Weekly feedback is not available yet';

  @override
  String get weeklyFeedbackHas => 'Has feedback';

  @override
  String get weeklyFeedbackCurrent => 'This week';

  @override
  String get weeklyFeedbackFiles => 'Files';

  @override
  String weeklyLessonCount(int count) {
    return '$count lessons';
  }

  @override
  String weeklyTeacherRoom(String teacher, String room) {
    return '$teacher • Room $room';
  }
}
