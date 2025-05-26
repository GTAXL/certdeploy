# SSL.com
SSL .com is a Certificate Authority from the United States offering 104 day TLS certificates for free using ACME. They were founded in 2002 in Houston, Texas. If you use their free service, you can only have the apex domain and www per-certificate.
![Logo](https://ee2cc1f8.delivery.rocketcdn.me/wp-content/uploads/2020/04/ssl-logo-black.svg)
## CA Details

 - **Country:** United States
 - **Default Certificate Duration:** 104 days free, 396 paid
 - **Staging Server Available:** No
 - **Requirements:** SSL.com account, e-mail address and EAB credentials.
 - **Restrictions:** Only apex domain and www. per certificate for free tier. RSA and EC keys are on separate ACME endpoints and require separate account keys.
 - [Website](https://www.ssl.com/)
## Pre-Registration Process
To use the SSL .com ACME server with certdeploy you will first need to gather your EAB (External Account Binding) information. You will need to have a SSL .com account, which is free to register and use the ACME service.
### Register an SSL .com account on their website
You can head [here](https://secure.ssl.com/users/new) to register a new account. You may also head over to their website directly.
### Retrieve your External Account Binding
Once you've registered an account, sign in and on the Dashboard under the **developers and integration** section, click on **api credentials**.
![Go to api credentials to retrieve your EAB for ACME](https://pik.gtaxl.net/2025_05_26_074101.png)
Your Account/ACME Key is your --eab-kid, HMAC Key is your --eab-hmac-key. Click the copy button for each, as they are likely truncated. These are the credentials you will need to register certdeploy to SSL .com. Keep these somewhere safe and secure.
![API and ACME Credential Management for SSL.com](https://pik.gtaxl.net/2025_05_26_074435.png)
## Register SSL .com with certdeploy
You should now have what you need to register SSL .com with certdeploy. **SSL requires the following parameters, --email, --eab-kid, and --eab-hmac-key.**
### Register Production Server

    certdeploy register sslcom --email example@openbackdoor.com --eab-kid secret_key_here --eab-hmac-key another_secret_here
 Replace **--eab-kid** with the Account/ACME Key you got earlier, and **--eab-hmac-key** with the HMAC Key.
 ## Configuration to use SSL.com
 If you want SSL .com to be your default CA for all certificates, update the **default_ca** entry in your **/etc/certdeploy.yml** configuration file.
 Production is sslcom.
 ### /etc/certdeploy.yml
 Set SSL .com as your default Certificate Authority for all certs. Please note, if you wish to use a different CA such as Let's Encrypt for a particular certificate, you can by adding the ca: configuration option to the domain in question, ex. ca: letsencrypt.
 ```yaml
 certdeploy:
   default_ca: sslcom
```
Use for a specific certificate only, if your default is another CA provider.
```yaml
certdeploy:
  default_ca: google

  domains:
    - cn: www.example.com
      san: "example.com"
      ca: sslcom
```
## Additional Information
[Retrieve ACME Credentials](https://obdr.it/EZP45)
[Advantages of SSL.com ACME](https://obdr.it/szbsF)
## Certificate Chain
By default SSL .com is not cross-signed and relies on their own 2016 root.
| **Certificate**                          | **Sent** | **Key**  | **Signature** | **Validity**            | **Fingerprint**                                                  |
|------------------------------------------|----------|----------|---------------|-------------------------|------------------------------------------------------------------|
| Leaf (Your Cert)                         |     Y    | RSA 2048 | SHA256withRSA | 396 days                | N/A                                                              |
| SSL .com RSA SSL subCA                    |     Y    | RSA 4096 | SHA256withRSA | 2016-02-12 - 2031-02-12 | 527a60b02abf3a4a5519c4f62fbbd560e3034074eeec8b8799aa9368693fe36d |
| SSL .com Root Certification Authority RSA |     Y    | RSA 4096 | SHA256withRSA | 2016-02-12 - 2041-02-12 | 85666a562ee0be5ce925c1d8890a6f76a87ec16d4d7d5f29ea7419cf20123b69 |
## CAA Record
If you are using CAA records to lock down what Certificate Authorities are authorized for your domain, you will need to add SSL .com. They using the following CAA record: `ssl.com`
