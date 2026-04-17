"""
Propaga i loghi dal documento CC 2025 agli altri anni dell'Albo d'Oro.

Regole per ogni squadra in un anno != 2025:
  1. Se una squadra con lo STESSO nome esiste nel 2025 -> usa quel logo
  2. Altrimenti, se esiste nel 2025 una squadra dello STESSO club (prima parola
     del nome, es. "Zeta", "Tiber", "Elis"), usa il logo della squadra di quel
     club arrivata piu' in alto nella classifica 2025
  3. Altrimenti lascia ""

Uso:
    python functions/updateAlboDoroLoghi.py           # solo anteprima (dry-run)
    python functions/updateAlboDoroLoghi.py --apply   # scrive su Firestore
"""

import sys
import requests

PROJECT_ID = "club-60d94"
API_KEY = "AIzaSyAkmPm2DpVcfIg6uXMUuj7uLIxGd371qqM"
BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"


# ---------- Firestore value <-> Python ----------

def to_firestore_value(val):
    if isinstance(val, bool):
        return {"booleanValue": val}
    if isinstance(val, str):
        return {"stringValue": val}
    if isinstance(val, int):
        return {"integerValue": str(val)}
    if isinstance(val, float):
        return {"doubleValue": val}
    if isinstance(val, dict):
        return {"mapValue": {"fields": {k: to_firestore_value(v) for k, v in val.items()}}}
    if isinstance(val, list):
        return {"arrayValue": {"values": [to_firestore_value(v) for v in val]}}
    if val is None:
        return {"nullValue": None}
    return {"stringValue": str(val)}


def from_firestore_value(v):
    if "stringValue" in v:
        return v["stringValue"]
    if "integerValue" in v:
        return int(v["integerValue"])
    if "doubleValue" in v:
        return v["doubleValue"]
    if "booleanValue" in v:
        return v["booleanValue"]
    if "nullValue" in v:
        return None
    if "mapValue" in v:
        fields = v["mapValue"].get("fields", {})
        return {k: from_firestore_value(val) for k, val in fields.items()}
    if "arrayValue" in v:
        values = v["arrayValue"].get("values", [])
        return [from_firestore_value(val) for val in values]
    if "timestampValue" in v:
        return v["timestampValue"]
    return None


def from_firestore_doc(doc):
    fields = doc.get("fields", {})
    return {k: from_firestore_value(v) for k, v in fields.items()}


# ---------- Firestore REST ----------

def list_documents(collection):
    url = f"{BASE_URL}/{collection}?key={API_KEY}&pageSize=300"
    resp = requests.get(url)
    resp.raise_for_status()
    data = resp.json()
    return data.get("documents", [])


def patch_classifica(doc_name, classifica):
    """PATCH only the 'classifica' field of the document with the given full name."""
    url = (
        f"https://firestore.googleapis.com/v1/{doc_name}"
        f"?updateMask.fieldPaths=classifica&key={API_KEY}"
    )
    payload = {"fields": {"classifica": to_firestore_value(classifica)}}
    return requests.patch(url, json=payload)


# ---------- Logica ----------

# Alias: nomi squadra/club che vogliamo considerare come appartenenti allo
# stesso club di un'altra denominazione (normalizzazione storica).
CLUB_ALIASES = {
    "Gekonda": "Geko",
}


def club_of(name):
    """Restituisce la prima parola del nome squadra (il 'club'), applicando
    eventuali alias di normalizzazione."""
    if not name:
        return ""
    first = name.strip().split(" ")[0]
    return CLUB_ALIASES.get(first, first)


def build_lookups_2025(classifica_2025):
    """Costruisce le mappe per lookup loghi dal 2025."""
    exact = {}             # nome esatto -> logo
    best_by_club = {}      # club -> (posizione, logo) della squadra meglio piazzata

    for item in classifica_2025:
        nome = item.get("squadra", "")
        logo = item.get("logo", "") or ""
        pos = item.get("posizione", 9999)
        if not nome:
            continue
        if logo:
            exact[nome] = logo
            club = club_of(nome)
            current = best_by_club.get(club)
            if current is None or pos < current[0]:
                best_by_club[club] = (pos, logo)

    best_by_club_logos = {club: pair[1] for club, pair in best_by_club.items()}
    return exact, best_by_club_logos


def resolve_logo(nome, exact, best_by_club):
    if nome in exact:
        return exact[nome], "esatto"
    club = club_of(nome)
    if club in best_by_club:
        return best_by_club[club], f"via club '{club}'"
    return "", "nessun match"


# ---------- Main ----------

def main():
    apply_changes = "--apply" in sys.argv

    print("Scarico tutti i documenti di ccAlboDoro...")
    docs = list_documents("ccAlboDoro")
    print(f"Trovati {len(docs)} documenti\n")

    # Trova il doc 2025
    doc_2025 = None
    others = []
    for d in docs:
        data = from_firestore_doc(d)
        if data.get("anno") == 2025:
            doc_2025 = (d, data)
        else:
            others.append((d, data))

    if doc_2025 is None:
        print("ERRORE: nessun documento con anno=2025 trovato in ccAlboDoro")
        sys.exit(1)

    classifica_2025 = doc_2025[1].get("classifica", []) or []
    exact, best_by_club = build_lookups_2025(classifica_2025)

    print(f"Loghi trovati nel 2025:")
    print(f"  - {len(exact)} per match esatto sul nome")
    print(f"  - {len(best_by_club)} club disponibili: {sorted(best_by_club.keys())}\n")

    total_updates = 0
    docs_to_patch = []

    for doc, data in sorted(others, key=lambda x: x[1].get("anno", 0)):
        anno = data.get("anno")
        classifica = data.get("classifica", []) or []
        changed = False
        new_classifica = []

        print(f"=== CC {anno} ===")
        for item in classifica:
            nome = item.get("squadra", "")
            old_logo = item.get("logo", "") or ""
            new_logo, motivo = resolve_logo(nome, exact, best_by_club)

            if new_logo != old_logo:
                changed = True
                total_updates += 1
                marker = "  [CHG]"
            else:
                marker = "       "

            print(f"{marker} {nome:<25s} -> logo: {'(vuoto)' if not new_logo else new_logo}   [{motivo}]")
            new_item = dict(item)
            new_item["logo"] = new_logo
            new_classifica.append(new_item)

        if changed:
            docs_to_patch.append((doc["name"], anno, new_classifica))
        print()

    print(f"\nTotale righe da aggiornare: {total_updates}")
    print(f"Documenti da modificare: {len(docs_to_patch)}")

    if not apply_changes:
        print("\n(dry-run) — rilancia con --apply per scrivere su Firestore.")
        return

    print("\nScrivo su Firestore...")
    for doc_name, anno, new_classifica in docs_to_patch:
        resp = patch_classifica(doc_name, new_classifica)
        if resp.status_code in (200, 201):
            print(f"  OK  CC {anno}")
        else:
            print(f"  KO  CC {anno}: {resp.status_code} {resp.text}")


if __name__ == "__main__":
    main()
