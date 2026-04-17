"""
Upload dei loghi mancanti su Firebase Storage + aggiornamento di TUTTI
i documenti ccAlboDoro (incluso 2025) con la mappatura corretta.

Regole:
  1. Per ogni file locale in LOCAL_FOLDER:
     - se non e' gia' in Storage sotto logo/<filename>, lo carica
     - costruisce la URL pubblica con token
  2. Per ogni squadra in ogni documento ccAlboDoro:
     - lookup in EXACT_NAMES (match esatto sul nome squadra)
     - altrimenti lookup in CLUB_DEFAULTS (match sulla prima parola / club)
     - altrimenti logo vuoto ""
  3. Se il logo risultante e' diverso da quello attuale, patcha il documento.

Uso:
    python functions/uploadAndApplyLoghi.py           # dry-run (mostra cosa farebbe)
    python functions/uploadAndApplyLoghi.py --upload  # carica i file mancanti in Storage
    python functions/uploadAndApplyLoghi.py --apply   # carica + aggiorna Firestore
"""

import os
import sys
import uuid
import urllib.parse

import firebase_admin
from firebase_admin import credentials, firestore, storage

SERVICE_ACCOUNT = os.path.join(os.path.dirname(__file__), "serviceAccount.json")
LOCAL_FOLDER = r"C:\Users\francesco\Desktop\Loghi\Loghi club"
LOCAL_SUBFOLDER = os.path.join(LOCAL_FOLDER, "Versioni png senza sfondo")
BUCKET_NAME = "club-60d94.appspot.com"
STORAGE_PREFIX = "logo/"

# --- Mappatura squadra -> nome file (dentro logo/) ---------------------------

# Match esatto sul nome squadra (case-insensitive). Ha priorita' assoluta.
EXACT_NAMES = {
    # Elis
    "Elis Blu": "Elis Blu.png",
    "Elis Nero": "Elis Nero.png",
    "Elis Bianco": "Elis Bianco.png",
    # Punta
    "Punta Real": "Punta_Real-removebg-preview.png",
    "Punta Athletic": "Punta_Athletic-removebg-preview.png",
    "Punta Torino": "Punta Torino.jpg",
    # Tiber
    "Tiber Rosso": "Tiber_Rosso-removebg-preview.png",
    "Tiber Blu": "Tiber Blu.png",
    "Tiber Bianco": "Tiber Bianco.png",
    "Tiber Nero": "Tiber Nero.png",
    "Tiber Roma": "Tiber Roma.jpeg",
    "TiberAlfa": "TiberAlfa-removebg-preview-new.png",
    "Tiber Alfa": "TiberAlfa-removebg-preview-new.png",
    # Zeta
    "Zeta Nero": "ZetaNero-removebg-preview.png",
    "Zeta Rosso": "ZetaRosso-removebg-preview.png",
    "Zeta Orange": "Zeta_orange_nosfondo.png",
    "Zeta Azzurro": "ZetaAzzurro_nosfondo.png",
    "Zeta Milano": "Zeta Milano.png",
    # Clubs con nome lungo
    "Deneb Bologna": "Deneb Bologna.jpg",
    "Alfa Napoli": "Alfa Napoli.png",
    "Randa Verona": "Randa_Verona-removebg-preview.png",
    "Junior Roma": "Junior_Roma-removebg-preview.png",
    "Grandangolo Genova": "Grandangolo Genova.png",
    "Spes Club": "Spes_Club-removebg-preview.png",
    "Castello Cagliari": "Castello Cagliari.jpg",
    "Starter Catania": "Starter Catania.jpg",
    "Rampa Sesto": "Rampa Sesto.jpg",
    "Prato Boys": "PratoBoys.jpg",
    "Effe 1": "Effe1 Modena.jpg",
    "Geko Brescia": "Geko Brescia.jpeg",
    "Fontane": "Fontane.jpeg",
    "Clipper": "Clipper.jpeg",
    "Gekonda": "Gekonda.jpeg",
    "Kalta": "Kalta.png",
    "Zenit": "Zenit.jpg",
    # Deneb varianti storiche
    "Deneb": "Deneb Bologna.jpg",
    "Deneb Rapax": "Deneb Bologna.jpg",
    "Deneb Felix": "Deneb Bologna.jpg",
    # Junior varianti storiche
    "Junior": "Junior_Roma-removebg-preview.png",
    "Junior Top": "Junior_Roma-removebg-preview.png",
    "Junior Big": "Junior_Roma-removebg-preview.png",
    # Alfa generico/storico
    "Alfa": "Alfa Napoli.png",
    "Alfa Rosso": "Alfa Napoli.png",
    "Alfa Blu": "Alfa Napoli.png",
    # Castello varianti
    "Castello": "Castello Cagliari.jpg",
    # Montegrifone varianti (non abbiamo logo: lasciamo vuoto intenzionalmente)
    # Starter, Rampa, Prato Boys generici
    "Starter": "Starter Catania.jpg",
    "Rampa": "Rampa Sesto.jpg",
    # Geko varianti
    "Geko": "LOGO GEKO.png",
    # Elis generico (storico) -> Blu (squadra principale)
    "Elis": "Elis Blu.png",
    # Punta storico generico -> Real
    "Punta": "Punta_Real-removebg-preview.png",
    # Punta varianti 2016-2017 senza logo dedicato -> Real come fallback
    "Punta Tigers": "Punta_Real-removebg-preview.png",
    "Punta Lions": "Punta_Real-removebg-preview.png",
    # Randa / Grandangolo / Spes
    "Randa": "Randa_Verona-removebg-preview.png",
    "Grandangolo": "Grandangolo Genova.png",
    "Spes": "Spes_Club-removebg-preview.png",
}

