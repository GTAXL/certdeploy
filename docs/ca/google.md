# Google Trust Services [recommended]

Google runs a Certificate Authority offering 90 day TLS certificates for free using ACME. Their root certificate is cross-signed with GlobalSign enabling world-class device compatibility. The certificate chain is the same as google.com and youtube.com We recommend this CA over others for the best device compatibility and reliability.


![Logo](https://status.pki.goog/images/trust-logo.svg)


## Pre-Registration Process
To use the GTS (Google Trust Services) ACME server with certdeploy you will first need to gather your EAB (External Account Binding) information. You will need to have a Google account and access to Google Cloud. The PKI ACME service is tied into Google Cloud. The ACME service is completely free to use and setup. You will need to un-fortunately install a Google Cloud program to run some commands to generate your EAB credentials to use the ACME server. Once you do this, you should never have to interact with this program or Google Cloud again.
### Download the Google Cloud CLI program
This program gives you command line access to your Google Cloud account to provision and configure various services. It is available for Windows, macOS, Debian, Ubuntu, Red Hat, Fedora, etc.

**Link to gcloud CLI program:** [Click Here](https://obdr.it/OeBZj)

Direct Link for Windows: [Click Here](https://obdr.it/m3MJY) *Might be dead later, try the above link or poke me to update it.*
### Install the Google Cloud CLI program
In this example we are using Windows.

![Installation of Google Cloud CLI on Windows 10](https://pik.gtaxl.net/2025_05_25_155405.png)

Make sure to check the "**Run 'gcloud init' to configure the Google Cloud CLI**" option
![Check mark options to complete the Google Cloud CLI setup on Windows 10](https://pik.gtaxl.net/2025_05_25_155552.png)
### Sign in and configure the Google Cloud CLI program
Sign into your Google account (same as Gmail). **You will get a command line prompt asking if you want to sign in, type y and press enter.** This will open a browser window to complete the authentication.
![Sign into Google Account for Google Cloud CLI program on Windows 10](https://pik.gtaxl.net/2025_05_25_155804.png)
### Create a new Google Cloud Project strictly for use with certdeploy
For "Pick cloud project to use" type the number that corresponds with "**Create a new project**".
![Create a new project](https://pik.gtaxl.net/2025_05_25_160439.png)

Create a new project ID. This is just a name of your new Google Cloud "project". You can name it anything but we recommend just putting certdeploy so you will know later if you ever go into your Google Cloud account. Type certdeploy and hit enter. In my particular example I used obd-pki instead.

![Enter a Project ID](https://pik.gtaxl.net/2025_05_25_163308.png)
### Enable ACME service for your Google Cloud Project
Enable the Public CA API for your newly created project.

    gcloud services enable publicca.googleapis.com
### Retrieve your External Account Binding
Request your EAB key ID and HMAC

    gcloud publicca external-account-keys create
This will output two parameters you will need to keep for later to register using certdeploy. These are your External Account Binding credentials. They tie the registered ACME account through your client to your Google Cloud account.
**The b64MacKey is your EAB HMAC Key, the keyId is your EAB KID. The certdeploy register arguments to specify these parameters are --eab-hmac-key and --eab-kid.**
Copy and paste and save this output somewhere safe. These are to be kept private and you can delete it once you've fully registered certdeploy to GTS. If you're having trouble copy and pasting from the Google CLI console window, try right clicking (hit Mark if applicable), select the output, the left click to copy.
## Staging (Testing ACME Server)
When setting up certdeploy for the first time or debugging issues, you probably want to use the Staging server first. This is an alternative ACME server offered by Google for use with testing without worrying about hitting rate limits. The certificate chain offered on Staging is not publicly trusted and is a mock-up simply for testing your configuration and deployment systems.

**Note:** It appears from the documentation that you can't currently use both Staging and Production ACME endpoints at the same time. You can only have one enable to your Google Cloud project at any given time.

> [!WARNING]
> Using the Staging server instead of Production will result in Invalid Certificate errors in your end-user's browsers and or application. This is meant for testing your configuration, then once you are satisfied everything is being installed and deployed correctly you switch back to Production immediately. If you followed the aforementioned instructions on this documentation, you have already enabled Production and don't have to continue with this section unless you want to use Staging.** </span>
### Switch your project to use the Staging ACME server

    gcloud config set api_endpoint_overrides/publicca https://preprod-publicca.googleapis.com/

### Retrieve your External Account Binding

    gcloud publicca external-account-keys create
   This is the same process as above in regards to saving this information and output format. If you've generated production EAB earlier, keep them separate so you don't confuse the two.
## Register Google Trust Services with certdeploy
You should now have what you need to register the GTS Certificate Authority with certdeploy. **GTS requires the following parameters, --email, --eab-kid, and --eab-hmac-key.** For your e-mail address we recommend you use the @gmail.com e-mail address tied to your Google Cloud account.
### Register Production Server (you probably want this)

    certdeploy register google --email your@gmail.com --eab-kid secret_key_here --eab-hmac-key another_secret_here
 Replace your&#64;gmail.com with your e-mail address. Replace **--eab-kid with the keyId** you got earlier, and **--eab-hmac-key with the b64MacKey**.
### Register Staging Server (Testing)
This is optional as stated above. If you plan on using it first to test things out, don't do the production server instructions. Remember, you can only use one at any given time.

    certdeploy register google-test --email your@gmail.com --eab-kid secrets_go_here --eab-hmac-key more_secrets_here
## Configuration to use Google Trust Services
If you want Google Trust Services to be your default CA for all certs update the default_ca entry in your /etc/certdeploy.yml configuration file.

**Production is google, Staging is google-test.**
### /etc/certdeploy.yml
Set GTS as your default Certificate Authority for all certs. Please note, if you wish to use a different CA such as Let's Encrypt for a particular certificate, you can by adding the ca: configuration option to the domain in question, ex. ca: letsencrypt.

    certdeploy:
      default_ca: google
Use for a specific certificate only, if your default is another CA provider.

    certdeploy:
      default_ca: letsencrypt
      domains:
        - cn: www.example.com
          san: "example.com"
          ca: google
## Reverting from Staging back to Production
If you are currently using Staging and want to go back to Production, open up the Google Cloud CLI program and run:

    gcloud config unset api_endpoint_overrides/publicca
Note: You may have to create a new EAB credentials. If you haven't previously, register certdeploy to the production server. Update your /etc/certdeploy.yml configuration file from google-test to google for the default_ca and or ca: entries.
## Additional Information
[Public CA Overview](https://obdr.it/eg19W)

[Request a certificate using Public CA and an ACME client](https://obdr.it/s3PAm)

[Quotas, rates and limits](https://obdr.it/7aqy9)

[Google Trust Services Homepage](https://obdr.it/teFw3)

[GTS Status](https://obdr.it/peWKc)
## Certificate Chain
Google Trust Services is cross-signed with a GlobalSign root certificate from 1998, ensuring maximum device compatibility.
### RSA Chain
| **Certificate**    | **Sent** | **Key**  | **Signature** | **Validity**            | **Fingerprint**                                                  |
|--------------------|----------|----------|---------------|-------------------------|------------------------------------------------------------------|
| Leaf (Your Cert)   |     Y    | RSA 2048 | SHA256withRSA | 90 days                 | N/A                                                              |
| WR1                |     Y    | RSA 2048 | SHA256withRSA | 2023-12-13 - 2029-02-20 | b10b6f00e609509e8700f6d34687a2bfce38ea05a8fdf1cdc40c3a2a0d0d0e45 |
| GTS Root R1        |     Y    | RSA 4096 | SHA256withRSA | 2020-06-19 - 2028-01-28 | 3ee0278df71fa3c125c4cd487f01d774694e6fc57e0cd94c24efd769133918e5 |
| GlobalSign Root CA |     N    | RSA 2048 | SHA1withRSA   | 1998-09-01 - 2028-01-28 | ebd41040e4bb3ec742c9e381d31ef2a41a48b6685c96e7cef3c1df6cd4331c99 |

