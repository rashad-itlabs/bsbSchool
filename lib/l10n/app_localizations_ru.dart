// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppL10nRu extends AppL10n {
  AppL10nRu([String locale = 'ru']) : super(locale);

  @override
  String get addChildAdded => 'Ученик добавлен к вашей учётной записи';

  @override
  String get addChildAnotherText =>
      'Введите номер зачисления ребёнка — ученик будет привязан к вашей учётной записи, и вы сможете следить за всем отсюда.';

  @override
  String get addChildEnterNumber => 'Введите номер зачисления';

  @override
  String get addChildField => 'Номер зачисления';

  @override
  String get addChildHint => 'ID вашего ребёнка';

  @override
  String get addChildOtherAccount => 'Войти под другой учётной записью';

  @override
  String get addChildSubmit => 'Добавить';

  @override
  String get addChildText =>
      'К вашей учётной записи ещё не привязан ученик. Введите номер зачисления ребёнка, чтобы продолжить.';

  @override
  String addChildTextNamed(String name) {
    return '$name, к вашей учётной записи ещё не привязан ученик. Введите номер зачисления ребёнка, чтобы продолжить.';
  }

  @override
  String get addChildTitle => 'Добавьте ученика';

  @override
  String get addChildWhere1 => 'На ученическом билете';

  @override
  String get addChildWhere2 => 'В документе о зачислении от школы';

  @override
  String get addChildWhere3 => 'Можно узнать в секретариате школы';

  @override
  String get addChildWhereTitle => 'Где найти номер зачисления?';

  @override
  String get amountEnterValid => 'Введите корректную сумму';

  @override
  String amountRange(String min, String max) {
    return 'Сумма должна быть от $min до $max ₼';
  }

  @override
  String get appTitle => 'BSB School';

  @override
  String get attendanceAbsent => 'Пропуски';

  @override
  String get attendanceEmpty => 'Записи не найдены';

  @override
  String get attendanceLate => 'Опоздания';

  @override
  String get attendanceLateTag => 'Опоздал';

  @override
  String get attendanceMixed => 'Смешанный';

  @override
  String get attendanceLesson => 'Урок';

  @override
  String attendanceMonthOverview(String month) {
    return 'Обзор за $month';
  }

  @override
  String get attendancePresent => 'Присутствие';

  @override
  String get attendanceRate => 'Посещаемость';

  @override
  String get attendanceRecent => 'Последние записи';

  @override
  String get attendanceTitle => 'Посещаемость';

  @override
  String get balanceAmountField => 'Сумма (AZN)';

  @override
  String get balanceCurrent => 'Доступный баланс';

  @override
  String get balanceCustomAmount => 'Своя сумма';

  @override
  String get balanceInvalidAmount => 'Введите корректную сумму';

  @override
  String get balanceLabel => 'Баланс';

  @override
  String get balanceQuickTopUp => 'Быстрое пополнение';

  @override
  String get balanceTopUp => 'Пополнить баланс';

  @override
  String get balanceTopUps => 'Пополнения баланса';

  @override
  String bookDeleteText(String location) {
    return 'Книга будет удалена с телефона и из «$location». Вы сможете прочитать её снова при наличии интернета.';
  }

  @override
  String get bookDeleteTitle => 'Удалить загруженный файл?';

  @override
  String get bookDeleted => 'Загруженный файл удалён';

  @override
  String get bookDownloadFailed => 'Не удалось загрузить';

  @override
  String bookDownloaded(String location) {
    return 'Книга сохранена в «$location»';
  }

  @override
  String bookDownloadedPartial(String location) {
    return 'Книга загружена, но не удалось записать её в «$location»';
  }

  @override
  String get bookNoFile => 'У этой книги нет файла';

  @override
  String bookOpenFailed(String reason) {
    return 'Не удалось открыть книгу: $reason';
  }

  @override
  String get buffetOrder => 'Заказать';

  @override
  String buffetProductCount(int count) {
    return '$count товаров';
  }

  @override
  String get cafeteriaDailyLimit => 'Дневной лимит';

  @override
  String get cafeteriaSpent => 'Потрачено';

  @override
  String get cardExpiry => 'Срок';

  @override
  String get cardHolder => 'Имя владельца карты';

  @override
  String get cardHolderHint => 'ИМЯ И ФАМИЛИЯ';

  @override
  String get cardNumberField => 'Номер карты';

  @override
  String get cardNumberLabel => 'Номер карты';

  @override
  String get commonAll => 'Все';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonConfirm => 'Подтвердить';

  @override
  String get commonContinue => 'Продолжить';

  @override
  String get commonCopy => 'Копировать';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonError => 'Произошла ошибка';

  @override
  String get commonErrorShort => 'Ошибка';

  @override
  String get commonFilter => 'Фильтр';

  @override
  String get commonHide => 'Скрыть';

  @override
  String get commonNo => 'Нет';

  @override
  String get commonNoData => 'Данные не найдены';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonSearch => 'Поиск';

  @override
  String get commonSelectStudent => 'Выбрать ученика';

  @override
  String get commonShow => 'Показать';

  @override
  String get commonYes => 'Да';

  @override
  String copiedToClipboard(String label) {
    return '$label скопировано';
  }

  @override
  String get credentialActive => 'Активен';

  @override
  String get credentialPaymentId => 'ID платежа';

  @override
  String get credentialSwitchTo => 'Переключиться на этого ученика';

  @override
  String get credentialSwitching => 'Переключение…';

  @override
  String get credentialUsername => 'Логин';

  @override
  String dailyUsage(String used, String limit) {
    return 'За день: $used/$limit';
  }

  @override
  String dashGreeting(String name) {
    return '$name 👋';
  }

  @override
  String get dashNewsFailed => 'Не удалось загрузить новости';

  @override
  String get dashSeeAll => 'Смотреть все';

  @override
  String get downloadsFiles => 'Файлы';

  @override
  String get downloadsFolder => 'Загрузки';

  @override
  String dueDateLabel(String date) {
    return 'Срок: $date';
  }

  @override
  String dueDateOverdueLabel(String date) {
    return 'Срок: $date · просрочено';
  }

  @override
  String get errAttendanceLoad => 'Не удалось загрузить посещаемость';

  @override
  String get errBalanceUpdate => 'Баланс не обновлён';

  @override
  String get errBuffetCardLoad => 'Не удалось загрузить карту питания';

  @override
  String get errCache => 'Произошла ошибка кэша';

  @override
  String get errChildNotSwitched => 'Не удалось сменить ученика';

  @override
  String get errChildNotYours =>
      'Этот ученик не относится к вашей учётной записи';

  @override
  String get errChildNotYoursShort =>
      'Этот ученик не привязан к вашей учётной записи';

  @override
  String get errEventsLoad => 'Не удалось загрузить мероприятия';

  @override
  String get errExamLoad => 'Не удалось загрузить результаты экзаменов';

  @override
  String get errExtraFeesLoad => 'Не удалось загрузить доп. платежи';

  @override
  String get errHomeworkLoad => 'Не удалось загрузить задания';

  @override
  String get errWeeklyFeedbackLoad => 'Не удалось загрузить отзывы';

  @override
  String get errInsufficientBalance => 'Недостаточно средств';

  @override
  String get errInvalid => 'Неверная операция';

  @override
  String get errLibraryLoad => 'Не удалось загрузить данные библиотеки';

  @override
  String get errNewsLoad => 'Не удалось загрузить новости';

  @override
  String get errNoConnection => 'Не удалось подключиться к серверу';

  @override
  String get errNoInternet => 'Нет подключения к интернету';

  @override
  String get errNotificationsLoad => 'Не удалось загрузить уведомления';

  @override
  String get errOrderFailed => 'Не удалось отправить заказ';

  @override
  String get errPaymentGateway => 'Не удалось связаться с платёжной системой';

  @override
  String get errPaymentLink => 'Не удалось получить ссылку на оплату';

  @override
  String get errServer => 'Произошла ошибка сервера';

  @override
  String get errSessionExpired => 'Сессия истекла, войдите снова';

  @override
  String get errStudentNotFound => 'Ученик не найден';

  @override
  String get errTimetableLoad => 'Не удалось загрузить расписание';

  @override
  String get errTokenMissing => 'Токен отсутствует в ответе';

  @override
  String get errTuitionLoad => 'Не удалось загрузить данные о платежах';

  @override
  String get errUserNotFound => 'Пользователь с таким e-mail не найден';

  @override
  String get errWrongCredentials => 'Неверный e-mail или пароль';

  @override
  String eventsMore(int count) {
    return 'и ещё $count мероприятий';
  }

  @override
  String get eventsNoneToday => 'На сегодня мероприятий нет';

  @override
  String get examAllResults => 'Все результаты';

  @override
  String examBehaviourLabel(String value) {
    return 'Поведение: $value';
  }

  @override
  String examEffortLabel(String value) {
    return 'Старание: $value';
  }

  @override
  String get examEmpty => 'Результаты экзаменов не найдены';

  @override
  String get examExam => 'Экзамен';

  @override
  String get examFilters => 'Фильтры';

  @override
  String examGradeLabel(String value) {
    return 'Оценка: $value';
  }

  @override
  String get examGroup => 'Группа экзаменов';

  @override
  String get examNoMatch => 'Нет результатов по выбранным фильтрам';

  @override
  String get examNoStudent => 'Ученик не назначен';

  @override
  String get examNotGraded => 'Не оценено';

  @override
  String get examReset => 'Сбросить';

  @override
  String get examResetFilters => 'Сбросить фильтры';

  @override
  String get examResults => 'Результаты';

  @override
  String examShowResults(int count) {
    return 'Показать результаты ($count)';
  }

  @override
  String get examTitle => 'Результаты экзаменов';

  @override
  String get extraFeeAmount => 'Сумма';

  @override
  String get extraFeeFallbackTitle => 'Дополнительный платёж';

  @override
  String get extraFeeNoDueDate => 'Без срока';

  @override
  String get extraFeePaid => 'Оплачено';

  @override
  String get extraFeeRemaining => 'Остаток';

  @override
  String get extraFeesAllDone => 'Все дополнительные платежи оплачены.';

  @override
  String get extraFeesAllPaid => 'Всё оплачено';

  @override
  String extraFeesCountLabel(int count) {
    return '$count доп. платежей';
  }

  @override
  String get extraFeesEmpty => 'Дополнительных платежей нет';

  @override
  String get extraFeesListTitle => 'Дополнительные платежи';

  @override
  String get extraFeesNoPayment => 'Платежей нет';

  @override
  String get extraFeesOutstanding => 'Остаток долга';

  @override
  String get extraFeesOverdueCount => 'Просроченные';

  @override
  String extraFeesOverdueDebt(String amount) {
    return 'Есть просроченный платёж — остаток $amount.';
  }

  @override
  String get extraFeesOverdueHint => 'Срок прошёл';

  @override
  String get extraFeesPaidAmount => 'Оплаченная сумма';

  @override
  String get extraFeesPayEachSeparately =>
      'Каждый платёж оплачивается отдельно — выберите его в списке ниже.';

  @override
  String extraFeesPayableAmount(String amount) {
    return 'К оплате: $amount';
  }

  @override
  String extraFeesPendingCount(int count) {
    return '$count ожидают оплаты';
  }

  @override
  String extraFeesProgressDone(int percent) {
    return '$percent% выполнено';
  }

  @override
  String get extraFeesTotal => 'Общая сумма';

  @override
  String get featureAttendance => 'Посещаемость';

  @override
  String get featureBuffet => 'Столовая';

  @override
  String get featureCalendar => 'Календарь';

  @override
  String get featureExaminations => 'Экзамены';

  @override
  String get featureHomework => 'Домашние задания';

  @override
  String get featureLibrary => 'Библиотека';

  @override
  String get featureLiveLessons => 'Онлайн-уроки';

  @override
  String get featureTimetable => 'Расписание уроков';

  @override
  String get featureWeeklyPlan => 'Недельный план';

  @override
  String get featureWeeklyFeedback => 'Отзывы недели';

  @override
  String get fileCouldNotOpen => 'Не удалось открыть файл';

  @override
  String get fileDownload => 'Скачать файл';

  @override
  String get foodCardEmpty => 'Карта питания не найдена';

  @override
  String get foodCardTitle => 'Продуктовая карта';

  @override
  String get filterFrom => 'С';

  @override
  String get filterTo => 'По';

  @override
  String get forgotBackToCode => 'Ввести код заново';

  @override
  String get forgotChangeEmail => 'Изменить адрес e-mail';

  @override
  String get forgotDone =>
      'Пароль обновлён. Теперь можно войти с новым паролем.';

  @override
  String get forgotEmailField => 'Адрес e-mail';

  @override
  String get forgotEmailInvalid => 'Некорректный адрес e-mail';

  @override
  String get forgotEmailRequired => 'Введите адрес e-mail';

  @override
  String forgotMinLength(int count) {
    return 'Пароль должен содержать не менее $count символов.';
  }

  @override
  String get forgotNewPassword => 'Новый пароль';

  @override
  String get forgotPasswordMismatch => 'Пароли не совпадают';

  @override
  String get forgotPasswordRequired => 'Введите новый пароль';

  @override
  String forgotPasswordShort(int count) {
    return 'Пароль должен содержать не менее $count символов';
  }

  @override
  String get forgotRepeatPassword => 'Новый пароль (повтор)';

  @override
  String get forgotSendCode => 'Отправить код';

  @override
  String get forgotSetPasswordText =>
      'E-mail подтверждён. Теперь задайте новый пароль.';

  @override
  String get forgotSubmit => 'Обновить пароль';

  @override
  String get forgotText =>
      'Введите зарегистрированный адрес e-mail. Мы отправим на него код подтверждения.';

  @override
  String get forgotTitle => 'Восстановление пароля';

  @override
  String get historyCanteen => 'Столовая';

  @override
  String get historyIncome => 'Пополнения';

  @override
  String get historyOther => 'Прочее';

  @override
  String get historyTitle => 'История';

  @override
  String get historyTuition => 'Обучение';

  @override
  String get homeSections => 'Разделы';

  @override
  String get homeworkActive => 'Активные';

  @override
  String homeworkDaysLeft(int days) {
    return 'Осталось $days дн.';
  }

  @override
  String get homeworkDuePrefix => 'Срок: ';

  @override
  String get homeworkInactive => 'Завершённые';

  @override
  String get homeworkNoActive => 'Активных заданий нет';

  @override
  String get homeworkNoClass => 'Класс не назначен';

  @override
  String get homeworkNoInactive => 'Завершённых заданий нет';

  @override
  String get homeworkOverdue => 'Просрочено';

  @override
  String get homeworkTitle => 'Задания';

  @override
  String get homeworkToday => 'Сегодня';

  @override
  String get homeworkTomorrow => 'Завтра';

  @override
  String get hwDetailDescription => 'Описание';

  @override
  String get hwDetailInfo => 'Информация';

  @override
  String get hwDetailTitle => 'Задание';

  @override
  String get hwDueDate => 'Срок сдачи';

  @override
  String get hwGivenDate => 'Дата выдачи';

  @override
  String get hwGrading => 'Оценивание';

  @override
  String get hwSection => 'Раздел';

  @override
  String get hwSubject => 'Предмет';

  @override
  String get hwTeacher => 'Учитель';

  @override
  String get hwSubmitted => 'Сдано';

  @override
  String get hwSubmission => 'Сдача';

  @override
  String get hwStatus => 'Статус';

  @override
  String get hwMarkedAt => 'Отмечено';

  @override
  String get hwGrade => 'Оценка';

  @override
  String get hwNotes => 'Заметки';

  @override
  String get hwTeacherComment => 'Комментарий учителя';

  @override
  String get hwSubmissionFile => 'Скачать сданный файл';

  @override
  String get languageAz => 'Азербайджанский';

  @override
  String get languageEn => 'Английский';

  @override
  String get languagePickSubtitle => 'Позже это можно изменить в настройках.';

  @override
  String get languagePickTitle => 'Выберите язык';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageSystem => 'Системный язык';

  @override
  String lastPaymentLabel(String date) {
    return 'Последний платёж: $date';
  }

  @override
  String get libraryEmpty => 'Книги не найдены';

  @override
  String get librarySchoolPaid => '£19.99 оплачено школой';

  @override
  String get librarySearch => 'Поиск...';

  @override
  String get libraryTitle => 'Библиотека';

  @override
  String libraryTitleWithClass(String className) {
    return 'Библиотека • $className';
  }

  @override
  String get liveBadge => 'В эфире';

  @override
  String get liveJoin => 'Присоединиться';

  @override
  String get liveLessonsTitle => 'Онлайн-уроки';

  @override
  String get liveRoomClosed => 'Комната ещё не открыта';

  @override
  String get liveStartingNow => 'Начинается сейчас';

  @override
  String get liveUpcoming => 'Предстоящие уроки';

  @override
  String get loginCall => 'Позвонить';

  @override
  String get loginCannotOpen =>
      'Не удалось выполнить это действие на устройстве';

  @override
  String get loginEmail => 'E-mail';

  @override
  String get loginEnterCredentials => 'Введите e-mail и пароль';

  @override
  String get loginForgotPassword => 'Забыли пароль?';

  @override
  String get loginNoAccount => 'Нет аккаунта?';

  @override
  String get loginPassword => 'Пароль';

  @override
  String get loginPasswordUpdated =>
      'Пароль обновлён. Войдите с новым паролем.';

  @override
  String get loginRegister => 'Зарегистрироваться';

  @override
  String get loginSendEmail => 'Отправить e-mail';

  @override
  String get loginSubmit => 'Войти';

  @override
  String get loginSubtitle => 'Войдите, чтобы продолжить';

  @override
  String get loginSupport => 'Связаться с поддержкой';

  @override
  String get loginSupportText =>
      'Если не удаётся войти или есть вопрос — свяжитесь с нами.';

  @override
  String get loginWelcome => 'Добро пожаловать';

  @override
  String get navAttendance => 'Посещаемость';

  @override
  String get navFoodCard => 'Прод. карта';

  @override
  String get navHome => 'Главная';

  @override
  String get navHomework => 'Домашние задания';

  @override
  String get navNotifications => 'Уведомления';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navTimetable => 'Расписание';

  @override
  String get navTuition => 'Платежи';

  @override
  String get newsNoBody => 'Для этой новости нет дополнительного текста';

  @override
  String get newsTitle => 'Новость';

  @override
  String get noTopUps => 'Пополнений пока нет';

  @override
  String get noTransactions => 'Операций пока нет';

  @override
  String get noTransactionsInRange => 'За этот период операций нет';

  @override
  String get notifPrefAttendance => 'Посещаемость';

  @override
  String get notifPrefAttendanceText =>
      'Уведомления о приходе ребёнка в школу и уходе из неё.';

  @override
  String get notifPrefBuffet => 'Столовая';

  @override
  String get notifPrefBuffetText => 'Уведомления о тратах ребёнка в столовой.';

  @override
  String get notifPrefExams => 'Экзамены';

  @override
  String get notifPrefExamsText =>
      'Уведомления о результатах экзаменов и их сдаче.';

  @override
  String get notifPrefHomework => 'Домашние задания';

  @override
  String get notifPrefHomeworkText =>
      'Уведомления о новых домашних заданиях ребёнка и сроках их сдачи.';

  @override
  String get notificationFallback => 'Уведомление';

  @override
  String get notificationsEmpty => 'Уведомлений пока нет.';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String otpIncomplete(int count) {
    return 'Код состоит из $count цифр';
  }

  @override
  String get otpInvalid => 'Код неверный или срок его действия истёк';

  @override
  String get otpLeaveBody =>
      'Аккаунт создан, но e-mail не подтверждён. Без ввода кода войти в аккаунт не получится.';

  @override
  String get otpLeaveExit => 'Выйти';

  @override
  String get otpLeaveStay => 'Ввести код';

  @override
  String get otpLeaveTitle => 'Прервать подтверждение?';

  @override
  String get otpRequired => 'Введите код подтверждения';

  @override
  String get otpResend => 'Отправить код повторно';

  @override
  String otpResendIn(int seconds) {
    return 'Отправить код повторно ($seconds с)';
  }

  @override
  String get otpResent => 'Новый код отправлен на ваш e-mail';

  @override
  String get otpSpamHint => 'Код не пришёл? Проверьте также папку «Спам».';

  @override
  String otpSubtitle(String email) {
    return 'Мы отправили 6-значный код подтверждения на $email.';
  }

  @override
  String get otpTitle => 'Подтверждение e-mail';

  @override
  String get otpVerified => 'E-mail подтверждён';

  @override
  String get otpVerify => 'Подтвердить';

  @override
  String overdueWithDate(String date) {
    return 'Просрочено · $date';
  }

  @override
  String get payAtBankPage => 'Платёж завершается на странице банка.';

  @override
  String get payNow => 'Оплатить';

  @override
  String payWithAmount(String amount) {
    return 'Оплатить · $amount';
  }

  @override
  String get paymentChecking => 'Проверка платежа';

  @override
  String get paymentCouldNotStart => 'Не удалось начать оплату';

  @override
  String get paymentUnavailable => 'В данный момент оплата недоступна';

  @override
  String get paymentCurrentBalance => 'Текущий баланс';

  @override
  String get paymentStatusUnavailable => 'Не удалось получить статус платежа';

  @override
  String get paymentUnconfirmed =>
      'Банк принял платёж, но его статус ещё не подтверждён. Сумма будет зачислена в течение нескольких минут — обновите список.';

  @override
  String get profileChildEmailSaved => 'Адрес e-mail ученика обновлён';

  @override
  String profileChildEmailText(String name) {
    return '$name входит в приложение с этим адресом. После изменения старый перестанет работать.';
  }

  @override
  String get profileChildEmailTitle => 'Адрес e-mail ученика';

  @override
  String get profileCurrentPassword => 'Текущий пароль';

  @override
  String get profileCurrentPasswordRequired => 'Введите текущий пароль';

  @override
  String get profileEdit => 'Изменить мои данные';

  @override
  String get profileEditSubtitle => 'Имя, e-mail и телефон';

  @override
  String get profileEmailNote =>
      'Если вы измените адрес e-mail, вход будет выполняться по новому адресу.';

  @override
  String get profileName => 'Имя и фамилия';

  @override
  String get profileNameRequired => 'Введите ваше имя';

  @override
  String get profilePassword => 'Изменить пароль';

  @override
  String get profilePasswordSaved => 'Пароль обновлён';

  @override
  String get profilePasswordSubtitle => 'Пароль для входа в аккаунт';

  @override
  String get profilePasswordText =>
      'Для безопасности сначала подтвердите текущий пароль.';

  @override
  String get profilePhone => 'Телефон';

  @override
  String get profileSaved => 'Ваши данные обновлены';

  @override
  String get profileTitle => 'Мои данные';

  @override
  String get purchaseLabel => 'Покупка';

  @override
  String get receiptAmount => 'Сумма';

  @override
  String get receiptApproval => 'Код авторизации';

  @override
  String get receiptCard => 'Карта';

  @override
  String get receiptClass => 'Класс';

  @override
  String get receiptDate => 'Дата';

  @override
  String get receiptDownload => 'Скачать квитанцию в PDF';

  @override
  String get receiptFailed => 'Платёж не прошёл';

  @override
  String get receiptFee => 'Комиссия';

  @override
  String get receiptFileBase => 'BSB-kvitansiya';

  @override
  String get receiptFooter =>
      'Квитанция сформирована автоматически приложением BSB School и не требует подписи.';

  @override
  String get receiptIssuer => 'Банк';

  @override
  String get receiptMethod => 'Способ оплаты';

  @override
  String get receiptNoDetails => 'Для этого платежа нет данных квитанции';

  @override
  String get receiptPaymentDetails => 'Данные платежа';

  @override
  String get receiptPurpose => 'Назначение';

  @override
  String get receiptReference => 'Номер операции';

  @override
  String get receiptRrn => 'RRN';

  @override
  String get receiptSaveFailed => 'Не удалось сохранить квитанцию';

  @override
  String receiptSaved(String location) {
    return 'Квитанция сохранена в «$location»';
  }

  @override
  String get receiptStatus => 'Статус';

  @override
  String get receiptStudent => 'Ученик';

  @override
  String get receiptSuccess => 'Платёж прошёл успешно';

  @override
  String get receiptSystem => 'Платёжная система';

  @override
  String get receiptTitle => 'Квитанция об оплате';

  @override
  String get recentTransactions => 'Последние операции';

  @override
  String get registerAdmissionNote =>
      'Номер зачисления указан в ученическом билете и в документе о зачислении, выданном школой.';

  @override
  String get registerDone =>
      'Регистрация завершена. Теперь вы можете войти в свой аккаунт.';

  @override
  String get registerHaveAccount => 'Уже есть аккаунт?';

  @override
  String get registerName => 'Имя и фамилия';

  @override
  String get registerNameHint => 'Ваши имя и фамилия';

  @override
  String get registerNameRequired => 'Введите имя и фамилию';

  @override
  String get registerNameShort => 'Укажите имя и фамилию полностью';

  @override
  String get registerPasswordHide => 'Скрыть пароль';

  @override
  String get registerPasswordRepeat => 'Пароль (повторно)';

  @override
  String get registerPasswordRequired => 'Придумайте пароль';

  @override
  String get registerPasswordShow => 'Показать пароль';

  @override
  String get registerPhone => 'Телефон';

  @override
  String get registerPhoneHint => '+994 50 123 45 67';

  @override
  String get registerPhoneInvalid => 'Номер телефона указан неверно';

  @override
  String get registerPhoneRequired => 'Введите номер телефона';

  @override
  String get registerSectionAccount => 'Данные аккаунта';

  @override
  String get registerSectionChild => 'Ваш ребёнок';

  @override
  String get registerSubmit => 'Зарегистрироваться';

  @override
  String get registerSubtitle => 'Создайте аккаунт родителя';

  @override
  String get registerTerms =>
      'Я согласен с условиями использования и политикой конфиденциальности';

  @override
  String get registerTermsRequired =>
      'Примите условия использования, чтобы продолжить';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get settingsAddChild => 'Добавить ещё одного ученика';

  @override
  String get settingsAddChildSubtitle =>
      'Привяжите ещё одного ребёнка к этой учётной записи';

  @override
  String get settingsChildCredentials =>
      'С этим e-mail и паролем ваш ребёнок может войти в приложение под своей учётной записью. Можно скопировать и отправить.';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSubtitle => 'Язык приложения';

  @override
  String get settingsLightMode => 'Светлый режим';

  @override
  String get settingsLightModeSubtitle => 'Светлый интерфейс';

  @override
  String get settingsLogout => 'Выход';

  @override
  String get settingsLogoutConfirm => 'Вы уверены, что хотите выйти?';

  @override
  String get settingsLogoutSubtitle => 'Выйти из приложения';

  @override
  String get settingsMyChild => 'Данные моего ребёнка';

  @override
  String settingsMyChildren(int count) {
    return 'Мои дети ($count)';
  }

  @override
  String get settingsNotifications => 'Настройки уведомлений';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get statusOverdue => 'Просрочено';

  @override
  String statusOverdueSuffix(String status) {
    return '$status · просрочено';
  }

  @override
  String get statusPaid => 'Оплачено';

  @override
  String get statusPartial => 'Частично';

  @override
  String get statusUnpaid => 'Не оплачено';

  @override
  String get supportEmailSubject => 'Приложение BSB — обращение в поддержку';

  @override
  String get tAccountSettings => 'Настройки аккаунта';

  @override
  String get tActiveDay => 'Активный день';

  @override
  String get tActiveHomeworks => 'Активные задания';

  @override
  String get tAssignHomework => 'Назначить задание';

  @override
  String get tAssignTask => 'Назначить задание';

  @override
  String get tAttachDoc => 'Нажмите, чтобы прикрепить документ (PDF / XLS)';

  @override
  String get tAttachmentFile => 'Прикреплённый файл';

  @override
  String tAttendanceCounts(int present, int absent, int late) {
    return 'Присутствуют: $present | Отсутствуют: $absent | Опоздали: $late';
  }

  @override
  String get tAttendanceSaved => 'Посещаемость сохранена!';

  @override
  String get tAverageScore => 'Средний балл';

  @override
  String get tBehaviourShort => 'ПОВ.';

  @override
  String get tChangePin => 'Изменить PIN-код';

  @override
  String get tChoosePdf => 'Нажмите, чтобы выбрать PDF / изображение';

  @override
  String get tClassGroup => 'Классная группа';

  @override
  String get tComments => 'Комментарии / Наблюдения';

  @override
  String get tCommentsHint => 'Укажите заметки или доп. информацию...';

  @override
  String get tCurrentlyAssigned => 'Назначено сейчас';

  @override
  String get tDate => 'Дата';

  @override
  String get tDescriptionHint => 'Подробности задания...';

  @override
  String get tDescriptionTasks => 'Описание / Задачи';

  @override
  String get tDocAttached => 'Документ прикреплён!';

  @override
  String get tDocUploaded => 'Документ отчёта загружен.';

  @override
  String get tDueDate => 'Срок сдачи';

  @override
  String tDueLabel(String date) {
    return 'Срок: $date';
  }

  @override
  String get tEditAttendance => 'Редактировать посещаемость';

  @override
  String get tEditingMode => 'Режим редактирования включён.';

  @override
  String get tEffortShort => 'СТАР.';

  @override
  String get tEnterHomeworkTitle => 'Введите название задания!';

  @override
  String get tEnterReportTitle => 'Введите название отчёта!';

  @override
  String get tExamType => 'Тип экзамена';

  @override
  String get tFileAttached => 'Файл прикреплён!';

  @override
  String get tGradeShort => 'ОЦЕНКА';

  @override
  String get tGradedStatus => 'Статус оценивания';

  @override
  String get tGrades => 'Оценки';

  @override
  String get tGradesPublished => 'Оценки опубликованы!';

  @override
  String get tHomeworkAssigned => 'Задание назначено!';

  @override
  String get tHomeworkDeleted => 'Задание удалено.';

  @override
  String get tHomeworkTitle => 'Название задания';

  @override
  String get tHomeworkTitleHint => 'напр. Практика по квадратным уравнениям';

  @override
  String get tKsqGrades => 'Оценки KSQ';

  @override
  String get tLanguageSelection => 'Выбор языка';

  @override
  String get tLanguageSubtitle => 'Язык интерфейса приложения';

  @override
  String get tLanguageUpdated => 'Язык изменён';

  @override
  String get tLightTheme => 'Светлая тема';

  @override
  String get tLogoutConfirm => 'Завершить сессию?';

  @override
  String get tLogoutSubtitle => 'Безопасно завершить сессию';

  @override
  String get tMaxPoints => 'Максимум: 100 баллов';

  @override
  String get tNextLesson => 'Следующий урок';

  @override
  String get tNoLessonsToday => 'На сегодня уроков не запланировано.';

  @override
  String get tNotifUpdated => 'Настройки уведомлений обновлены';

  @override
  String get tPinLoading => 'Открывается экран смены PIN...';

  @override
  String get tPinSubtitle => 'PIN для турникета и входа';

  @override
  String get tPostGrades => 'Выставить оценки за экзамен';

  @override
  String get tPreferences => 'Предпочтения';

  @override
  String get tPublishGrades => 'Опубликовать оценки';

  @override
  String get tPushNotifications => 'Push-уведомления';

  @override
  String get tPushSubtitle => 'Оповещения об оценках и расписании';

  @override
  String get tRecentUploads => 'Последние загрузки';

  @override
  String get tReportDocument => 'Документ отчёта';

  @override
  String get tReportHintStudent =>
      'напр. Самир Алиев — отзыв о поведении и работе';

  @override
  String get tReportHintWeekly => 'напр. Прогресс по математике, неделя 14';

  @override
  String get tReportSubmitted => 'Отчёт отправлен!';

  @override
  String get tReportTitle => 'Название отчёта';

  @override
  String get tReports => 'Отчёты';

  @override
  String get tSaveAttendance => 'Сохранить посещаемость';

  @override
  String get tSeeAll => 'Смотреть все';

  @override
  String get tStudentAttendance => 'Посещаемость учеников';

  @override
  String get tStudentGrades => 'Оценки учеников';

  @override
  String get tStudentInfo => 'УЧЕНИК';

  @override
  String get tStudentList => 'Список учеников';

  @override
  String tStudentReportFor(String name) {
    return 'Отчёт по ученику $name';
  }

  @override
  String get tStudentReports => 'Отчёты по ученикам';

  @override
  String get tSubmissionHistory => 'История отправок';

  @override
  String get tSubmitReport => 'Отправить отчёт';

  @override
  String get tTargetStudent => 'Ученик';

  @override
  String get tTaskManagement => 'Управление задачами';

  @override
  String get tUploadReports => 'Загрузка отчётов';

  @override
  String get tWeeklyReports => 'Недельные отчёты';

  @override
  String get tWeeklyTimetable => 'Недельное расписание';

  @override
  String get tWelcomeBack => 'С возвращением,';

  @override
  String get timetableEmpty => 'На сегодня уроков нет';

  @override
  String get timetableGroupPrefix => 'Группа: ';

  @override
  String timetableTeacherLabel(String name) {
    return 'Учитель: $name';
  }

  @override
  String get topUpCardSection => 'Платёжная карта';

  @override
  String get topUpLabel => 'Пополнение баланса';

  @override
  String get tuitionAmountInvalid => 'Введите корректную сумму';

  @override
  String get tuitionAmountOther => 'Другая сумма';

  @override
  String get tuitionAmountOtherHint => 'Введите любую сумму';

  @override
  String get tuitionAmountSheetHint =>
      'Выберите предложенную сумму или введите свою.';

  @override
  String get tuitionAmountSheetTitle => 'Сумма платежа';

  @override
  String get tuitionAmountTooSmall => 'Сумма должна быть больше 0';

  @override
  String get tuitionColumnAmount => 'СУММА ПЛАТЕЖА';

  @override
  String get tuitionColumnDate => 'ДАТА ПЛАТЕЖА';

  @override
  String get tuitionColumnStatus => 'СТАТУС';

  @override
  String get tuitionCredit => 'Переплата';

  @override
  String tuitionCreditAmount(String amount) {
    return 'Переплата на счету: $amount';
  }

  @override
  String get tuitionCurrentMonth => 'Платёж за текущий месяц';

  @override
  String tuitionDueNowAmount(String amount) {
    return 'К оплате сейчас: $amount';
  }

  @override
  String get tuitionHistoryTitle => 'История платежей';

  @override
  String tuitionInstalmentsCount(int count) {
    return 'По $count платежам';
  }

  @override
  String get tuitionLateFee => 'Пеня за просрочку';

  @override
  String get tuitionLateFeeHint => 'За просрочку';

  @override
  String get tuitionNoDate => 'Нет даты';

  @override
  String get tuitionNoDebt => 'Задолженности нет. Можно оплатить заранее.';

  @override
  String get tuitionNoLateFee => 'Просрочки нет';

  @override
  String get tuitionNothingDueYet => 'Просроченной задолженности нет.';

  @override
  String get tuitionPayDueNow => 'К оплате сейчас';

  @override
  String get tuitionPayDueNowHint => 'Просроченная сумма';

  @override
  String get tuitionPayFull => 'Вся задолженность';

  @override
  String get tuitionPayFullHint => 'Весь остаток долга';

  @override
  String get tuitionPaySection => 'Раздел оплаты';

  @override
  String get tuitionRingLabel => 'Оплата';

  @override
  String get tuitionScheduleClosed => 'График завершён';

  @override
  String get tuitionScheduleEmpty => 'График платежей не найден';

  @override
  String get tuitionScheduleTitle => 'График платежей';

  @override
  String get tuitionTabExtra => 'Доп. платежи';

  @override
  String get tuitionTabTuition => 'Обучение';

  @override
  String get tuitionTitle => 'График платежей';

  @override
  String get tuitionTotalDue => 'Общий остаток';

  @override
  String get underConstructionBadge => 'Скоро';

  @override
  String get underConstructionComingTitle => 'Скоро в этом разделе';

  @override
  String get underConstructionFeatureHistory => 'Чеки и история';

  @override
  String get underConstructionFeatureHistoryHint =>
      'Все платежи в одном списке';

  @override
  String get underConstructionFeaturePay => 'Оплата картой';

  @override
  String get underConstructionFeaturePayHint =>
      'Обучение и дополнительные услуги';

  @override
  String get underConstructionFeatureSchedule => 'График платежей';

  @override
  String get underConstructionFeatureScheduleHint => 'Рассрочка и сроки оплаты';

  @override
  String get underConstructionNote =>
      'Раздел откроется в приложении сам, как только будет готов — от вас ничего не требуется.';

  @override
  String get underConstructionProgress => 'В работе';

  @override
  String get underConstructionSubtitle =>
      'Мы работаем над разделом оплаты. Скоро вы сможете оплачивать обучение и дополнительные услуги прямо в приложении.';

  @override
  String get underConstructionTitle => 'В процессе разработки';

  @override
  String updateAvailableText(String version) {
    return 'Версия $version готова. Обновите, чтобы получить последние изменения.';
  }

  @override
  String get updateAvailableTitle => 'Доступна новая версия';

  @override
  String get updateForcedText =>
      'Эта версия приложения больше не поддерживается. Установите последнюю, чтобы продолжить.';

  @override
  String get updateForcedTitle => 'Требуется обновление';

  @override
  String get updateLater => 'Позже';

  @override
  String get updateNow => 'Обновить';

  @override
  String updateVersions(String current, String latest) {
    return 'Установлена: $current · Последняя: $latest';
  }

  @override
  String get webviewLoadFailed => 'Не удалось загрузить страницу';

  @override
  String get webviewStopText => 'Платёж не завершён. Закрыть страницу?';

  @override
  String get webviewStopTitle => 'Прервать оплату';

  @override
  String get webviewTitle => 'Оплата';

  @override
  String get weeklyFeedbackTitle => 'Отзывы за неделю';

  @override
  String get weeklyFeedbackWeeks => 'Учебные недели';

  @override
  String weeklyFeedbackWeek(int week) {
    return 'Неделя $week';
  }

  @override
  String get weeklyFeedbackNoneForWeek => 'За эту неделю отзывов нет';

  @override
  String get weeklyFeedbackUnavailable => 'Отзывы за неделю пока недоступны';

  @override
  String get weeklyFeedbackHas => 'Есть отзыв';

  @override
  String weeklyFeedbackAboutStudent(String name) {
    return 'Об ученике: $name';
  }

  @override
  String get weeklyFeedbackCurrent => 'Текущая неделя';

  @override
  String get weeklyFeedbackFiles => 'Файлы';

  @override
  String weeklyLessonCount(int count) {
    return '$count уроков';
  }

  @override
  String weeklyTeacherRoom(String teacher, String room) {
    return '$teacher • Кабинет $room';
  }
}
