import requests
from datetime import datetime, timezone

PROJECT_ID = "club-60d94"
API_KEY = "AIzaSyAkmPm2DpVcfIg6uXMUuj7uLIxGd371qqM"
BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"


def to_firestore_value(val):
    if isinstance(val, str):
        return {"stringValue": val}
    elif isinstance(val, int):
        return {"integerValue": str(val)}
    elif isinstance(val, dict):
        return {"mapValue": {"fields": {k: to_firestore_value(v) for k, v in val.items()}}}
    elif isinstance(val, list):
        return {"arrayValue": {"values": [to_firestore_value(v) for v in val]}}
    elif val is None:
        return {"nullValue": None}
    return {"stringValue": str(val)}


def create_document(collection, data):
    fields = {}
    for key, value in data.items():
        if key == "timestamp":
            continue
        fields[key] = to_firestore_value(value)

    fields["timestamp"] = {
        "timestampValue": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    }

    url = f"{BASE_URL}/{collection}?key={API_KEY}"
    return requests.post(url, json={"fields": fields})


albo_2019 = {
    "anno": 2019,
    "classifica": [
        {"squadra": "CAT", "posizione": 1, "logo": ""},
        {"squadra": "Deneb", "posizione": 2, "logo": ""},
        {"squadra": "Grandangolo", "posizione": 3, "logo": ""},
        {"squadra": "Tiber A", "posizione": 4, "logo": ""},
        {"squadra": "Zeta Orange", "posizione": 5, "logo": ""},
        {"squadra": "Zeta Rosso", "posizione": 6, "logo": ""},
        {"squadra": "Starter", "posizione": 7, "logo": ""},
        {"squadra": "Monte Grifone", "posizione": 8, "logo": ""},
        {"squadra": "Junior", "posizione": 9, "logo": ""},
        {"squadra": "Castello", "posizione": 10, "logo": ""},
        {"squadra": "Prato Boys", "posizione": 11, "logo": ""},
        {"squadra": "Tiber B", "posizione": 12, "logo": ""},
    ],
    "marcatori": [],
}


def main():
    print(f"Caricamento Albo d'Oro CC {albo_2019['anno']} su Firebase...\n")

    resp = create_document("ccAlboDoro", albo_2019)

    if resp.status_code in (200, 201):
        doc_name = resp.json().get("name", "")
        doc_id = doc_name.split("/")[-1] if doc_name else "unknown"
        print(f"OK - CC {albo_2019['anno']} caricato (doc ID: {doc_id})")
        print(f"   - {len(albo_2019['classifica'])} squadre in classifica")
        print(f"   - {len(albo_2019['marcatori'])} marcatori")
    else:
        print(f"ERRORE nel caricare CC {albo_2019['anno']}: {resp.status_code}")
        print(resp.text)


if __name__ == "__main__":
    main()
