# تشغيل Worker تعدين XMR على Heroku للتطبيق afdaa

هذه الحزمة مصممة لتجنب خطأ:

`No default language could be detected for this app`

لذلك لا تعتمد على Docker ولا heroku.yml. بدلًا من ذلك تحتوي على:

- `requirements.txt` حتى يتعرف Heroku على التطبيق كتطبيق Python.
- `Procfile` لتشغيل العملية كـ `worker`.
- `run_miner.py` لتحميل XMRig وتشغيله عند بدء الـ dyno.

## أين أضع عنوان المحفظة؟

افتح:

```bash
nano config.env
```

وغيّر السطر:

```bash
XMR_WALLET="PUT_YOUR_XMR_RECEIVE_ADDRESS_HERE"
```

إلى عنوان محفظة XMR من زر Receive / استلام:

```bash
XMR_WALLET="عنوان_XMR_الخاص_بك"
```

لا تضع Seed Phrase ولا Private Key.

## التشغيل

```bash
unzip heroku_xmr_afdaa_python_v3.zip
cd heroku_xmr_afdaa_python_v3
chmod +x *.sh
nano config.env
bash quick_start.sh
```

## مراقبة التشغيل

```bash
bash logs.sh
```

إذا ظهرت كلمة:

`accepted`

فهذا يعني أن الـ pool قبل المشاركات وأن التعدين يعمل.

## إيقاف التعدين

```bash
bash stop.sh
```

## ملاحظات مهمة

- استخدم هذه الحزمة فقط إذا لديك موافقة مكتوبة من Heroku للتطبيق والحساب نفسه.
- لا ترفع ملف `config.env` إلى مكان عام لأنه يحتوي عنوان المحفظة.
- إذا كانت Heroku Dyno محدودة CPU، اترك `XMR_THREADS=2` للبداية.
