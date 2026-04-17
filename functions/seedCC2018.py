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


albo_2018 = {
    "anno": 2018,
    "classifica": [
        {"squadra": "Effe 1", "posizione": 1, "logo": ""},
        {"squadra": "Zeta Nero", "posizione": 2, "logo": ""},
        {"squadra": "Alfa Rosso", "posizione": 3, "logo": ""},
        {"squadra": "Punta", "posizione": 4, "logo": ""},
        {"squadra": "Deneb", "posizione": 5, "logo": ""},
        {"squadra": "Grandangolo", "posizione": 6, "logo": ""},
        {"squadra": "Randa", "posizione": 7, "logo": ""},
        {"squadra": "Tiber A", "posizione": 8, "logo": ""},
        {"squadra": "Prato Boys", "posizione": 9, "logo": ""},
        {"squadra": "Alfa Blu", "posizione": 10, "logo": ""},
        {"squadra": "Starter", "posizione": 11, "logo": ""},
        {"squadra": "Zeta Orange", "posizione": 12, "logo": ""},
        {"squadra": "Clipper", "posizione": 13, "logo": ""},
        {"squadra": "Montegrifon", "posizione": 14, "logo": ""},
        {"squadra": "Junior", "posizione": 15, "logo": ""},
        {"squadra": "Gekopunta", "posizione": 16, "logo": ""},
        {"squadra": "Castello", "posizione": 17, "logo": ""},
        {"squadra": "Castelgiglio", "posizione": 18, "logo": ""},
        {"squadra": "Tiber B", "posizione": 19, "logo": ""},
        {"squadra": "Dolphin", "posizione": 20, "logo": ""},
    ],
    "marcatori": [
        {"nome": "Tancredi Di Martino", "gol": 16, "squadra": "Deneb"},
        {"nome": "Matteo Sambugaro", "gol": 15, "squadra": "Randa"},
        {"nome": "Riccardo Calabro'", "gol": 14, "squadra": "Alfa Rosso"},
        {"nome": "Fabio Battaini", "gol": 11, "squadra": "Zeta Nero"},
        {"nome": "Pietro Pederzini", "gol": 10, "squadra": "Deneb"},
        {"nome": "Matteo Di Molfetta", "gol": 9, "squadra": "Punta"},
        {"nome": "Tommaso Taccioli", "gol": 8, "squadra": "Zeta Orange"},
        {"nome": "Alessandro Garuti", "gol": 7, "squadra": "Effe 1"},
        {"nome": "Raffaele Piciocchi", "gol": 7, "squadra": "Grandangolo"},
        {"nome": "David Messina", "gol": 7, "squadra": "Starter"},
        {"nome": "Lorenzo Tondi", "gol": 6, "squadra": "Effe 1"},
    ],
}


def main():
    print(f"Caricamento Albo d'Oro CC {albo_2018['anno']} su Firebase...\n")

    resp = create_document("ccAlboDoro", albo_2018)

    if resp.status_code in (200, 201):
        doc_name = resp.json().get("name", "")
        doc_id = doc_name.split("/")[-1] if doc_name else "unknown"
        print(f"OK - CC {albo_2018['anno']} caricato (doc ID: {doc_id})")
        print(f"   - {len(albo_2018['classifica'])} squadre in classifica")
        print(f"   - {len(albo_2018['marcatori'])} marcatori")
    else:
        print(f"ERRORE nel caricare CC {albo_2018['anno']}: {resp.status_code}")
        print(resp.text)


if __name__ == "__main__":
    main()
