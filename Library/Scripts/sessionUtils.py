from robot.api.deco import keyword
import requests
from RequestsLibrary import RequestsLibrary
from robot.libraries.BuiltIn import BuiltIn

@keyword("Create Secure Session With Client Cert")
def create_secure_session_with_client_cert(alias, base_url, cert_path, key_path, verify=True):
    session = requests.Session()
    session.cert = (cert_path, key_path)
    session.verify = verify
    session.url = base_url  # <-- Manually set required attribute

    # Register session with RequestsLibrary's internal cache
    req_lib = BuiltIn().get_library_instance('RequestsLibrary')
    req_lib._cache.register(session, alias)
