const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule }        = require('firebase-functions/v2/scheduler');
const { initializeApp }     = require('firebase-admin/app');
const { getFirestore }      = require('firebase-admin/firestore');
const { getMessaging }      = require('firebase-admin/messaging');
const { logger }            = require('firebase-functions');

initializeApp();

const db  = getFirestore();
const fcm = getMessaging();

const TOPIC_ALL        = 'all_users';
const TOPIC_PHARMACIEN = 'pharmacien';
const TOPIC_MEDECIN    = 'medecin';
const TOPIC_KINE       = 'kine';
const TOPIC_COMMERCIAL = 'commercial';

function topicForTarget(target) {
  switch (target) {
    case 'pharmacien': return TOPIC_PHARMACIEN;
    case 'medecin':    return TOPIC_MEDECIN;
    case 'kine':       return TOPIC_KINE;
    case 'commercial': return TOPIC_COMMERCIAL;
    default:           return TOPIC_ALL;
  }
}

// ── Envoi push à chaque nouveau doc dans notification_queue ──────────────────
exports.sendPushNotification = onDocumentCreated(
  {
    document: 'notification_queue/{docId}',
    region: 'us-central1',
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const { title, body, target = 'all', type = 'info' } = data;
    const docRef = db.collection('notification_queue').doc(event.params.docId);

    if (!title || !body) {
      await docRef.update({ status: 'error', error: 'Titre ou corps manquant' });
      return;
    }

    const topic = topicForTarget(target);

    try {
      const messageId = await fcm.send({
        topic,
        notification: { title, body },
        data: { type, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
        apns: {
          payload: { aps: { sound: 'default', badge: 1 } },
        },
        android: {
          priority: 'high',
          notification: { sound: 'default', channelId: 'eacademia_default' },
        },
      });

      await docRef.update({
        status: 'sent',
        messageId,
        processedAt: getFirestore.FieldValue?.serverTimestamp() ?? new Date(),
      });
      logger.info(`✅ Push envoyé topic:${topic} — "${title}"`, { messageId });
    } catch (err) {
      logger.error('❌ Erreur FCM', err);
      await docRef.update({ status: 'error', error: err.message });
    }
  }
);

// ── Nettoyage quotidien des notifications > 30 jours ────────────────────────
exports.cleanOldNotifications = onSchedule(
  { schedule: 'every 24 hours', region: 'europe-west1' },
  async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);

    const snap = await db
      .collection('notification_queue')
      .where('sentAt', '<', cutoff)
      .get();

    if (snap.empty) return;

    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    logger.info(`🗑 ${snap.size} vieilles notifications supprimées`);
  }
);
