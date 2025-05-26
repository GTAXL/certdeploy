# Buypass AS
Buypass is a CA from Norway offering 180 day TLS certificates for free using ACME. They have been in business since 2001.
## CA Details

 - **Country:** Norway
 - **Default Certificate Duration:** 180 days
 - **Staging Server Available:** Yes
 - **Requirements:** E-mail address
 - [Website](https://www.buypass.com/)
## Register Buypass with certdeploy
Buypass requires you to provide an e-mail address to register an ACME account. They do not utilize EAB.
### Register Production Server

    certdeploy register buypass --email example@openbackdoor.com
 ### Register Staging Server (Testing)
 Using the Staging server is optional. If you are just setting up certdeploy for the first time and want to test out your configuration and deployment, you probably want to use Staging to verify everything is working right. Then once you are satisfied with the results switch back to the Production server.
 

    certdeploy register buypass-test --email example@openbackdoor.com
## Configuration to use Buypass AS
If you want Buypass AS to be your default CA for all certificates, update the **default_ca** entry in your **/etc/certdeploy.yml configuration file**.

**Production is buypass, Staging is buypass-test.**
### /etc/certdeploy.yml
Set Buypass as your default Certificate Authority for all certs. Please note, if you wish to use a different CA such as Let's Encrypt for a particular certificate, you can do so by adding the ca: configuration option to the domain in question, ex. ca: letsencrypt.

    certdeploy:
      default_ca: buypass
  Use for a specific certificate only, if your default is another CA provider.
  

    certdeploy:
      default_ca: google
      domains:
        - cn: www.example.com
          san: "example.com"
          ca: buypass
## Staging (Testing ACME Server)
When setting up certdeploy for the first time or debugging issues, you probably want to use the Staging server first. This is an alternative ACME server offered by Buypass for use with testing without worrying about hitting rate limits. The certificate chain offered on Staging is not publicly trusted and is a mock-up simply for testing your configuration and deployment systems.
## Additional Information
[GO SSL ACME Rate Limits](https://obdr.it/07pUV)
## Certificate Chain
Buypass AS is not cross-signed and relies on their own 2010 root.
### RSA Chain
| **Certificate**         | **Sent** | **Key**  | **Signature** | **Validity**            | **Fingerprint**                                                  |
|-------------------------|----------|----------|---------------|-------------------------|------------------------------------------------------------------|
| Leaf (Your Cert)        |     Y    | RSA 2048 | SHA256withRSA | 180 days                | N/A                                                              |
| Buypass Class 2 CA 5    |     Y    | RSA 4096 | SHA256withRSA | 2017-05-23 - 2027-05-23 | 3062918d9dd617925271bc7f8080b8a6a5d2185bbd880f7862fd4c043b194191 |
| Buypass Class 2 Root CA |     N    | RSA 4096 | SHA256withRSA | 2010-10-26 - 2040-10-26 | 9a114025197c5bb95d94e63d55cd43790847b646b23cdf11ada4a00eff15fb48 |
## CAA Record
If you are using CAA records to lock down what Certificate Authorities are authorized for your domain, you will need to add Buypass AS. They using the following CAA record: `buypass.com`
