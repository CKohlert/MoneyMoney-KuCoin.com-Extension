-- Inofficial KuCoin Extension (www.kucoin.com) for MoneyMoney
-- Fetches balances from KuCoin API and returns them as securities
--
-- older MoneyMoney Dialog:
-- Username: KuCoin API Key + KuCoin API Passphrase (example: "KKKKK+PPPPP")
-- Password: KuCoin API Secret
--
-- newer MoneyMoney Dialog:
-- there are explicit named input fields for API Key, Passphrase and Secret
--
-- MIT License
--
-- Copyright (c) 2023 Christopher Kohlert
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

WebBanking {
    version     = 1.0,
    url         = "https://openapi-v2.kucoin.com",
    description = "Fetch balances from KuCoin API and list them as securities",
    services    = { "KuCoin Account" },
}

local apiKey
local apiSecret
local apiPassphrase
local balances

local currency = "EUR"

-- MoneyMoney Web Scraping Interface:
-- doc: https://moneymoney-app.com/api/webbanking/

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "KuCoin Account"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  if username2 and username2 ~= "" then -- support for a newer version of MoneyMoney
    -- Key, Passphrase and Secret are in username, username2 and password
    apiKey = username
    apiPassphrase = username2
    apiSecret = password
  else
    -- Key + Passphrase is in username
    apiKey, apiPassphrase = string.match(username, "(%w+)%+(%g+)")
    apiSecret = password
  end
  if not apiSecret or not apiKey or not apiPassphrase then return LoginFailed end
end

function ListAccounts (knownAccounts)
  MM.printStatus("Abfrage der KuKoin Konten")
  local raccounts, status = queryPrivate("accounts")
  if not KuCoinErrorSuccess(status) then
    return "Fehler bei der Kontenabfrage: " .. KuCoinErrorToText(status)
  end

  local accounttypes = {} -- available account types
  for _, account in pairs(raccounts['data']) do
    accounttypes[account['type']] = true
  end

  local accounts = {}
  for atype, _ in pairs(accounttypes) do
    accounts[#accounts+1] = {
      name = "KuCoin " .. atype, -- editierbarer Kontoname in der Auswahl und in der Hauptliste
      accountNumber = atype, -- identifier for the account SubName in the Account-View / und neben der account auswahl
      currency = currency,
      portfolio = true,
      type = "AccountTypePortfolio"
    }
  end

  return accounts
end

function RefreshAccount (account, since)
  MM.printStatus("Abfrage von KuKoin - " .. account.accountNumber)
  local balancesr, status = queryPrivate("accounts", "type=" .. account.accountNumber)
  if not KuCoinErrorSuccess(status) then
    return "Fehler beim Versuch den Kontostand zu laden: " .. KuCoinErrorToText(status)
  end

  balances = balancesr['data']

  local eurPrices = querySymbolsToEUR(compileAssetsString())

  local s = {}
  for _, value in pairs(balances) do
    if tonumber(value["balance"]) > 0 then
      -- doc: https://moneymoney-app.com/api/webbanking/#securities
      s[#s+1] = {
        name = value["currency"],
        -- market = "KuCoin", -- Börse, steht optional bei den einzelnen Einträgen
        currency = nil, -- Nominalbetrag
        quantity = value["available"],
        price = eurPrices[value["currency"]],
      }
    end
  end

  return {securities = s}
end

function EndSession ()
end

-- Internal:

function KuCoinErrorSuccess(errorp)
  local error = tonumber(errorp)
  if error == 200 or error == 200000 then return true end
  return false
end

