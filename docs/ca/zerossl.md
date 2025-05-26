# ZeroSSL [not recommended]
ZeroSSL is a Certificate Authority from Austria offering 90 day TLS certificates for free using ACME. They were recently acquired in 2024 by HID Global from the United States. It appears they are still running ZeroSSL operations from Austria however. They were founded in 2016. Their root certificate is cross-signed with Sectigo enabling world-class device compatibility.
## CA Details

 - **Country:** Austria, parent company United States
 - **Default Certificate Duration:** 90 days
 - **Staging Server Available:** No
 - **Requirements:** E-mail address, or EAB or both.
 - [Website](https://obdr.it/Wfh0P)
## Register ZeroSSL with certdeploy
ZeroSSL requires you to either provide your e-mail address, or EAB credentials to register an ACME account. We recommend just the e-mail method, unless you plan on using their paid version. If you have a ZeroSSL account and or utilizing their paid service, login to their website to obtain your EAB credentials. See [here](https://obdr.it/s8CLd) for more information.
### Register Production Server
E-mail method (**recommended**, unless paid version)

    certdeploy register zerossl --email example@openbackdoor.com
 External Account Binding Method
 

    certdeploy register zerossl --eab-kid secret_key_here --eab-hmac-key another_secret_here
> [!TIP]
> ZeroSSL is automatically registered when you use the `certdeploy register all --email example@openbackdoor.com` command.
## Configuration to use ZeroSSL
If you want ZeroSSL to be your default CA for all certificates, update the **default_ca** entry in your **/etc/certdeploy.yml** configuration file.

**Production is zerossl.**
### /etc/certdeploy.yml
Set ZeroSSL as your default Certificate Authority for all certs. Please note, if you wish to use a different CA such as Let's Encrypt for a particular certificate, you can by adding the ca: configuration option to the domain in question, ex. ca: letsencrypt.

    certdeploy:
      default_ca: zerossl
  Use for a specific certificate only, if your default is another CA provider.
  

    certdeploy:
      default_ca: letsencrypt
      domains:
        - cn: www.example.com
          san: "example.com"
          ca: zerossl
  ## Additional Information
  [Generate ACME EAB Credentials via API](https://obdr.it/EzPrD)
  [ACME Documentation](https://obdr.it/Zd0WR)
  [ZeroSSL vs Let's Encrypt](https://obdr.it/O1JRJ)
  [ZeroSSL Status](https://obdr.it/SnMM5)
## Certificate Chain
ZeroSSL is cross-signed with Sectigo's "AAA Certificate Services" root certificate from 2004, ensuring maximum device compatibility.
### RSA Chain
| **Certificate**                       | **Sent** | **Key**  | **Signature** | **Validity**            | **Fingerprint**                                                  |
|---------------------------------------|----------|----------|---------------|-------------------------|------------------------------------------------------------------|
| Leaf (Your Cert)                      |     Y    | RSA 2048 | SHA384withRSA | 90 days                 | N/A                                                              |
| ZeroSSL RSA Domain Secure Site CA     |     Y    | RSA 4096 | SHA384withRSA | 2020-01-30 - 2030-01-29 | 21acc1dbd6944f9ac18c782cb5c328d6c2821c6b63731fa3b8987f5625de8a0d |
| USERTrust RSA Certification Authority |     Y    | RSA 4096 | SHA384withRSA | 2019-03-12 - 2028-12-31 | 68b9c761219a5b1f0131784474665db61bbdb109e00f05ca9f74244ee5f5f52b |
| AAA Certificate Services              |     N    | RSA 2048 | SHA1withRSA   | 2004-01-01 - 2028-12-31 | d7a7a0fb5d7e2731d771e9484ebcdef71d5f0c3e0a2948782bc83ee0ea699ef4 |
## CAA Record
If you are using CAA records to lock down what Certificate Authorities are authorized for your domain, you will need to add ZeroSSL. They use the following CAA record, `sectigo.com`
## Reliability Issues
We currently don't recommend ZeroSSL due to reliability issues. Their ACME server tends to time out or throw 500 errors very often. Our ACME client dehydrate will try the request again but can often sometimes fail. We would otherwise strongly recommend them due to their cross-sign and laxed rate limits.
