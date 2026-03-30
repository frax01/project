const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

const albiDoro = [
  // ==================== CC 2022 ====================
  {
    anno: 2022,
    classifica: [
      { squadra: "Alfa", posizione: 1, logo: "" },
      { squadra: "Zeta Nero", posizione: 2, logo: "" },
      { squadra: "Randa", posizione: 3, logo: "" },
      { squadra: "Tiber A", posizione: 4, logo: "" },
      { squadra: "Clipper", posizione: 5, logo: "" },
      { squadra: "Monte Grifone", posizione: 6, logo: "" },
      { squadra: "Deneb", posizione: 7, logo: "" },
      { squadra: "Tiber B", posizione: 8, logo: "" },
      { squadra: "Starter", posizione: 9, logo: "" },
      { squadra: "Punta", posizione: 10, logo: "" },
      { squadra: "Elis", posizione: 11, logo: "" },
      { squadra: "Fontane", posizione: 12, logo: "" },
      { squadra: "Zeta Rosso", posizione: 13, logo: "" },
      { squadra: "Grandangolo", posizione: 14, logo: "" },
      { squadra: "Gekonda", posizione: 15, logo: "" },
      { squadra: "Junior", posizione: 16, logo: "" },
    ],
    marcatori: [
      { nome: "Ursino", gol: 18, squadra: "Starter" },
      { nome: "Luciani", gol: 15, squadra: "Randa" },
      { nome: "Tocci", gol: 13, squadra: "Elis" },
      { nome: "Moccia", gol: 11, squadra: "Zeta Nero" },
      { nome: "Girgenti", gol: 9, squadra: "Monte Grifone" },
      { nome: "Paterno'", gol: 8, squadra: "Starter" },
      { nome: "Remagni", gol: 7, squadra: "Zeta Nero" },
      { nome: "Calabro'", gol: 6, squadra: "Alfa" },
      { nome: "Cortese", gol: 6, squadra: "Punta" },
      { nome: "Ruscazio", gol: 6, squadra: "Monte Grifone" },
      { nome: "Micheli", gol: 6, squadra: "Clipper" },
      { nome: "Scarano", gol: 5, squadra: "Gekonda" },
    ],
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  },

  // ==================== CC 2023 ====================
  {
    anno: 2023,
    classifica: [
      { squadra: "Zeta Rosso", posizione: 1, logo: "" },
      { squadra: "Clipper", posizione: 2, logo: "" },
      { squadra: "Grandangolo", posizione: 3, logo: "" },
      { squadra: "Alfa", posizione: 4, logo: "" },
      { squadra: "Monte Grifone", posizione: 5, logo: "" },
      { squadra: "Deneb Rapax", posizione: 6, logo: "" },
      { squadra: "Randa", posizione: 7, logo: "" },
      { squadra: "Tiber D", posizione: 8, logo: "" },
      { squadra: "Zeta Nero", posizione: 9, logo: "" },
      { squadra: "Tiber A", posizione: 10, logo: "" },
      { squadra: "Elis Nero", posizione: 11, logo: "" },
      { squadra: "Elis Blu", posizione: 12, logo: "" },
      { squadra: "Junior Top", posizione: 13, logo: "" },
      { squadra: "Junior Big", posizione: 14, logo: "" },
      { squadra: "Punta", posizione: 15, logo: "" },
      { squadra: "Geko", posizione: 16, logo: "" },
      { squadra: "Tiber B", posizione: 17, logo: "" },
      { squadra: "Deneb Felix", posizione: 18, logo: "" },
      { squadra: "Tiber C", posizione: 19, logo: "" },
    ],
    marcatori: [
      { nome: "Farina", gol: 13, squadra: "Zeta Nero" },
      { nome: "Vender", gol: 9, squadra: "Junior Top" },
      { nome: "Zendrini", gol: 8, squadra: "Grandangolo" },
      { nome: "Ruscazio", gol: 8, squadra: "Monte Grifone" },
      { nome: "Girgenti", gol: 8, squadra: "Monte Grifone" },
      { nome: "Calabro'", gol: 7, squadra: "Alfa" },
      { nome: "Todesco", gol: 7, squadra: "Randa" },
      { nome: "Bernacchi", gol: 6, squadra: "Deneb Rapax" },
      { nome: "Aschi", gol: 6, squadra: "Junior Big" },
      { nome: "Parola", gol: 6, squadra: "Grandangolo" },
      { nome: "Cipriani", gol: 6, squadra: "Junior Big" },
    ],
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  },

  // ==================== CC 2024 ====================
  {
    anno: 2024,
    classifica: [
      { squadra: "Elis Blu", posizione: 1, logo: "" },
      { squadra: "Zeta Nero", posizione: 2, logo: "" },
      { squadra: "Deneb", posizione: 3, logo: "" },
      { squadra: "Elis Nero", posizione: 4, logo: "" },
      { squadra: "Montegrifone", posizione: 5, logo: "" },
      { squadra: "Tiber Rosso", posizione: 6, logo: "" },
      { squadra: "Junior", posizione: 7, logo: "" },
      { squadra: "Geko", posizione: 8, logo: "" },
      { squadra: "Tiber Bianco", posizione: 9, logo: "" },
      { squadra: "Tiber Blu", posizione: 10, logo: "" },
      { squadra: "Zeta Rosso", posizione: 11, logo: "" },
      { squadra: "Clipper", posizione: 12, logo: "" },
      { squadra: "Grandangolo", posizione: 13, logo: "" },
      { squadra: "Randa", posizione: 14, logo: "" },
      { squadra: "Punta", posizione: 15, logo: "" },
      { squadra: "Tiber Nero", posizione: 16, logo: "" },
    ],
    marcatori: [
      { nome: "Di Giovanni", gol: 17, squadra: "Deneb" },
      { nome: "Vender", gol: 17, squadra: "Junior" },
      { nome: "Memmi", gol: 12, squadra: "Elis Club" },
      { nome: "Denise F.", gol: 10, squadra: "Zeta Club" },
      { nome: "Fuschino", gol: 10, squadra: "Tiber" },
      { nome: "Aureliano", gol: 10, squadra: "Deneb" },
      { nome: "Parola", gol: 9, squadra: "Grandangolo" },
      { nome: "Bernardi", gol: 8, squadra: "Deneb" },
      { nome: "Panozzo", gol: 7, squadra: "Randa Verona" },
      { nome: "Denise S.", gol: 6, squadra: "Zeta Club" },
      { nome: "Santini", gol: 6, squadra: "Geko & Rampa" },
    ],
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  },
];