# Fallback sul "club" (prima parola del nome) per nomi storici non mappati.
CLUB_DEFAULTS = {
    "Alfa": "Alfa Napoli.png",
    "Castello": "Castello Cagliari.jpg",
    "Clipper": "Clipper.jpeg",
    "Deneb": "Deneb Bologna.jpg",
    "Effe": "Effe1 Modena.jpg",
    "Elis": "Elis Blu.png",
    "Fontane": "Fontane.jpeg",
    "Geko": "LOGO GEKO.png",
    "Gekonda": "Gekonda.jpeg",
    "Grandangolo": "Grandangolo Genova.png",
    "Junior": "Junior_Roma-removebg-preview.png",
    "Kalta": "Kalta.png",
    "Prato": "PratoBoys.jpg",
    "Punta": "Punta_Real-removebg-preview.png",
    "Rampa": "Rampa Sesto.jpg",
    "Randa": "Randa_Verona-removebg-preview.png",
    "Spes": "Spes_Club-removebg-preview.png",
    "Starter": "Starter Catania.jpg",
    "Tiber": "Tiber_Rosso-removebg-preview.png",
    "Zenit": "Zenit.jpg",
    "Zeta": "ZetaNero-removebg-preview.png",
}

# File locali che vogliamo garantire esistano in Storage (tutti quelli usati
# nelle mappe sopra + eventuali extra). Li carichiamo se mancanti.
FILES_NEEDED = sorted(set(list(EXACT_NAMES.values()) + list(CLUB_DEFAULTS.values())))


# -----------------------------------------------------------------------------

def init_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT)
        firebase_admin.initialize_app(cred, {"storageBucket": BUCKET_NAME})
    return firestore.client(), storage.bucket()


def find_local_file(filename):
    """Cerca il file in LOCAL_FOLDER o nella sottocartella Versioni png."""
    for folder in (LOCAL_FOLDER, LOCAL_SUBFOLDER):
        candidate = os.path.join(folder, filename)
        if os.path.isfile(candidate):
            return candidate
    return None


def content_type_for(filename):
    ext = filename.lower().rsplit(".", 1)[-1]
    return {
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
    }.get(ext, "application/octet-stream")


def storage_url(bucket_name, object_name, token):
    """Genera la URL stile app (con alt=media&token=...) per un file in Storage."""
    quoted = urllib.parse.quote(object_name, safe="")
    return (
        f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}/o/{quoted}"
        f"?alt=media&token={token}"
    )


def ensure_file_in_storage(bucket, filename, do_upload):
    """Restituisce (url, stato). Se manca e do_upload=False, ritorna (None, 'missing')."""
    object_name = STORAGE_PREFIX + filename
    blob = bucket.blob(object_name)
    blob.reload_or_none = None
    try:
        if blob.exists():
            blob.reload()
            meta = blob.metadata or {}
            token = meta.get("firebaseStorageDownloadTokens")
            if not token:
                # File presente senza token - ne aggiungiamo uno per poterlo linkare
                token = str(uuid.uuid4())
                blob.metadata = {"firebaseStorageDownloadTokens": token}
                if do_upload:
                    blob.patch()
                else:
                    return (None, "needs-token")
            return (storage_url(bucket.name, object_name, token), "exists")
    except Exception as e:
        return (None, f"error: {e}")

    # Non esiste: dobbiamo caricarlo
    local = find_local_file(filename)
    if not local:
        return (None, "local-missing")

    if not do_upload:
        return (None, "missing")

    token = str(uuid.uuid4())
    blob.metadata = {"firebaseStorageDownloadTokens": token}
    blob.upload_from_filename(local, content_type=content_type_for(filename))
    return (storage_url(bucket.name, object_name, token), "uploaded")


