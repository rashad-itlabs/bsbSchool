# Backend-də yaradılmalı endpointlər

Flutter tərəfi bu dörd endpointi **hazır gözləyir** — route və controller yazılan kimi
tətbiq əlavə dəyişiklik olmadan işləyəcək.

| Endpoint | Auth | Nə edir | Tətbiqdəki yeri |
|---|---|---|---|
| `POST /api/v1/forgotPassword` | — | Şifrə bərpası üçün 6 rəqəmli kod göndərir | Login → "Şifrəni unutmusunuz?" (1-ci addım) |
| `POST /api/v1/changePassword` | — | Kodu yoxlayıb şifrəni dəyişir | Eyni sheet (3-cü addım) |
| `POST /api/v1/updateProfile` | Sanctum | Valideynin öz məlumatlarını yeniləyir | Profil → "Məlumatlarımı redaktə et" |
| `POST /api/v1/updateChildEmail` | Sanctum | Şagirdin giriş e-mailini dəyişir | Profil → şagird kartı → e-mail sətrindəki redaktə düyməsi |
| `POST /api/v1/updatePassword` | Sanctum | Daxil olmuş valideynin öz şifrəsini dəyişir | Profil → "Şifrəni dəyiş" |

`/updatePassword` və `/changePassword` fərqli işlər görür: birincisi **daxil
olmuş** valideynin cari şifrəsini soruşur, ikincisi isə hesaba girə bilməyən
adam üçün e-mailə gələn kodu yoxlayır.

Yol adları tətbiqdə sabit kimi saxlanılır
([`auth_service.dart`](../lib/features/auth/data/services/auth_service.dart)) — başqa ad
seçsəniz, orada bir sətir dəyişmək kifayətdir.

## Ümumi qaydalar

Tətbiq hər cavabı eyni məntiqlə oxuyur:

- **Uğur:** HTTP 200/201/204 **və** gövdədə `success` sahəsi `false` olmamalıdır.
  `{"success": false, ...}` qaytarılan 200 cavabı da xəta sayılır.
- **Xəta:** 4xx status. Mesaj bu ardıcıllıqla axtarılır:
  1. `errors.<sahə>[0]` — ən konkret mesaj, formada həmin sahənin altında göstərilir
  2. `message`
  3. status koduna uyğun tətbiqin öz mətni
- Validasiya xətaları üçün **422**, başqasının şagirdinə müraciət üçün **403** gözlənilir.

Laravel-in standart `$validator->errors()` formatı birbaşa uyğundur:

```json
{
  "success": false,
  "message": "Məlumatlar yenilənmədi",
  "errors": { "email": ["Bu email artıq istifadə olunur."] }
}
```

### `user` obyektinin forması

`updateProfile` və `updateChildEmail` cavabında istifadəçini geri qaytarmaq
**məcburi deyil**, amma qaytarsanız tətbiq onu keşə yazır. Forma `/login`
cavabı ilə eynidir (tətbiq `user`, `data` və ya kök səviyyəni yoxlayır):

```json
{
  "user_id": 3139,           // şagirdin id-si (parent üçün aktiv şagird)
  "parent_ids": 66,          // hesabın öz sətri — push ünvanı bundan qurulur
  "push_external_id": "66",  // varsa, olduğu kimi istifadə olunur
  "name": "Ceyhun Alizade",
  "child_name": "Rashad Ali",
  "role": "parent",
  "email": "ceyhun@bsb.edu.az",
  "phone": "0501234567",
  "class_id": 94,
  "className": "Class Group 7",
  "info": [ { "child_id": 3139, "class_id": 94, "class_name": "...",
              "child_name": "Rashad", "child_surname": "Ali",
              "email": "std_3139@bsb.edu.az", "password": "7QXVi9ir",
              "payment_id": "RA3139" } ]
}
```

Cavabda olmayan sahələr keşdəki köhnə dəyərini saxlayır, ona görə natamam
`user` obyekti də təhlükəsizdir.

