*** Settings ***
Library    ../../Library/Scripts/certificates.py

*** Variables ***


*** Test Cases ***
Access With P12 Certificate
    ${cert_file}    ${key_file}=    Extract Cert Key From P12    C://projects//city//tech//certificates//dev//dev.p12    a12345678
    Log To Console   cert:${cert_file}    key:${key_file}

