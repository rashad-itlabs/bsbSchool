# BSB School

Məktəb tətbiqi — **Clean Architecture** (feature-first) ilə qurulub.

## Bölmələr
- **Homework** — ev tapşırıqları, tamamlandı işarəsi
- **Library** — kitabxana, kitab götürmə
- **Examination** — imtahan cədvəli və qiymətlər
- **WeeklyPlan** — həftəlik dərs cədvəli
- **Buffet Cart** — bufet, səbət, sifariş (balansdan çıxır)
- **Balance** — balansa baxış və artırma

## Texnologiyalar
- `flutter_bloc` (Cubit) — state management
- `get_it` — dependency injection
- `dartz` — `Either<Failure, T>` ilə error handling
- `dio` — şəbəkə (real API üçün hazır)
- `shared_preferences` — lokal saxlama (balans)

## Qatlar (hər feature üçün)
```
features/<feature>/
├── data/
│   ├── datasources/     # Remote/Local (hazırda mock)
│   ├── models/          # JSON ⇄ Entity
│   └── repositories/    # Repository impl
├── domain/
│   ├── entities/        # Saf biznes obyektləri
│   ├── repositories/    # Abstract müqavilələr
│   └── usecases/        # Tək məsuliyyətli əməliyyatlar
└── presentation/
    ├── cubit/           # State + Cubit
    └── pages/           # UI
```

Asılılıq istiqaməti: `presentation → domain ← data`. Domain heç nədən asılı deyil.

## İşə salma
```bash
flutter pub get
flutter run
```

## Real API-yə keçid
Hər `*RemoteDataSourceMock` sinfini `Dio` əsaslı implementasiya ilə əvəz etmək kifayətdir —
qalan qatlara toxunmağa ehtiyac yoxdur. Bağlantı `core/di/injection_container.dart`-dadır.
