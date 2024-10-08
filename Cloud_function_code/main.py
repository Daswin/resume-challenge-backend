import functions_framework
import firebase_admin
from firebase_admin import credentials, firestore
keyPath = "my-terraform-project-14102-3970879e2b69.json"
cred = credentials.Certificate(keyPath)
firebase_admin.initialize_app(cred)
db = firestore.client()

import json


def get_current_number_visitors():
    current_number=0
    number_ref = db.collection('Visitors').document('my-doc-id')
    try:
        doc=number_ref.get()
        if doc.exists:
            return int(doc.to_dict().get('visitors', 0))
    except Exception as e:
        print(f"Error retrieving visitor number: {e}")
    return current_number


def save_number_visitors(current_number):
    # db=firestore.client()
    number_ref = db.collection('Visitors').document('my-doc-id')
    number_ref.set({'visitors':current_number})

@functions_framework.http
def current_number_visitors(request):
    current_number=get_current_number_visitors()
    new_number=str(current_number+1)
    save_number_visitors(new_number)
    data = {
        'visitors': new_number
    }
    headers = {
        'Access-Control-Allow-Origin': '*'
    }
    data = json.dumps(data)
    # return jsonify(data), 200, headers
    return data,200,headers