> **`phone` haqqında:** tətbiq indi `phone` sahəsini oxuyur. `/login` cavabına da
> əlavə etsəniz, profil formu mövcud nömrə ilə açılacaq; əks halda xana boş
> başlayacaq (yenə də yazılıb yadda saxlanıla bilər).

### Telefon nömrəsinin formatı

Telefon xanaları maskalıdır: valideyn yalnız öz rəqəmlərini yazır, `+994` və
aralıqlar avtomatik görünür (`+994 50 123 45 67`). Serverə **həmişə eyni
formada** göndərilir — aralıqsız E.164:

```
+994501234567
```

Bu həm `/register`, həm də `/updateProfile` üçün keçərlidir. Bazada köhnə
qeydlər başqa formatdadırsa (`0501234567`, `994501234567`), tətbiq onları
oxuyub maskaya uyğun göstərir — miqrasiya tələb olunmur, amma yeni yazılanlar
E.164 olacaq. Telefon boş buraxılarsa, sahə boş sətir (`""`) kimi gedir.

---

## 1. `POST /api/v1/forgotPassword`

Sorğu:

```json
{ "email": "ceyhun@bsb.edu.az" }
```

Uğurlu cavab (200):

```json
{ "success": true, "message": "Kod e-mail ünvanınıza göndərildi" }
```

Xəta (422) — bu email ilə hesab yoxdursa:

```json
{ "success": false, "message": "Bu email ilə istifadəçi tapılmadı." }
```

> **Qeyd:** mövcud `/resendOtp` bu iş üçün yaramır — o, yalnız qeydiyyatı təsdiq
> gözləyən hesablara kod göndərir və təsdiqlənmiş hesabı "Bu email üçün təsdiq
> gözləyən hesab yoxdur." cavabı ilə rədd edir.

## 2. `POST /api/v1/changePassword`

Sorğu:

```json
{
  "email": "ceyhun@bsb.edu.az",
  "otp": "123456",
  "new_password": "yeniSifre1",
  "new_password_confirmation": "yeniSifre1"
}
```

Uğurlu cavab (200): `{ "success": true, "message": "Şifrəniz yeniləndi" }`

Xəta (422) — kod yanlış/vaxtı bitib:

```json
{ "success": false, "errors": { "otp": ["Kod yanlışdır və ya vaxtı bitib"] } }
```

Kod mütləq burada da yoxlanmalıdır: yoxsa yalnız e-mail bilməklə istənilən
hesabın şifrəsini dəyişmək mümkün olar.

### Nümunə controller (migration tələb etmir — OTP cache-də saxlanılır)

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Validator;

class PasswordResetController extends Controller
{
    private const TTL_MINUTES = 10;

