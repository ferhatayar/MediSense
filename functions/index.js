/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { CloudSchedulerClient } = require("@google-cloud/scheduler");

admin.initializeApp();

const projectId = "medisenseapp-ece7b"; // Firebase Proje ID
const location = "us-central1"; // Firebase bölgesi

const scheduler = new CloudSchedulerClient();

/**
 * Firestore'a ilaç eklenince Cloud Scheduler'da görev oluşturur.
 */
exports.scheduleMedicineReminder = onDocumentCreated(
  "medicines/{medicineId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const medicineId = event.params.medicineId;

    if (!data.logs || !data.userId) return;

    const authClient = await admin.credential.applicationDefault().getAccessToken();

    for (const dateKey of Object.keys(data.logs)) {
      const log = data.logs[dateKey];

      for (const timeData of log.times) {
        let [hour, minute] = timeData.time
          .replace("PM", "")
          .replace("AM", "")
          .split(":")
          .map(Number);

        if (timeData.time.includes("PM") && hour !== 12) hour += 12;
        if (timeData.time.includes("AM") && hour === 12) hour = 0;

        const reminderTime = new Date(dateKey);
        reminderTime.setHours(hour, minute, 0, 0);

        const jobName = `projects/${projectId}/locations/${location}/jobs/reminder-${medicineId}-${hour}-${minute}`;

        const job = {
          name: jobName,
          schedule: `${minute} ${hour} * * *`, // Günlük belirli saatte çalıştır
          timeZone: "Europe/Istanbul",
          httpTarget: {
            uri: `https://${location}-${projectId}.cloudfunctions.net/sendMedicineReminder`,
            httpMethod: "POST",
            body: Buffer.from(JSON.stringify({ medicineId })).toString("base64"),
            headers: { "Content-Type": "application/json" },
          },
        };

        try {
          await scheduler.createJob({
            parent: `projects/${projectId}/locations/${location}`,
            job: job,
          });
          logger.info(`✅ Görev oluşturuldu: ${jobName}`);
        } catch (error) {
          logger.error("🚨 Cloud Scheduler hatası:", error);
        }
      }
    }
  }
);

/**
 * Cloud Scheduler tarafından çağrılan ve bildirim gönderen HTTP fonksiyonudur.
 */
exports.sendMedicineReminder = onRequest(async (req, res) => {
  try {
    const { medicineId, userId } = req.body;
    if (!medicineId || !userId) return res.status(400).send("Medicine ID and User ID are required.");

    const db = admin.firestore();
    
    // İlaç verisini Firestore'dan al
    const medicineDoc = await db
      .collection("medications")
      .doc(userId)
      .collection("medicines")
      .doc(medicineId)
      .get();
    
    if (!medicineDoc.exists) {
      console.warn(`⚠️ Medicine not found: ${medicineId}`);
      return res.status(404).send("Medicine not found.");
    }

    const data = medicineDoc.data();
    console.log("📄 Medicine Data:", data);

    // Kullanıcı verisini Firestore'dan al
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      console.warn(`⚠️ User not found: ${userId}`);
      return res.status(404).send("User not found.");
    }

    const userData = userDoc.data();
    const tokens = userData?.fcmToken || "";

    if (tokens.length === 0) {
      console.warn(`⚠️ No FCM tokens found for user: ${userId}`);
      return res.status(200).send("No tokens found.");
    }

    // FCM bildirimi oluştur
    const message = {
      notification: {
        title: `💊 İlaç Hatırlatma: ${data.name}`,
        body: `Saat ${data.time} ilacınızı almayı unutmayın!`,
      },
      tokens: tokens,
    };

    // FCM bildirimi gönder
    const response = await admin.messaging().sendMulticast(message);
    console.info(`📢 Bildirim gönderildi: ${data.name} - Kullanıcı: ${userId}`, response);

    return res.status(200).send("Bildirim başarıyla gönderildi.");
  } catch (error) {
    console.error("🚨 Bildirim gönderme hatası:", error);
    return res.status(500).send("Internal Server Error");
  }
});






