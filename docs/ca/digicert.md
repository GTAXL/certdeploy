# DigiCert [PAID]
DigiCert is a major Certificate Authority from the United States offering paid TLS certificates for enterprise. They were founded in 2003 in Lehi, Utah. They are used by 90% of Fortune 500 companies. Their root certificate is from 2006 enabling excellent device compatibility. They own and operate four additional subsidiary Certificate Authorities, GeoTrust, RapidSSL, Thawte, and QuoVadis.
![Logo](https://www.digicert.com/content/dam/digicert/images/navigation/header/DigiCertLogo_MainNavigation.svg)
## CA Details
 - **Country:** United States
 - **Default Certificate Duration:** 365 days
 - **Staging Server Available:** No
 - **Requirements:** DigiCert CertCentral account, DV enabled on your account, EAB credentials.
 - **Restrictions:** Paid service, varies depending on product you enable for your ACME endpoint
 - [Website](https://obdr.it/2EfED)
## Pre-Registration Process
 This document is a work in progress. If it's still like this, open an issue bugging me to update it.
 ## Certificate Chain
 DigiCert is well trusted and relies on their own 2006 root.
 ### RSA Chain (when using RapidSSL Standard DV)
 | **Certificate**                             | **Sent** | **Key**  | **Signature** | **Validity**            | **Fingerprint**                                                  |
|---------------------------------------------|----------|----------|---------------|-------------------------|------------------------------------------------------------------|
| Leaf (Your Cert)                            |     Y    | RSA 2048 | SHA256withRSA | 365 days                | N/A                                                              |
| RapidSSL Global TLS RSA4096 SHA256 2022 CA1 |     Y    | RSA 4096 | SHA256withRSA | 2022-05-04 - 2031-11-09 | 92a5f515ad35d3a27c490edb135de7044b1e399d608ac1abe883fc82fb4b16be |
| DigiCert Global Root CA                     |     Y    | RSA 2048 | SHA1withRSA   | 2006-11-10 - 2031-11-10 | 4348a0e9444c78cb265e058d5e8944b4d84f9662bd26db257f8934a443c70161 |
## CAA Record
If you are using CAA records to lock down what Certificate Authorities are authorized for your domain, you will need to add DigiCert. Regardless of what subsidiary you use, whether it's RapidSSL or GeoTrust, they all share the same record. They use the following CAA record: `www.digicert.com`
