import requests
from requests.auth import HTTPBasicAuth

def get_bearer_token(token_url,client_id,client_secret):
    # Replace with your actual values
    # token_url = "https://api.watsoncommerce.ibm.com/inventory/us-1b8d5331/v1/oauth2/token"  # OAuth2 token endpoint
    # client_id = "LDvKQpNiCyr3NU8gEfPvC0gwOzpF0jkw"
    # client_secret = "X3E2XV9wotpndnfvkipX7sGOqY6CqKpy"

    # Set the parameters for the request
    data = {
        'grant_type': 'client_credentials'
    }

    # Make the request
    response = requests.post(
        token_url,
        data=data,
        auth=HTTPBasicAuth(client_id, client_secret)
    )

    # Handle the response
    if response.status_code == 200:
        token_data = response.json()
        access_token = token_data['access_token']
        print("Bearer Token:", access_token)
        return access_token
    else:
        print("Failed to retrieve token:", response.status_code, response.text)