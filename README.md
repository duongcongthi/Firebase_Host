# Firebase Hosting Helper

Folder này dùng để quản lý nhiều support website Firebase Hosting. Mỗi site nằm trong một folder riêng dưới:

```text
WebSites/<group>/<site-name>/
```

Ví dụ hiện tại:

```text
WebSites/
  Miracast_v6/
    tvcast-studio/
      HTML/
        contact.html
        privacy.html
        term.html
      Deploy/
        site-config.txt
        deploy.sh
      .firebaserc
      firebase.json
      README.md
      Website.txt
```

## File Quan Trọng

- `HTML/contact.html`: trang contact và form feedback.
- `HTML/privacy.html`: trang privacy policy.
- `HTML/term.html`: trang terms of use.
- `Deploy/site-config.txt`: cấu hình redirect trang gốc, thường là `ROOT_REDIRECT=/contact`.
- `Deploy/deploy.sh`: script deploy nhanh cho đúng site đó.
- `firebase.json`: nằm ngay dưới folder site, dùng `"public": "HTML"`.
- `.firebaserc`: Firebase project id, lấy theo tên folder site.
- `README.md`: ghi chú riêng của từng site.
- `Website.txt`: tự tạo/cập nhật sau khi deploy thành công.

## Quy Tắc Khi Tạo Site Mới

1. Copy một folder site có sẵn.

```bash
cp -R WebSites/Miracast_v6/tvcast-studio WebSites/Miracast_v6/tvcast-studio-1
```

2. Đổi tên folder site thành Firebase project id mới.

Tên folder chỉ nên dùng:

- chữ thường `a-z`
- số `0-9`
- dấu gạch ngang `-`

Ví dụ:

```text
tvcast-studio
tvcast-studio-1
miracast-support
```

3. Sửa 3 file trong `HTML/`.

Các giá trị thường cần sửa:

- App display name: ví dụ `Smart TV Cast`.
- Company name: dùng tên site hiển thị + `Co,.Ltd`, ví dụ `TVCast Studio Co,.Ltd`.
- Hidden feedback app name trong `HTML/contact.html`:

```html
<input type="hidden" name="App Name" value="Miracast_v6">
```

- Support URL text nếu đổi host:

```text
https://PROJECT_ID.web.app/contact
```

4. Sửa `README.md` trong folder site để ghi lại giá trị thật của site đó.

## Deploy Một Site

Chạy từ root folder này:

```bash
scripts/deploy_site.sh WebSites/Miracast_v6/tvcast-studio --dry-run
scripts/deploy_site.sh WebSites/Miracast_v6/tvcast-studio
```

Hoặc chạy từ folder `Deploy` của site:

```bash
cd WebSites/Miracast_v6/tvcast-studio/Deploy
./deploy.sh --dry-run
./deploy.sh
```

## Deploy Tất Cả Site

```bash
scripts/deploy_all.sh --dry-run
scripts/deploy_all.sh
```

## Site Config

Mỗi site cần có:

```text
Deploy/site-config.txt
```

Nội dung tối thiểu:

```text
ROOT_REDIRECT=/contact
```

Project id luôn lấy từ tên folder site:

```text
WebSites/Miracast_v6/tvcast-studio/   -> https://tvcast-studio.web.app
WebSites/Miracast_v6/tvcast-studio-1/ -> https://tvcast-studio-1.web.app
```

## Sau Khi Deploy Thành Công

Script sẽ tự tạo/cập nhật `Website.txt`:

```text
URL Website 
PROJECT_ID.web.app/contact
PROJECT_ID.web.app/term
PROJECT_ID.web.app/privacy
```

Script cũng in ra:

- `https://PROJECT_ID.web.app/contact`
- `https://PROJECT_ID.web.app/privacy`
- `https://PROJECT_ID.web.app/term`

## Kiểm Tra Nhanh

```bash
bash tests/test_support_html_content.sh
tests/test_deploy_site.sh
```

Lưu ý: `tests/test_support_html_content.sh` hiện kiểm tra riêng site mẫu `tvcast-studio`. Khi tạo site mới, có thể copy test này hoặc sửa biến trong test để kiểm tra site mới.

## Lưu Ý

- Chỉ sửa file gốc trong `HTML/`.
- Không sửa `.firebase/`; đây là cache của Firebase CLI.
- Không sửa `Website.txt` bằng tay; file này do deploy cập nhật.
- Nếu Firebase báo tên project đã được dùng, đổi tên folder site rồi chạy deploy lại.
- Nếu deploy lỗi, `Website.txt` sẽ không được ghi mới.
- Email nhận feedback không hiển thị trên UI, nhưng vẫn nằm trong source JS của `contact.html` vì form đang gửi trực tiếp qua FormSubmit.
