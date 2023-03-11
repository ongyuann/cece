force iPad-only IPA to install on iPhone
```
1. rename .ipa file to .zip
2. unzip
3. enter Payload folder
4. edit Info.plist (any text editor will do)
5. search for "UIDeviceFamily"
6. change value to 1
7. zip back the Payload folder
8. rename back to .ipa
```
