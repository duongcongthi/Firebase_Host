# AllShareCast Support Site

App support pages này nằm trong Firebase host `tvmirror-labs`.

## Giá Trị Hiện Tại

- Account folder: `JamesAnderson`
- Firebase project / host: `tvmirror-labs`
- App path: `allsharecast`
- Website URL: `https://tvmirror-labs.web.app/allsharecast`
- Contact URL: `https://tvmirror-labs.web.app/allsharecast/contact`
- Term URL: `https://tvmirror-labs.web.app/allsharecast/term`
- Privacy URL: `https://tvmirror-labs.web.app/allsharecast/privacy`
- Public source folder: `HTML`

## Cấu Trúc File

- `HTML/contact.html`: trang contact và form feedback.
- `HTML/privacy.html`: trang privacy policy.
- `HTML/term.html`: trang terms of use.
- `Deploy/site-config.txt`: root redirect cho host khi deploy từ app này.
- `Deploy/deploy.sh`: lệnh deploy nhanh cho app này.
- `firebase.json`: config tham chiếu public folder chung ở cấp host.
- `Website.txt`: tự tạo/cập nhật sau khi deploy thành công.

## Deploy

```bash
cd /Users/thi/Desktop/SupportHTML/Firebase_Host/WebSites/JamesAnderson/tvmirror-labs/allsharecast/Deploy
./deploy.sh --dry-run
./deploy.sh
```

Deploy từ app này sẽ gom cả các app cùng host `tvmirror-labs` vào `FirebaseHostingPublic/` rồi deploy một lần.

## Ghi Chú

- HTML đang được copy tạm thời từ source cũ, cần sửa nội dung app/company/app name sau nếu khác.
- URL public phải luôn có prefix `/allsharecast/...`.
- Không sửa `.firebase/` hoặc `FirebaseHostingPublic/` bằng tay.
