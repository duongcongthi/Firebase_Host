# Firebase Hosting Helper

Each Firebase site lives in its own folder under `WebSites/<group>/<site-name>/`.

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
        firebase.json
        deploy.sh
      Website.txt
```

## Deploy One Site

```bash
scripts/deploy_site.sh WebSites/Miracast_v6/tvcast-studio --dry-run
scripts/deploy_site.sh WebSites/Miracast_v6/tvcast-studio
```

Or from inside the site folder:

```bash
cd WebSites/Miracast_v6/tvcast-studio/Deploy
./deploy.sh --dry-run
./deploy.sh
```

## Deploy All Sites

```bash
scripts/deploy_all.sh --dry-run
scripts/deploy_all.sh
```

## Site Config

Each `site-config.txt` can be very small:

```text
ROOT_REDIRECT=/contact
```

The Firebase project id is always taken from the folder name. For example:

```text
WebSites/Miracast_v6/tvcast-studio/   -> https://tvcast-studio.web.app
WebSites/Miracast_v6/tvcast-studio-1/ -> https://tvcast-studio-1.web.app
```

To create another site, copy an existing folder and rename it:

```bash
cp -R WebSites/Miracast_v6/tvcast-studio WebSites/Miracast_v6/tvcast-studio-1
scripts/deploy_site.sh WebSites/Miracast_v6/tvcast-studio-1 --dry-run
scripts/deploy_site.sh WebSites/Miracast_v6/tvcast-studio-1
```

The script writes `Deploy/firebase.json` and `Deploy/.firebaserc`. After a successful deploy, it writes `Website.txt`:

```text
URL Website 
PROJECT_ID.web.app/contact
PROJECT_ID.web.app/term
PROJECT_ID.web.app/privacy
```

It also prints:

- `https://PROJECT_ID.web.app/contact`
- `https://PROJECT_ID.web.app/privacy`
- `https://PROJECT_ID.web.app/term`

## Notes

- `PROJECT_ID` must be globally unique on Firebase.
- The script does not store passwords or tokens.
- If the site name is already used globally, deploy stops with `Could not create Firebase project` and tells you to rename the site folder.
- If deploy fails, `Website.txt` is not written or refreshed.
- If Firebase asks for Terms of Service, open Firebase Console once, accept the required terms, then run the script again.
