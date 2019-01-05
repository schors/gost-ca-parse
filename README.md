Russian Certificate Authorities list XML-file converter
=======================================================


What is it?
-----------

Toolset converts "Gosuslugi" Russian Certificate Authorities list XML-file to standard PEM format.
This should not be used in real life. Use the prepared data: https://github.com/schors/gost-russian-ca

In fact, this is the task of the [Minsvyaz](http://minsvyaz.ru). It must do this, but it can't. I don't know why. 
I don't have to do this. But I can.

Features
--------
* Version test
* git integration
* Very simple fast-maded code without strict error handling
* Powered by [Usher II](https://usher2.club)
* Rostelecom doesn't provide some HTTP features such as If-Modified-Since and Accept-Encoding. This is depressing

Requirements
------------

* wget
* xmllint
* golang
* git (for git integration)

Very simple usage
-----------------

Prepare directories:
```console
mkdir -p ~/gost-russian-ca/certs
```

Compile:
```console
go build -o ~/gost-russian-ca/gost-ca-parse
```

Just test it:
```console
~/gost-ca-parse/parse.sh ~/gost-russian-ca/CA.xml ~/gost-russian-ca/certs ~/gost-russian-ca/gost-ca-parse
```

Put line in the crontab:
```console
30 */4 * * * flock -x -n /tmp/gost-ca-parse.lock ~/gost-ca-parse/parse.sh ~/gost-russian-ca/CA.xml ~/gost-russian-ca/certs ~/gost-russian-ca/gost-ca-parse >/dev/null 2>&1
```

Links
-----

* [Gosuslugi e-trust](http://e-trust.gosuslugi.ru/CA) Portal of Russian Federal Authority of using electronic signature

For nuts
--------

* PayPal https://www.paypal.me/schors
* Yandex.Money http://yasobe.ru/na/schors
* BTC: 18YFeAV12ktBxv9hy4wSiSCUXXAh5VR7gE
* LTC: LVXP51M8MrzaEQi6eBEGWpTSwckybqHU5s
* ETH: 0xba53cebd99157bf412a6bb91165e7dff29abd0a2
* ZEC: t1McmUhzdsauoXpiu2yCjNpnLKGGH225aAW
* DGE: D8cZwBsVp1hW4mjTCgspEKG5TpPZycTJBn
* BCH: 1FiXmPZ6eecHVaZbgdadAuzQLU9kqdSzVN
* ETC: 0xeb990a29d4f870b5fdbe331db90d9849ce3dae77
* WAX: 0xba53cebd99157bf412a6bb91165e7dff29abd0a2

---
[![UNLICENSE](noc.png)](UNLICENSE)
