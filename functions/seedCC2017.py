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


albo_2017 = {
    "anno": 2017,
    "classifica": [
        {"squadra": "Zeta Nero", "posizione": 1, "logo": ""},
        {"squadra": "Starter", "posizione": 2, "logo": ""},
        {"squadra": "Elis", "posizione": 3, "logo": ""},
        {"squadra": "Punta Tigers", "posizione": 4, "logo": ""},
        {"squadra": "Junior", "posizione": 5, "logo": ""},
        {"squadra": "Deneb", "posizione": 6, "logo": ""},
        {"squadra": "Randa", "posizione": 7, "logo": ""},
        {"squadra": "Tiber B", "posizione": 8, "logo": ""},
        {"squadra": "Alfa", "posizione": 9, "logo": ""},
        {"squadra": "Zeta Rosso", "posizione": 10, "logo": ""},
        {"squadra": "Effe 1", "posizione": 11, "logo": ""},
        {"squadra": "Zeta Orange", "posizione": 12, "logo": ""},
        {"squadra": "Tiber A", "posizione": 13, "logo": ""},
        {"squadra": "Tuscania", "posizione": 14, "logo": ""},
        {"squadra": "A19", "posizione": 15, "logo": ""},
        {"squadra": "Clipper", "posizione": 16, "logo": ""},
        {"squadra": "Catrina", "posizione": 17, "logo": ""},
        {"squadra": "Geko", "posizione": 18, "logo": ""},
        {"squadra": "Punta Lions", "posizione": 19, "logo": ""},
        {"squadra": "Dolphin", "posizione": 20, "logo": ""},
    ],
    "marcatori": [
        {"nome": "Domenico Guerra", "gol": 23, "squadra": "Elis"},
        {"nome": "Carlo Alberto Lonardi", "gol": 15, "squadra": "Punta"},
        {"nome": "Alessandro Falleni", "gol": 15, "squadra": "Zeta Nero"},
        {"nome": "Andrea Bonomi", "gol": 8, "squadra": "Randa"},
        {"nome": "Saverio Luconi", "gol": 8, "squadra": "Tiber A"},
        {"nome": "Francesco Cutore", "gol": 8, "squadra": "Starter"},
        {"nome": "Andrea Canali", "gol": 7, "squadra": "Zeta Nero"},
        {"nome": "Emanuele Albert", "gol": 7, "squadra": "Punta"},
        {"nome": "Fabio Battaini", "gol": 6, "squadra": "Zeta Nero"},
        {"nome": "Pietro Biscardo", "gol": 6, "squadra": "Randa"},
        {"nome": "Filippo Leccese", "gol": 6, "squadra": "Zeta Nero"},
        {"nome": "Riccardo Raccone", "gol": 6, "squadra": "Junior"},
    ],
}


def main():
    print(f"Caricamento Albo d'Oro CC {albo_2017['anno']} su Firebase...\n")

    resp = create_document("ccAlboDoro", albo_2017)

    if resp.status_code in (200, 201):
        doc_name = resp.json().get("name", "")
        doc_id = doc_name.split("/")[-1] if doc_name else "unknown"
        print(f"OK - CC {albo_2017['anno']} caricato (doc ID: {doc_id})")
        print(f"   - {len(albo_2017['classifica'])} squadre in classifica")
        print(f"   - {len(albo_2017['marcatori'])} marcatori")
    else:
        print(f"ERRORE nel caricare CC {albo_2017['anno']}: {resp.status_code}")
        print(resp.text)


if __name__ == "__main__":
    main()
