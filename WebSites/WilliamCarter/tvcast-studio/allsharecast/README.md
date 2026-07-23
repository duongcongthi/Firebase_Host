# AllShareCast Support Site

App support pages này nằm trong Firebase host `tvcast-studio`.

## Giá Trị Hiện Tại

- Account folder: `WilliamCarter`
- Firebase project / host: `tvcast-studio`
- App path: `allsharecast`
- Website URL: `https://tvcast-studio.web.app/allsharecast`
- Contact URL: `https://tvcast-studio.web.app/allsharecast/contact`
- Term URL: `https://tvcast-studio.web.app/allsharecast/term`
- Privacy URL: `https://tvcast-studio.web.app/allsharecast/privacy`
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
cd /Users/thi/Desktop/SupportHTML/Firebase_Host/WebSites/WilliamCarter/tvcast-studio/allsharecast/Deploy
./deploy.sh --dry-run
./deploy.sh
```

Deploy từ app này sẽ gom cả các app cùng host `tvcast-studio` vào `FirebaseHostingPublic/` rồi deploy một lần.

## Ghi Chú

- HTML đang được copy tạm thời từ source cũ, cần sửa nội dung app/company/app name sau nếu khác.
- URL public phải luôn có prefix `/allsharecast/...`.
- Không sửa `.firebase/` hoặc `FirebaseHostingPublic/` bằng tay.