def build_file_url_map(bucket, do_upload):
    url_map = {}
    report = {"exists": [], "uploaded": [], "missing": [], "local-missing": [], "needs-token": [], "error": []}
    for filename in FILES_NEEDED:
        url, status = ensure_file_in_storage(bucket, filename, do_upload)
        if url:
            url_map[filename] = url
        # bucket categoria
        if status.startswith("error"):
            report["error"].append((filename, status))
        else:
            report.setdefault(status, []).append(filename)
    return url_map, report


def club_of(name):
    return name.strip().split(" ")[0] if name else ""


def resolve_logo(nome, url_map):
    """Risolve il logo per una squadra in base alla mappatura, restituisce (url, motivo)."""
    if not nome:
        return "", "nome-vuoto"
    # Match esatto (case-sensitive come definito)
    if nome in EXACT_NAMES:
        f = EXACT_NAMES[nome]
        if f in url_map:
            return url_map[f], f"esatto ({f})"
        return "", f"esatto ma file non disponibile ({f})"
    # Fallback su club
    club = club_of(nome)
    if club in CLUB_DEFAULTS:
        f = CLUB_DEFAULTS[club]
        if f in url_map:
            return url_map[f], f"via club '{club}' ({f})"
        return "", f"via club '{club}' ma file non disponibile"
    return "", f"nessun match (club '{club}')"


def list_docs(db):
    return list(db.collection("ccAlboDoro").stream())


def main():
    args = set(sys.argv[1:])
    do_upload = ("--upload" in args) or ("--apply" in args)
    do_apply = "--apply" in args

    db, bucket = init_firebase()

    print(f"Fase 1: verifica/upload loghi in Storage (do_upload={do_upload})")
    url_map, report = build_file_url_map(bucket, do_upload)
    print(f"  esistenti   : {len(report.get('exists', []))}")
    print(f"  caricati ora: {len(report.get('uploaded', []))}")
    if report.get("uploaded"):
        for f in report["uploaded"]:
            print(f"    + {f}")
    if report.get("missing"):
        print(f"  da caricare (solo con --upload/--apply): {len(report['missing'])}")
        for f in report["missing"]:
            print(f"    - {f}")
    if report.get("local-missing"):
        print(f"  FILE LOCALI MANCANTI ({len(report['local-missing'])}):")
        for f in report["local-missing"]:
            print(f"    ! {f}")
    if report.get("needs-token"):
        print(f"  senza token (da risistemare con --upload/--apply): {len(report['needs-token'])}")
    if report.get("error"):
        print(f"  ERRORI: {len(report['error'])}")
        for f, e in report["error"]:
            print(f"    X {f}: {e}")

    print(f"\nFase 2: analisi documenti ccAlboDoro (apply={do_apply})")
    docs = list_docs(db)
    docs_sorted = sorted(docs, key=lambda d: (d.to_dict() or {}).get("anno", 0))

    total_changes = 0
    patches = []  # (doc_ref, new_classifica, anno)

    for doc in docs_sorted:
        data = doc.to_dict() or {}
        anno = data.get("anno")
        classifica = data.get("classifica") or []
        if not classifica:
            continue
        print(f"\n=== CC {anno} ===")
        new_classifica = []
        changed_here = False
        for item in classifica:
            nome = item.get("squadra", "")
            old_logo = item.get("logo", "") or ""
            new_logo, motivo = resolve_logo(nome, url_map)
            marker = "  [CHG]" if new_logo != old_logo else "       "
            if new_logo != old_logo:
                changed_here = True
                total_changes += 1
            short = "(vuoto)" if not new_logo else new_logo.split("?")[0].rsplit("/", 1)[-1]
            print(f"{marker} {nome:<22s} -> {short}   [{motivo}]")
            new_item = dict(item)
            new_item["logo"] = new_logo
            new_classifica.append(new_item)

        if changed_here:
            patches.append((doc.reference, new_classifica, anno))

    print(f"\nRighe totali da aggiornare: {total_changes}")
    print(f"Documenti da patchare    : {len(patches)}")

    if not do_apply:
        print("\n(dry-run) — rilancia con --apply per scrivere su Firestore.")
        return

    print("\nPatch Firestore...")
    for ref, new_cls, anno in patches:
        try:
            ref.update({"classifica": new_cls})
            print(f"  OK  CC {anno}")
        except Exception as e:
            print(f"  KO  CC {anno}: {e}")


if __name__ == "__main__":
    main()
