# KuCoin-MoneyMoney

This is an inofficial extension for the [MoneyMoney macOS App](https://moneymoney-app.com/) that fetches all 
available balances from the KuCoin API and returns them as securities.
Prices are in EUR.

Requirements:
* MoneyMoney v2.3.4+

## Download Signed Extension

As long as this extension is not signed by MoneyMoney, you can get it from
* [the GitHub](https://github.com/CKohlert/MoneyMoney-KuCoin.com-Extension) page

Once downloaded, move `kucoin.lua` to your MoneyMoney Extensions folder which you can
open in MoneyMoney with the menu  
"Help" -> "Show Database in Finder".

You need to run MoneyMoney as Beta-Version to enable running unsigned extensions
which you can enable in the Preferences

## Account Setup

### KuCoin

1. Login in your KuCoin account
2. Goto your Account -> "API Management" (https://www.kucoin.com/account/api)
3. Create API (https://www.kucoin.com/account/api/create)  
Save the passphrase you invented! You wont see it elsewhere again!  
The only permission that the key needs is the default "General"  
![KuCoin screenshot create API](https://github.com/CKohlert/MoneyMoney-KuCoin.com-Extension/blob/master/img/kucoin%20create%20api.png)
4. Go through the "Security Verification" page
5. Note the key and the secure key that presents itself in the resulting dialog somewhere safe  
![KuCoin screenshot API create result](https://github.com/CKohlert/MoneyMoney-KuCoin.com-Extension/blob/master/img/kucoin%20api%20result.png)

### MoneyMoney

* Add a new account of type “KuCoin”
* In the "Username" field insert your key and the passphrase in the form KEY+PASSPHRASE
* The "Password" field needs the secret key
* Choose which account you want to monitor
Now you have an overview over your available balances on KuCoin

### Screenshot

![KuCoin screenshot overview](https://github.com/CKohlert/MoneyMoney-KuCoin.com-Extension/blob/master/img/kucoin%20overview.png)

## Known Issues and Limitations

* Always assumes EUR as base currency