-- doc: https://docs.kucoin.com/#rest-api-2
function KuCoinErrorToText(errorp)
  local error = tonumber(errorp)
  if     error == 200 then return "OK"
  elseif error == 400 then return "Falsch formatierte Anfrage (Bad Request)"
  elseif error == 401 then return "Unauthorisiert (Invalid API Key)"
  elseif error == 403 then return "Verboten oder zu viele Anfragen"
  elseif error == 404 then return "Nicht gefunden (The specified resource could not be found)"
  elseif error == 405 then return "Abfragemethode nicht erlaubt"
  elseif error == 415 then return "Nicht unterstützter Media-Type (use: application/json)"
  elseif error == 500 then return "Interner Server Fehler (Try again later)"
  elseif error == 503 then return "Service nicht erreichbar (Try again later)"
  elseif error == 200000 then return "OK"
  elseif error == 200001 then return "Order creation for this pair suspended"
  elseif error == 200002 then return "Order cancel for this pair suspended"
  elseif error == 200003 then return "Number of orders breached the limit"
  elseif error == 200009 then return "Please complete the KYC verification before you trade XX"
  elseif error == 200004 then return "Balance insufficient"
  elseif error == 260210 then return "Withdraw disabled -- Currency/Chain withdraw is closed, or user is frozen to withdraw"
  elseif error == 400001 then return "Fehlender Header (Any of KC-API-KEY, KC-API-SIGN, KC-API-TIMESTAMP, KC-API-PASSPHRASE is missing in your request header)"
  elseif error == 400002 then return "Header: KC-API-TIMESTAMP Invalid"
  elseif error == 400003 then return "Header: KC-API-KEY not exists (Falsche Zugangsdaten?)"
  elseif error == 400004 then return "Header: KC-API-PASSPHRASE error (Falsche Zugangsdaten?)"
  elseif error == 400005 then return "Signature error (Zugangsdaten falsch?)"
  elseif error == 400006 then return "The requested ip address is not in the api whitelist"
  elseif error == 400007 then return "Access Denied"
  elseif error == 404000 then return "Url Not Found"
  elseif error == 400100 then return "Parameter Error"
  elseif error == 400200 then return "Forbidden to place an order"
  elseif error == 400500 then return "Your located country/region is currently not supported for the trading of this token"
  elseif error == 400600 then return "The trading pair has not yet started trading"
  elseif error == 400700 then return "Transaction restricted, there's a risk problem in your account"
  elseif error == 400800 then return "Leverage order failed"
  elseif error == 411100 then return "User are frozen"
  elseif error == 415000 then return "Unsupported Media Type -- The Content-Type of the request header needs to be set to application/json"
  elseif error == 500000 then return "Internal Server Error"
  elseif error == 900001 then return "Symbol does not exist"
  else return "Unbekannter Fehler (" .. error .. ")"
  end
end

function compileAssetsString()
  local assets = ""
  for key, value in pairs(balances) do
    if tonumber(value["balance"]) > 0 then
      assets = assets .. value["currency"] .. ','
    end
  end
  return assets
end

-- KuCoin Get Fiat Price doc: https://docs.kucoin.com/#get-fiat-price

function querySymbolsToEUR(symbolsstring)
  return queryPublic("prices", "base=EUR&currencies=" .. symbolsstring)["data"]
end

-- External Communication:

-- kucoin request api doc: https://docs.kucoin.com/#request

function queryPublic(method, parameters, apiVersion)
  local apiVersion = apiVersion or "v1"
  local endpoint = string.format("/api/%s/%s", apiVersion, method)
  local endpoint = endpoint .. (parameters and "?" .. parameters or "")
  local kucoinerror = -1

  local headers = {}
  -- headers["User-Agent"] = MM.productName .. "/" .. MM.productVersion
  headers["Accept"] = "application/json"
  headers["Content-Type"] = "application/json"

  connection = Connection()
  content = connection:request("GET", url .. endpoint, nil, nil, headers)

  json = JSON(content)
  jsond = json:dictionary()
  kucoinerror = jsond['code'] or kucoinerror

  return jsond, kucoinerror
end

function queryPrivate(method, parameters, apiVersion)
  local apiVersion = apiVersion or "v1"
  local endpoint = string.format("/api/%s/%s", apiVersion, method)
  local endpoint = endpoint .. (parameters and "?" .. parameters or "")
  local timestamp = string.format("%d", MM.time() * 1000)
  local signStr = timestamp .. "GET" .. endpoint
  local endpointSign = MM.hmac256(apiSecret, signStr)
  local passphraseSign = MM.hmac256(apiSecret, apiPassphrase)
  local kucoinerror = -1

  local headers = {}
  -- headers["User-Agent"] = MM.productName .. "/" .. MM.productVersion
  headers["Accept"] = "application/json"
  headers["Content-Type"] = "application/json"
  headers["KC-API-KEY"] = apiKey
  headers["KC-API-SIGN"] = MM.base64(endpointSign)
  headers["KC-API-TIMESTAMP"] = timestamp
  headers["KC-API-PASSPHRASE"] = MM.base64(passphraseSign)
  headers["KC-API-KEY-VERSION"] = "2"

  connection = Connection()
  content = connection:request("GET", url .. endpoint, nil, nil, headers)
  if not content then return "", kucoinerror end

  json = JSON(content)
  jsond = json:dictionary()
  kucoinerror = jsond['code'] or kucoinerror

  return jsond, kucoinerror
end
