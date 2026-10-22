# WebView wrapper example

Wraps a website as an installable APK — the seed of the **web2apk** idea
("URL do, APK lo").

## Build it

```bash
../../gradleless.sh --src . --out MySite.apk \
  --name "My Site" --package com.example.mysite
```

## Point it at a live site

Edit `java/MainActivity.java` and change:

```java
private static final String START_URL = "file:///android_asset/www/index.html";
```

to your URL, e.g. `"https://example.com"`, then rebuild.
The bundled `assets/www/index.html` demo page is ignored for live URLs.
