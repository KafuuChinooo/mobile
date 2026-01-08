<img src="https://drive.google.com/file/d/179ooMjmfAtE-3mN5tQdcehsobaUfc2n7/view?usp=sharing" alt="Logo" width="200"/>

# Memzy (Flash Card)
Ứng dụng flashcard hỗ trợ học tập, đăng nhập Firebase, sinh đáp án nhiễu/hint bằng AI.

## Yêu cầu
- Flutter SDK (Dart >= `3.9.2`, kênh stable)
- Có sẵn Firebase project: tải `google-services.json` vào `android/app/`
- Khóa API Gemini: điền vào `lib/services/ai_distractor_service.dart` và `lib/services/hint_service.dart` nếu cần

## Cài đặt
1) Kiểm tra môi trường: `flutter doctor`
2) Cài dependency:  
   ```bash
   flutter pub get
   ```
3) (Tuỳ chọn) Cấu hình lại Firebase nếu thay project:  
   ```bash
   flutterfire configure
   ```

## Chạy ứng dụng
- Thiết bị thật/giả lập: `flutter run -d <device_id>`
- Web (nếu bật): `flutter run -d chrome`

## Thư mục chính
- `lib/` mã nguồn Flutter
- `images/` assets giao diện
- `firebase_options.dart` cấu hình Firebase do FlutterFire sinh


