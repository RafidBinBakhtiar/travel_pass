lib/
├── core/
│   ├── constants/app_colors.dart
│   ├── constants/app_fonts.dart
│   ├── network/
│   │   ├── dio_client.dart          ← Dio + interceptor
│   │   └── token_storage.dart       ← save/read tokens
├── features/
│   └── auth/
│       ├── data/
│       │   ├── auth_repository.dart  ← API calls
│       │   └── auth_models.dart      ← request/response models
│       ├── provider/
│       │   └── auth_provider.dart    ← Riverpod providers
│       └── screens/
│           └── login_screen.dart
├── l10n/
│   ├── app_en.arb
│   └── app_bn.arb
│
├── models
│   ├──user.dart
│
├── screens
│   ├──home_screen.dart
│   ├──login.dart
│   ├──registration.dart
│   ├──splash_screen.dart
│
└── main.dart


Implement the forget password section while being clicked on "Forget Password" button. At first upon getting clicked on "Forget Password" button, it will ask for "emailOrPhone". Then it will take that "পাসওয়ার্ড ভুলে গেছেন?" page. Then the user will give his "emailOrPhone" and hit "এগিয়ে যান" button. If the "emailOrPhone" is verified then it will take to the next page where he will be asked for an OTP. 

The "ওটিপি যাচাইকরণ" page will get this json. 

{
    "emailOrPhone": "+8801534522302",
    "otp": "1234"
}
This page will get response of 
{
    "success": true,
    "message": "Operation successful",
    "data": {
        "resetToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjUsInB1cnBvc2UiOiJwYXNzd29yZF9yZXNldCIsImlhdCI6MTc3NTYxOTY5MSwiZXhwIjoxNzc1NjIwNTkxfQ.1dVfoyX9mkAyt8L_X1iyJ4fLfdWKVOFN-eKu64LPbMI",
        "message": "OTP verified successfully. Use the token to reset your password."
    },
    "errors": null
}

The resetToken will be passed on for setting new pasword page. "নতুন পাসওয়ার্ড সেট করুন" page will get this 
{
    "resetToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjUsInB1cnBvc2UiOiJwYXNzd29yZF9yZXNldCIsImlhdCI6MTc3NTYxOTY5MSwiZXhwIjoxNzc1NjIwNTkxfQ.1dVfoyX9mkAyt8L_X1iyJ4fLfdWKVOFN-eKu64LPbMI",
    "newPassword": "NewPass123!",
    "confirmPassword": "NewPass123!"
}

After that there will be a congratulating page. Which will say, "অভিনন্দন!". 

//................//.................................
Forget Password:

There is two type of OTP verification, one is email OTP and other is phone OTP. The app will decide on the basis of user input. A user must have his phone number verified in order to register in the application but the email field is not mandatory for registering. So you have to make sure that a user who has no email cannot request for email OTP. 

‘এগিয়ে যান’ Button will be disabled until user input OTP.
If user don’t get OTP in one minute ‘আবার ওটিপি পাঠান’ button will be activated automatically. There will be a dynamic countdown to enter the OTP. If user pressed ‘আবার ওটিপি পাঠান’ button, A toaster will be shown here. User have to wait 1min after every time user request OTP. "ভুল নম্বর দিয়েছেন? পরিবর্তন করুন" will take him to previous page where email/phone is asked. 



Registration:
Also make the registration_screen updated, the registration will be confirmed through a OTP verification. A user CAN provide Email/Phone, but Email field can be empty, it depends on the user how he would like to be verified. But he must have to verify his phone number but if he wants he can verify his email as well. 

Without email JSON
{
    "fullName": "Rafid Bin Bakhtiar",
    "phone": "+8801234567891",
    "password": "123456",
    "touristType": "DOMESTIC"
}
With email JSON
{
    "fullName": "Rafid Bin Bakhtiar",
    "email": "abc@gamil.com"
    "phone": "+8801234567891",  
    "password": "123456",
    "touristType": "DOMESTIC"
}



=============================!!=====================================