async function seedAlboDoro() {
  console.log("🏆 Inizio caricamento Albo d'Oro...\n");

  for (const albo of albiDoro) {
    try {
      const docRef = await db.collection("ccAlboDoro").add(albo);
      console.log(
        `✅ CC ${albo.anno} caricato con successo! (doc ID: ${docRef.id})`
      );
      console.log(
        `   - ${albo.classifica.length} squadre in classifica`
      );
      console.log(`   - ${albo.marcatori.length} marcatori\n`);
    } catch (error) {
      console.error(`❌ Errore nel caricare CC ${albo.anno}:`, error);
    }
  }

  // Seed palmares (vittorie per club)
  console.log("🏆 Aggiornamento palmares...");
  try {
    const alboSnap = await db.collection("ccAlboDoro").get();
    const vittorie = {};
    alboSnap.docs.forEach((doc) => {
      const classifica = doc.data().classifica || [];
      const winner = classifica.find((item) => item.posizione === 1);
      if (winner && winner.squadra) {
        const club = winner.squadra.split(" ")[0];
        vittorie[club] = (vittorie[club] || 0) + 1;
      }
    });
    await db.collection("ccVittorieClub").doc("palmares").set({
      vittorie,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log("✅ Palmares aggiornato:", vittorie);
  } catch (error) {
    console.error("❌ Errore nell'aggiornamento palmares:", error);
  }

  console.log("\n🎉 Caricamento completato!");
  process.exit(0);
}

seedAlboDoro();
