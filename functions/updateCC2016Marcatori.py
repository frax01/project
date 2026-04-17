import requests

PROJECT_ID = "club-60d94"
API_KEY = "AIzaSyAkmPm2DpVcfIg6uXMUuj7uLIxGd371qqM"
DOC_ID = "rC0ijnN7VdHQ9F5N8GzO"
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
    return {"stringValue": str(val)}


marcatori = [
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
]


def main():
    print(f"Aggiornamento marcatori CC 2016 (doc {DOC_ID})...")

    url = (
        f"{BASE_URL}/ccAlboDoro/{DOC_ID}"
        f"?updateMask.fieldPaths=marcatori&key={API_KEY}"
    )
    payload = {"fields": {"marcatori": to_firestore_value(marcatori)}}

    resp = requests.patch(url, json=payload)

    if resp.status_code in (200, 201):
        print("OK - marcatori aggiornati (nome poi cognome)")
    else:
        print(f"Errore: {resp.status_code}")
        print(resp.text)


if __name__ == "__main__":
    main()