Registration flow in your project
1. Entry point
The user reaches registration from the login screen.
login_screen.dart
The register link navigates to RegistrationScreen.
2. Registration form
registration_screen.dart
RegistrationScreen collects:
full name
phone
email
password
tourist type (DOMESTIC / FOREIGN)
It validates the form and then calls:
ref.read(registerProvider.notifier).register(RegisterRequest(...))
3. State management
register_provider.dart
Defines registration states:
RegisterInitial
RegisterLoading
RegisterNeedsPhoneVerification
RegisterNeedsEmailVerification
RegisterSuccess
RegisterError
register() sends the request to AuthRepository
verifyOtp() sends OTP verification to AuthRepository
resendOtp() calls the repository resend endpoint
4. Backend interaction
auth_repository.dart
register(RegisterRequest request)
POST /auth/register
If success:
returns RegisterNeedsPhoneOtp(request.phone) when both phone and email are present
otherwise returns RegisterNeedsEmailOtp(request.email)
On failure: throws exception with API message
verifyPhoneOtp(String emailOrPhone, String otp)
POST /auth/verify-login
This is the OTP verification endpoint used after registration
resendOtp(String emailOrPhone)
POST /auth/resend-otp
5. OTP verification screen
RegistrationOtpScreen in registration_screen.dart
Shows masked phone/email
Accepts OTP input
Allows resend after a countdown
When verify succeeds:
provider state becomes RegisterSuccess
it sets verificationStatusProvider true
then navigates to RegistrationSuccessScreen
6. Success handling
RegistrationSuccessScreen in registration_screen.dart
Displays a success message
Has a button that pops back to the first route
7. App-wide verification status
main.dart
verificationStatusProvider tracks whether the user is considered verified
On startup it checks secure token storage
Registration OTP success sets it to true via setVerified(true)
Key behavior summary
Registration is a two-step flow:
Submit details to /auth/register
Verify OTP via /auth/verify-login
The UI and state are separated:
UI in registration_screen.dart
registration state in register_provider.dart
API calls in auth_repository.dart
request/result models in auth_models.dart
Important note
The registration flow currently does not appear to save auth tokens after OTP verification.
Instead, it marks verification status true and then shows success.
If you want, I can also trace how verificationStatusProvider drives the splash/login/home navigation after registration.



