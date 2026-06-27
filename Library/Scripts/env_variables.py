def get_environment(env_name):
    """Return environment config dict for the given env name (DEV / QA / FyreSan)."""
    return ENVIRONMENTS.get(env_name, {})


ENVIRONMENTS = {
    "DEV": {
        "URL": "https://cityf-dev-1.oms.supply-chain.ibm.com/",
        "USERNAME": "admin",
        "PASSWORD": "password",
        "CERTlOCATION": "/Users/sakshimaurya/Testing_v2.0/owner=jeevitha.p12",
        # "CERTlOCATION": "C://projects//city//tech//certificates//dev//dev.p12",
        "CERTPASSWORD": "password",
        # "CERTPASSWORD": "a12345678"
    },
    "FyreSan": {
        "URL": "http://9.30.161.162:9080",
        "USERNAME": "admin",
        "PASSWORD": "password"
    },
    "QA": {
        "URL": "https://cityf-qa-1.oms.supply-chain.ibm.com/",
        "USERNAME": "admin",
        "PASSWORD": "password",
        "CERTlOCATION": "C://CITY//AppManager_26.2//owner=jeevitha-qa.p12",
        # "CERTlOCATION": "C://CITY//AppManager_25.2//qa.p12",
        "CERTPASSWORD": "password"
    }
}
