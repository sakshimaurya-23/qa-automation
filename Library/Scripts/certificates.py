# cert_api.py

import tempfile
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend


def extract_cert_key_from_p12(p12_path, p12_password):
    with open(p12_path, 'rb') as f:
        p12_data = f.read()

    private_key, cert, _ = pkcs12.load_key_and_certificates(
        p12_data,
        p12_password.encode(),
        backend=default_backend()
    )

    cert_pem = cert.public_bytes(encoding=serialization.Encoding.PEM)
    key_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )

    cert_file = tempfile.NamedTemporaryFile(delete=False)
    key_file = tempfile.NamedTemporaryFile(delete=False)

    cert_file.write(cert_pem)
    key_file.write(key_pem)

    cert_file.close()
    key_file.close()

    # Debug: Verify the values being returned
    print("Cert file path:", cert_file.name)
    print("Key file path:", key_file.name)

    # Ensure two separate values are returned
    return cert_file.name, key_file.name