======================!========================
Issues:
1. Dashboard Issue -> The registration flow currently does not appear to save auth tokens after OTP verification. After registration is completed, it will redirect to dashboard. 
2. When I verify OTP during login, it is saying Insufficient Permissions. But when I try to verify OTP again, it is saying "OTP is verified. Please perform a regular login". That means it has verified OTP in the first place but has said, "Insufficient Permissions". So you need to fix that. 
3. All OTP page should follow one certain design and principle. Let it be Login OTP, the OTP verification after registration. The OTP page after registration is the benchmark of OTP page and validation. Every OTP page should look like that (like having timer countdown, the OTP placeholder design, If user pressed ‘আবার ওটিপি পাঠান’ button, A toaster will be shown in the top).
4. In registration_screen the, "অন্তত ৮টি অক্ষর হতে হবে
একটি বড় হাতের অক্ষর (A-Z) ও একটি সংখ্যা (0-9) থাকতে হবে
একটি বিশেষ চিহ্ন (যেমন: @, #, $) থাকতে হবে" isn't dyanmic. Make it dynamic.



============================!================================
- 1. Dashboard Issue -> The registration flow currently does not appear to save auth tokens after OTP verification. After registration is completed, it will redirect to dashboard. (Not working)
- 2. I/flutter (11459): ❌ REGISTER ERROR: 400 {success: false, message: Validation Failed, data: null, errors: {email: email must be an email}}
-The email is just an optional field. But a user can verify their email if he has provided his email during registration. 

- 3. None of the password's condition is being applied in registration_screen, if I register with password "123456" it just accepts. So, the password condition is not imposed. 
"অন্তত ৮টি অক্ষর হতে হবে
একটি বড় হাতের অক্ষর (A-Z) ও একটি সংখ্যা (0-9) থাকতে হবে
একটি বিশেষ চিহ্ন (যেমন: @, #, $) থাকতে হবে"
The registration password checking is still not dynamic.

- 4. All OTP page should follow one certain design and principle. Try to duplicate the OTP page. After registration when OTP screen appears and there is a button named "আবার ওটিপি পাঠান". If user pressed ‘আবার ওটিপি পাঠান’ button, A toaster will be shown. There is two OTP states, one is OTP filled, and when OTP is blank. Try to replicate the exact design. ‘এগিয়ে যান’ Button will be disabled until user input OTP. If user don’t get OTP in one second ‘আবার ওটিপি পাঠান’ button will be activated automatically.

- 5. In every OTP page there is a button named "পরিবর্তন করুন". We have OTP verification in three places, Forgot Password, Registration and Login. Regardless of the case the "পরিবর্তন করুন" button will take towards the previous page.

==============================!================================

- 1. After taking the user's credentials, we send them to the backend. The backend responds with one of two scenarios:

Scenario A: Fully Verified Account (No OTP Needed)
If the phone or email is already fully verified from a previous login, the API response directly includes an accessToken and refreshToken.
The AuthRepository reads these tokens, saves them into Secure Storage using _saveAuthTokens(data), and returns a LoginHasTokens object to AuthNotifier.
Then, Riverpod emits AuthDirectSuccess, immediately redirecting the user straight to the Home Screen (Skipping OTP).
Scenario B: Registered, But Not Yet Verified (OTP Required)
Sometimes users register but don't finish their OTP validation. As our system has made email field optional, the user must verify his phone number but not obliged to verify his email (He can verify his email though). If he provided his email address during registration, he can login with email although he didn't verify his email, so we will take him to OTP_email verification page. So, when he logs in with email if his email is not verified he will have to verify his email and then he will be taken to dashboard.

- 2. If the user is sent to the OTP Screen, they are required to input the 4-digit code.

Countdown Timer: Starts a 60-second loop. Once hitting 0, it logically activates the "Resend OTP (আবার পাঠান)" button giving the user a chance to ask to be sent the pin again.
Submit Validation: As the user begins typing, the Verify button ("এগিয়ে যান") disables until the input reaches exactly 4 characters.

- 3. Closely observe the otp_pin_field the screenshot I provided and implement every single features I told for OTP_page, all OTP_page should follow a single design. 


=======================!=================================

A new update, previously we were verifying the phone if it was not verified, the registration could be successful without even verifying the phone just by clicking "অ্যাকাউন্ট তৈরি করুন". But now a account cannot be possible to be created without verifying the phone OTP. After a registration, there must be a OTP verification stage, if a user clicks "পরিবর্তন করুন" then it will just take to previous state none of the information will be erased as we have a unified OTP verification system.

We have a new API, /auth/verify-registration

{
    "phone": "+8801700000000",
    "otp": "1234"
}

==========================!============================
So, authentication part is complete. Now, let's do the profile part. So, we have home_screen.dart which we call dashboard. A user logs in and enter in dashboard. So, there is a "Profile" button in the top right corner. When a user clicks on "Profile" button, it will take him to the profile page. The design of profile page is given. 

1. {{base_url}}/auth/me (GET)
Response: 
{
    "success": true,
    "message": "Operation successful",
    "data": {
        "id": 3,
        "fullName": "Rafid",
        "email": "rafid@gmail.com",
        "phone": "+8801907199135",
        "isEmailVerified": true,
        "roles": [
            "tourist"
        ],
        "permissions": [
            "applications.read",
            "applications.create",
            "applications.update",
            "applications.delete"
        ]
    },
    "errors": null
}

2. {{base_url}}/auth/me (PUT)
Request:
{
    "fullName": "System Admin (Updated)",
    "email": "admin.updated@tourism.com",
    "phone": "+8801700000001",
    "touristType": "DOMESTIC"
}
3. {{base_url}}/auth/change-password
{
    "currentPassword": "Admin@123",
    "newPassword": "NewSecret123!"
}