    public function sendCode(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => ['required', 'email'],
        ], [
            'email.required' => 'Email boş ola bilməz.',
            'email.email'    => 'Email düzgün deyil.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user = User::where('email', $request->email)->first();
        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Bu email ilə istifadəçi tapılmadı.',
            ], 422);
        }

        $otp = (string) random_int(100000, 999999);
        Cache::put('pw_otp:'.$user->email, Hash::make($otp), now()->addMinutes(self::TTL_MINUTES));

        Mail::raw(
            "Şifrənin bərpası üçün kod: {$otp}\nKod ".self::TTL_MINUTES." dəqiqə etibarlıdır.",
            fn ($m) => $m->to($user->email)->subject('Şifrənin bərpası')
        );

        return response()->json([
            'success' => true,
            'message' => 'Kod e-mail ünvanınıza göndərildi',
        ]);
    }

    public function change(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email'        => ['required', 'email'],
            'otp'          => ['required', 'digits:6'],
            'new_password' => ['required', 'string', 'min:6', 'confirmed'],
        ], [
            'otp.required'          => 'Təsdiq kodu boş ola bilməz.',
            'new_password.min'      => 'Şifrə ən azı 6 simvol olmalıdır.',
            'new_password.confirmed'=> 'Şifrələr eyni deyil.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors'  => $validator->errors(),
            ], 422);
        }

        $key    = 'pw_otp:'.$request->email;
        $hashed = Cache::get($key);

        if (! $hashed || ! Hash::check($request->otp, $hashed)) {
            return response()->json([
                'success' => false,
                'errors'  => ['otp' => ['Kod yanlışdır və ya vaxtı bitib']],
            ], 422);
        }

        $user = User::where('email', $request->email)->first();
        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Bu email ilə istifadəçi tapılmadı.',
            ], 422);
        }

        $user->password = Hash::make($request->new_password);
        $user->save();

        Cache::forget($key);

        return response()->json([
            'success' => true,
            'message' => 'Şifrəniz yeniləndi',
        ]);
    }
}
```

---

## 3. `POST /api/v1/updateProfile`

Header: `Authorization: Bearer <sanctum token>` (tətbiq avtomatik göndərir).

Sorğu:

```json
{ "name": "Ceyhun Alizade", "email": "ceyhun@bsb.edu.az", "phone": "0501234567" }
```

- `phone` boş sətir ola bilər — valideyn nömrəni silmək istəyirsə.
- E-mail dəyişəndə həmin hesab bundan sonra **yeni e-mail ilə** daxil olur;
  mövcud token etibarlı qalır, yəni sessiya qırılmır.

Uğurlu cavab (200) — `user` olmasa da olar:

```json
{ "success": true, "message": "Məlumatlar yeniləndi", "user": { ... } }
```

Xəta (422): `errors.name`, `errors.email`, `errors.phone` — hər biri formada öz
xanasının altında göstərilir.

## 4. `POST /api/v1/updatePassword`

Header: `Authorization: Bearer <sanctum token>`.

Sorğu:

```json
{
  "current_password": "kohneSifre",
  "new_password": "yeniSifre1",
  "new_password_confirmation": "yeniSifre1"
}
```

Uğurlu cavab (200): `{ "success": true, "message": "Şifrəniz yeniləndi" }`

Xəta (422) — cari şifrə yanlışdırsa, mesaj **öz xanasının altında** görünür:

```json
{ "success": false, "errors": { "current_password": ["Cari şifrə yanlışdır."] } }
```

> **Vacib:** cari tokeni ləğv etməyin — valideyn şifrəni dəyişən kimi
> tətbiqdən çıxarılar. Başqa cihazlardakı sessiyaları bağlamaq istəsəniz,
> yalnız *digər* tokenləri silin:
> `$user->tokens()->where('id', '!=', $request->user()->currentAccessToken()->id)->delete();`

```php
public function updatePassword(Request $request)
{
    $user = $request->user();

    $validator = Validator::make($request->all(), [
        'current_password' => ['required', 'string'],
        'new_password'     => ['required', 'string', 'min:6', 'confirmed'],
    ], [
        'current_password.required' => 'Cari şifrəni daxil edin.',
        'new_password.min'          => 'Şifrə ən azı 6 simvol olmalıdır.',
        'new_password.confirmed'    => 'Şifrələr eyni deyil.',
    ]);

    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'errors'  => $validator->errors(),
        ], 422);
    }

    if (! Hash::check($request->current_password, $user->password)) {
        return response()->json([
            'success' => false,
            'errors'  => ['current_password' => ['Cari şifrə yanlışdır.']],
        ], 422);
    }

    $user->password = Hash::make($request->new_password);
    $user->save();

    return response()->json([
        'success' => true,
        'message' => 'Şifrəniz yeniləndi',
    ]);
}
```

## 5. `POST /api/v1/updateChildEmail`

Sorğu:

```json
{ "child_id": 3139, "email": "resad@bsb.edu.az" }
```

- `child_id` — `/login` cavabındakı `info[].child_id`.
- **Mütləq yoxlanmalıdır:** şagird sorğunu göndərən valideynin hesabına bağlıdırmı.
  Bağlı deyilsə **403**. (Tətbiq də öz tərəfindən yoxlayır, amma bu kifayət deyil.)

Uğurlu cavab (200) — `user`, `info` və ya sadəcə təsdiq:

```json
{ "success": true, "message": "Şagirdin e-mail ünvanı yeniləndi", "info": [ ... ] }
```

Xətalar: **403** (başqasının şagirdi), **422** (e-mail artıq istifadə olunur / düzgün deyil).

### Nümunə controller

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    public function update(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'name'  => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', Rule::unique('users', 'email')->ignore($user->id)],
            'phone' => ['nullable', 'string', 'max:32'],
        ], [
            'name.required'  => 'Ad boş ola bilməz.',
            'email.required' => 'Email boş ola bilməz.',
            'email.email'    => 'Email düzgün deyil.',
            'email.unique'   => 'Bu email artıq istifadə olunur.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Məlumatlar yenilənmədi',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user->fill($validator->validated())->save();

        return response()->json([
            'success' => true,
            'message' => 'Məlumatlar yeniləndi',
            // '/login' ilə eyni formada. Qaytarmasanız da tətbiq göndərdiyi
            // dəyərləri özü keşə yazır.
            'user'    => $this->userPayload($user),
        ]);
    }

    public function updateChildEmail(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'child_id' => ['required', 'integer'],
            'email'    => ['required', 'email',
                           Rule::unique('users', 'email')->ignore($request->child_id)],
        ], [
            'email.email'  => 'Email düzgün deyil.',
            'email.unique' => 'Bu email artıq istifadə olunur.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors'  => $validator->errors(),
            ], 422);
        }

        // ⬇️ Bu sətir sizin sxeminizə görə dəyişir: valideyn–şagird əlaqəsi
        // hansı cədvəl/münasibətlə saxlanılırsa, ondan istifadə edin.
        $child = $user->children()->where('id', $request->child_id)->first();

        if (! $child) {
            return response()->json([
                'success' => false,
                'message' => 'Bu şagird sizin hesabınıza bağlı deyil.',
            ], 403);
        }

        $child->email = $request->email;
        $child->save();

        return response()->json([
            'success' => true,
            'message' => 'Şagirdin e-mail ünvanı yeniləndi',
            // '/login' cavabındakı `info` massivinin eynisi.
            'info'    => $this->childrenPayload($user),
        ]);
    }
}
```

