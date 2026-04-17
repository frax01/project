"""
Aggiorna il documento ccVittorieClub/bonus su Firestore.

Il documento contiene una mappa `vittorie` (club -> numero di vittorie extra)
che viene sommata al conteggio calcolato automaticamente dagli albi d'oro.

Modifica la mappa BONUS qui sotto con i club e le vittorie da aggiungere,
poi lancia:
    python functions/updatePalmaresBonus.py
"""

import requests

PROJECT_ID = "club-60d94"
API_KEY = "AIzaSyAkmPm2DpVcfIg6uXMUuj7uLIxGd371qqM"
BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"


# ---- Modifica qui i bonus ----
# Chiave = "club" = prima parola del nome squadra (es. "Tiber" per Tiber A/B/...)
# Valore = vittorie extra da sommare a quelle gia' presenti negli albi d'oro.
BONUS = {
    # "Tiber": 2,
    # "Alfa": 3,
    # "Effe": 1,
}
# ------------------------------


def to_firestore_value(val):
    if isinstance(val, str):
        return {"stringValue": val}
    if isinstance(val, int):
        return {"integerValue": str(val)}
    if isinstance(val, dict):
        return {"mapValue": {"fields": {k: to_firestore_value(v) for k, v in val.items()}}}
    if isinstance(val, list):
        return {"arrayValue": {"values": [to_firestore_value(v) for v in val]}}
    return {"stringValue": str(val)}


def main():
    # PATCH del solo campo `vittorie`
    url = (
        f"{BASE_URL}/ccVittorieClub/bonus"
        f"?updateMask.fieldPaths=vittorie&key={API_KEY}"
    )
    payload = {"fields": {"vittorie": to_firestore_value(BONUS)}}
    resp = requests.patch(url, json=payload)

    if resp.status_code in (200, 201):
        if BONUS:
            print("OK - bonus palmares aggiornati:")
            for club, n in BONUS.items():
                print(f"  {club}: +{n}")
        else:
            print("OK - bonus svuotati (nessuna vittoria extra).")
    else:
        print(f"ERRORE: {resp.status_code}")
        print(resp.text)


if __name__ == "__main__":
    main()
