*** Settings ***
Resource    ../../Library/Robots/keywords.robot

*** Variables ***
${client_id}     LDvKQpNiCyr3NU8gEfPvC0gwOzpF0jkw
${client_secret}    X3E2XV9wotpndnfvkipX7sGOqY6CqKpy
${grant_type}    client_credentials 
${req_uri}    https://api.watsoncommerce.ibm.com/

*** Test Cases ***
Test To Get Bearer Token
    Initialize Token
    #Create Session   baseUri   https://api.watsoncommerce.ibm.com/      verify=false
    #Log To Console    block1--------------
    #&{params}=  Create Dictionary   client_id=${client_id}   client_secret=${client_secret}   grant_type=${grant_type}
    #Log To Console    block2--------------
    #&{headers}=  Create Dictionary   Content-Type=application/json
    #Log To Console    block3--------------
    #${resp}=  POST On Session  baseUri   /oauth/token    none    none    ${params}  ${headers}
    #${resp}=       POST On Session    baseUri    ${req_uri}  params=${params}
    #Log To Console    block4--------------
    #Log to Console  response:${resp.json()['access_token']}
    #Status Should Be  200            ${resp}
