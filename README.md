# Firebase Hosting Helper

Folder này quản lý nhiều support website Firebase Hosting. Một Firebase host có thể chứa nhiều app con.

## Cấu Trúc Chuẩn

```text
WebSites/
  <account-name>/
    <firebase-host>/
      .firebaserc
      firebase.json
      FirebaseHostingPublic/
      <app-name>/
        HTML/
          contact.html
          privacy.html
          term.html
        Deploy/
          site-config.txt
          deploy.sh
        firebase.json
        README.md
        Website.txt
```

Ví dụ hiện tại:

```text
WebSites/
  WilliamCarter/
    tvcast-studio/
      miracast/
      allsharecast/
  JamesAnderson/
    tvmirror-labs/
      miracast/
      allsharecast/
```

## URL Sau Khi Deploy

Mỗi app được publish dưới path riêng của cùng host:

```text
https://tvcast-studio.web.app/miracast/contact
https://tvcast-studio.web.app/miracast/term
https://tvcast-studio.web.app/miracast/privacy

https://tvcast-studio.web.app/allsharecast/contact
https://tvcast-studio.web.app/allsharecast/term
https://tvcast-studio.web.app/allsharecast/privacy
```

Tương tự với host khác:

```text
https://tvmirror-labs.web.app/miracast/contact
https://tvmirror-labs.web.app/allsharecast/contact
```

## Quy Tắc Deploy

- Firebase project id lấy theo folder `<firebase-host>`, ví dụ `tvcast-studio`.
- App path lấy theo folder `<app-name>`, ví dụ `miracast`.
- File `.firebaserc` đặt ở cấp host: `WebSites/<account>/<firebase-host>/.firebaserc`.
- Chạy deploy từ một app sẽ build và deploy toàn bộ app cùng host để không xóa nhầm path của app khác.
- `FirebaseHostingPublic/` là folder public được generate tự động ở cấp host.
- `Website.txt` chỉ được cập nhật sau khi deploy thật thành công.

## Deploy Một App

Chạy từ root folder này:

```bash
scripts/deploy_site.sh WebSites/WilliamCarter/tvcast-studio/miracast --dry-run
scripts/deploy_site.sh WebSites/WilliamCarter/tvcast-studio/miracast
```

Hoặc chạy từ folder `Deploy` của app:

```bash
cd WebSites/WilliamCarter/tvcast-studio/miracast/Deploy
./deploy.sh --dry-run
./deploy.sh
```

Lưu ý: dù gọi deploy từ `miracast`, script vẫn gom cả các app cùng host như `allsharecast` vào một lần deploy.

## Deploy Tất Cả

```bash
scripts/deploy_all.sh --dry-run
scripts/deploy_all.sh
```

## Tạo App Mới Trong Một Host Có Sẵn

Copy một app folder có sẵn:

```bash
cp -R WebSites/WilliamCarter/tvcast-studio/miracast WebSites/WilliamCarter/tvcast-studio/newapp
```

Sau đó sửa:

- `HTML/contact.html`
- `HTML/privacy.html`
- `HTML/term.html`
- `Deploy/site-config.txt`
- `README.md`

`Deploy/site-config.txt` nên trỏ root về contact page của app:

```text
ROOT_REDIRECT=/newapp/contact
```

## Kiểm Tra Nhanh

```bash
bash tests/test_support_html_content.sh
tests/test_deploy_site.sh
```

## Lưu Ý

- Chỉ sửa file gốc trong `HTML/`.
- Không sửa `.firebase/`; đây là cache của Firebase CLI.
- Không sửa `FirebaseHostingPublic/` bằng tay; folder này do script generate.
- Không sửa `Website.txt` bằng tay nếu không cần, vì deploy thật sẽ cập nhật lại.
- Nếu Firebase báo tên project đã được dùng, đổi tên folder host rồi deploy lại.
- Nếu deploy lỗi, `Website.txt` sẽ không được ghi mới.
