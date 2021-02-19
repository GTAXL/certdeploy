# Cloudflare DNS hook for certdeploy (dehydrated)
Use this hook if you are using Cloudflare's DNS service for your domain names.
## Configuration
* Generate API token, more info [here](https://support.cloudflare.com/hc/en-us/articles/200167836-Managing-API-Tokens-and-Keys)
  * Login to [Cloudflare Dashboard](https://dash.cloudflare.com/login)
  * In the upper right-hand corner click on the Avatar dropdown menu and click on **My Profile**
  * Click on the **API Tokens** tab and click **Create Token**
  * Under **API token templates** choose **Edit zone DNS**
  * Next to **Token name: Edit zone DNS** click the pencil icon and change the Token name to **certdeploy**
  * Under **Zone Resources** you can specify if you want the API token to apply to a specific domain aka zone or all domains, in most cases you'll want to change this dropdown to **All zones**![alt text](https://pik.gtaxl.net/19_02_21_14_41_09.png)
  * If your main certdeploy server has a static IP, then under **IP Address Filtering** set the IP address, otherwise leave it empty.
  * Click **Continue to summary** then click **Create Token**
  * Copy your token and paste it into the **api_token** variable of `hook.sh`![alt text](https://pik.gtaxl.net/19_02_21_14_46_34.png)
  * Run the **Test this token** curl command to activate the token. 
   Example: `curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer tokenhere" -H "Content-Type:application/json"`
  * Finished!