### `routes/api.php`

```php
Route::prefix('v1')->group(function () {
    Route::post('/forgotPassword', [PasswordResetController::class, 'sendCode'])
        ->middleware('throttle:5,1');
    Route::post('/changePassword', [PasswordResetController::class, 'change'])
        ->middleware('throttle:5,1');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/updateProfile',     [ProfileController::class, 'update']);
        Route::post('/updatePassword',    [ProfileController::class, 'updatePassword']);
        Route::post('/updateChildEmail',  [ProfileController::class, 'updateChildEmail']);
    });
});
```

---

## Yoxlama

Endpointləri yazandan sonra tətbiqi açmadan da sınaya bilərsiniz:

```bash
curl -X POST https://online.bsb.edu.az/api/v1/forgotPassword \
  -H 'Accept: application/json' -H 'Content-Type: application/json' \
  -d '{"email":"ceyhun@bsb.edu.az"}'

curl -X POST https://online.bsb.edu.az/api/v1/updateProfile \
  -H 'Accept: application/json' -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <token>' \
  -d '{"name":"Ceyhun Alizade","email":"ceyhun@bsb.edu.az","phone":"0501234567"}'
```

404 gəlirsə route qeydə alınmayıb; 401 gəlirsə token göndərilməyib; 422 gəlirsə
validasiya işləyir və tətbiq mesajı olduğu kimi istifadəçiyə göstərəcək.
