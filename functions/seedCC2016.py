import requests
from datetime import datetime, timezone

PROJECT_ID = "club-60d94"
API_KEY = "AIzaSyAkmPm2DpVcfIg6uXMUuj7uLIxGd371qqM"
BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"


def to_firestore_value(val):
    """Convert a Python value to Firestore REST API value format."""
    if isinstance(val, str):
        return {"stringValue": val}
    elif isinstance(val, int):
        return {"integerValue": str(val)}
    elif isinstance(val, dict):
        fields = {k: to_firestore_value(v) for k, v in val.items()}
        return {"mapValue": {"fields": fields}}
    elif isinstance(val, list):
        return {"arrayValue": {"values": [to_firestore_value(v) for v in val]}}
    elif val is None:
        return {"nullValue": None}
    return {"stringValue": str(val)}


def create_document(collection, data):
    """Create a new document in the given collection."""
    fields = {}
    for key, value in data.items():
        if key == "timestamp":
            continue
        fields[key] = to_firestore_value(value)

    fields["timestamp"] = {
        "timestampValue": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    }

    url = f"{BASE_URL}/{collection}?key={API_KEY}"
    payload = {"fields": fields}
    return requests.post(url, json=payload)


albo_2016 = {
    "anno": 2016,
    "classifica": [
        {"squadra": "Tiber A", "posizione": 1, "logo": ""},
        {"squadra": "Giglio Azzurro", "posizione": 2, "logo": ""},
        {"squadra": "Junior", "posizione": 3, "logo": ""},
        {"squadra": "Starter", "posizione": 4, "logo": ""},
        {"squadra": "Zeta Nero", "posizione": 5, "logo": ""},
        {"squadra": "Randa", "posizione": 6, "logo": ""},
        {"squadra": "Zeta Rosso", "posizione": 7, "logo": ""},
        {"squadra": "Rampa", "posizione": 8, "logo": ""},
        {"squadra": "Elis", "posizione": 9, "logo": ""},
        {"squadra": "Deneb", "posizione": 10, "logo": ""},
        {"squadra": "Punta", "posizione": 11, "logo": ""},
        {"squadra": "Zeniber", "posizione": 12, "logo": ""},
        {"squadra": "Zeta Orange", "posizione": 13, "logo": ""},
        {"squadra": "Castello", "posizione": 14, "logo": ""},
        {"squadra": "Tiber B", "posizione": 15, "logo": ""},
        {"squadra": "Clipper", "posizione": 16, "logo": ""},
    ],
    "marcatori": [
        {"nome": "Giacomo Frati", "gol": 18, "squadra": "Giglio Azzurro"},
        {"nome": "Samuele Vitaterna", "gol": 14, "squadra": "Elis"},
        {"nome": "Pietro Biscardo", "gol": 12, "squadra": "Randa"},
        {"nome": "Riccardo Mincato", "gol": 11, "squadra": "Punta"},
        {"nome": "Alessandro Pomponi", "gol": 10, "squadra": "Tiber A"},
        {"nome": "Gualtiero Schiavi", "gol": 7, "squadra": "Zeta Orange"},
        {"nome": "Domenico Guerra", "gol": 7, "squadra": "Elis"},
        {"nome": "Tommaso Viani", "gol": 7, "squadra": "Zeta Rosso"},
        {"nome": "Aleg Montanelli", "gol": 7, "squadra": "Zeta Nero"},
        {"nome": "Marco Consogno", "gol": 7, "squadra": "Zeta Nero"},
        {"nome": "Francesco Cutore", "gol": 7, "squadra": "Starter"},
        {"nome": "Luca Serra", "gol": 6, "squadra": "Punta"},
    ],
}


def main():
    print("🏆 Caricamento Albo d'Oro CC 2016 su Firebase...\n")

    resp = create_document("ccAlboDoro", albo_2016)

    if resp.status_code in (200, 201):
        doc_name = resp.json().get("name", "")
        doc_id = doc_name.split("/")[-1] if doc_name else "unknown"
        print(f"✅ CC {albo_2016['anno']} caricato con successo! (doc ID: {doc_id})")
        print(f"   - {len(albo_2016['classifica'])} squadre in classifica")
        print(f"   - {len(albo_2016['marcatori'])} marcatori")
    else:
        print(f"❌ Errore nel caricare CC {albo_2016['anno']}: {resp.status_code}")
        print(f"   {resp.text}")


if __name__ == "__main__":
    main()
