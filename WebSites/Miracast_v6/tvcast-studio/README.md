# TVCast Studio Support Site

Folder này là một Firebase Hosting site độc lập cho support pages của app.

## Giá trị hiện tại

- Firebase project / host folder: `tvcast-studio`
- Website URL: `https://tvcast-studio.web.app`
- App display name trên UI: `Smart TV Cast`
- Company name trên UI: `TVCast Studio Co,.Ltd`
- Hidden feedback app name: `Miracast_v6`
- Public folder Firebase: `HTML`

## Cấu trúc file

- `HTML/contact.html`: trang contact và form feedback.
- `HTML/privacy.html`: trang privacy policy.
- `HTML/term.html`: trang terms of use.
- `Deploy/site-config.txt`: cấu hình redirect trang gốc.
- `Deploy/deploy.sh`: lệnh deploy nhanh cho site này.
- `firebase.json`: Firebase Hosting config, dùng `"public": "HTML"`.
- `.firebaserc`: Firebase project id cho site.
- `Website.txt`: tự tạo/cập nhật sau khi deploy thành công.

## Khi copy sang project khác

1. Copy cả folder site này.
2. Đổi tên folder site thành Firebase project id mới, chỉ dùng chữ thường, số và dấu `-`.

Ví dụ:

```bash
cp -R tvcast-studio tvcast-studio-1
```

3. Sửa 3 file trong `HTML/`.

Các giá trị cần thay:

- Đổi app display name: tìm `Smart TV Cast`.
- Đổi company name: tìm `TVCast Studio Co,.Ltd`.
- Đổi hidden app name trong `HTML/contact.html`:

```html
<input type="hidden" name="App Name" value="Miracast_v6">
```

- Đổi support URL text nếu đổi host:

```text
https://tvcast-studio.web.app/contact
```

4. Không sửa file trong `.firebase/` hoặc `Website.txt`; các file này do deploy tự tạo/cập nhật.

## Deploy sau khi sửa

Chạy từ folder `Deploy` của site:

```bash
cd /Users/thi/Desktop/SupportHTML/Firebase_Host/WebSites/Miracast_v6/tvcast-studio/Deploy
./deploy.sh
```

Nếu copy sang site khác, vào đúng `Deploy` của site đó rồi chạy:

```bash
./deploy.sh
```

Sau khi deploy thành công, script sẽ tự tạo/cập nhật `Website.txt` với 3 URL:

- `/contact`
- `/term`
- `/privacy`

## Kiểm tra nhanh trước deploy

```bash
cd /Users/thi/Desktop/SupportHTML/Firebase_Host
bash tests/test_support_html_content.sh
tests/test_deploy_site.sh
```

Lưu ý: `tests/test_support_html_content.sh` hiện đang kiểm tra riêng site `tvcast-studio`. Khi tạo site mới, có thể dùng file này làm mẫu để kiểm tra site mới.

## Lưu ý quan trọng

- Chỉ sửa file gốc trong `HTML/`.
- `firebase.json` phải nằm ngay dưới folder site và dùng `"public": "HTML"`.
- `Deploy/deploy.sh` sẽ lấy tên folder site làm Firebase project id.
- Nếu Firebase báo tên project đã bị dùng, đổi tên folder site rồi chạy lại deploy.
- Email nhận feedback không hiển thị trên UI, nhưng vẫn nằm trong source JS của `contact.html` vì form đang gửi trực tiếp qua FormSubmit.
