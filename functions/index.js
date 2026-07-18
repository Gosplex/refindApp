const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");

const onesignalApiKey = defineSecret("ONESIGNAL_API_KEY");
const onesignalAppId = defineSecret("ONESIGNAL_APP_ID");
const openRouterApiKey = defineSecret("OPENROUTER_API_KEY");

admin.initializeApp();
const db = admin.firestore();

const ONESIGNAL_API_URL = "https://onesignal.com/api/v1/notifications";
const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";

async function generateAIMessage(reminderCount, postTitle, postDescription, postDomain) {
    try {
        const apiKey = openRouterApiKey.value();

        const prompt = `You are an assistant that creates short, engaging push notifications.

Context:
- Content title: "${postTitle}"
- Description: "${postDescription || "N/A"}"
- Source: "${postDomain || "unknown"}"
- Times reminded before: ${reminderCount}

Rules:
- Keep it short (max 12 words)
- Make it feel personal and natural
- Do NOT sound robotic
- Encourage action subtly
- Vary tone if reminded multiple times

Return JSON:
{
  "title": "...",
  "body": "..."
}`;

        const response = await axios.post(
            OPENROUTER_API_URL,
            {
                model: "openai/gpt-4o-mini",
                messages: [
                    {
                        role: "user",
                        content: prompt
                    }
                ]
            },
            {
                headers: {
                    "Authorization": `Bearer ${apiKey}`,
                    "Content-Type": "application/json"
                },
                timeout: 10000
            }
        );

        const content = response.data.choices[0].message.content;
        const jsonResult = JSON.parse(content);

        return {
            title: jsonResult.title,
            body: jsonResult.body
        };
    } catch (error) {
        logger.error("Error generating AI message:", error);
        const fallbackMessages = [
            { title: "Hey", body: `You saved "${postTitle}". Ready to check it out?` },
            { title: "Still interested", body: `Don't forget about "${postTitle}". It might be valuable!` },
            { title: "Quick reminder", body: `Take a moment to review "${postTitle}"` },
            { title: "One more look", body: `"${postTitle}" is still waiting for you` },
            { title: "Final reminder", body: `Last chance to check "${postTitle}"` },
        ];
        const index = Math.min(reminderCount, fallbackMessages.length - 1);
        return fallbackMessages[index];
    }
}

async function sendOneSignalNotification(userId, title, body, data = {}) {
    try {
        const appId = onesignalAppId.value();
        const apiKey = onesignalApiKey.value();

        const response = await axios.post(
            ONESIGNAL_API_URL,
            {
                app_id: appId,
                include_external_user_ids: [userId],
                headings: { en: title },
                contents: { en: body },
                data: data,
                channel_for_external_user_ids: "push",
            },
            {
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Basic ${apiKey}`,
                },
            }
        );

        logger.info(`Notification sent to ${userId}:`, response.data);
        return response.data;
    } catch (error) {
        logger.error("Error sending OneSignal notification:", error);
        throw error;
    }
}

function getReminderDelays(defaultReminder) {
    switch (defaultReminder) {
        case "2 hours":
            return [2 * 60 * 60 * 1000, 6 * 60 * 60 * 1000, 24 * 60 * 60 * 1000, 2 * 24 * 60 * 60 * 1000, 3 * 24 * 60 * 60 * 1000];
        case "6 hours":
            return [6 * 60 * 60 * 1000, 24 * 60 * 60 * 1000, 2 * 24 * 60 * 60 * 1000, 3 * 24 * 60 * 60 * 1000];
        case "1 day":
            return [24 * 60 * 60 * 1000, 2 * 24 * 60 * 60 * 1000, 3 * 24 * 60 * 60 * 1000, 5 * 24 * 60 * 60 * 1000];
        default:
            return [2 * 60 * 60 * 1000];
    }
}

function isQuietHours(settings) {
    if (!settings.quietHoursEnabled) return false;

    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();

    const startHour = settings.quietStartHour || 22;
    const startMinute = settings.quietStartMinute || 0;
    const endHour = settings.quietEndHour || 8;
    const endMinute = settings.quietEndMinute || 0;

    const currentTotal = currentHour * 60 + currentMinute;
    const startTotal = startHour * 60 + startMinute;
    const endTotal = endHour * 60 + endMinute;

    if (startTotal <= endTotal) {
        return currentTotal >= startTotal && currentTotal <= endTotal;
    } else {
        return currentTotal >= startTotal || currentTotal <= endTotal;
    }
}

function getNextAllowedTime(settings) {
    const now = new Date();
    const endHour = settings.quietEndHour || 8;
    const endMinute = settings.quietEndMinute || 0;

    let nextTime = new Date(now);
    nextTime.setHours(endHour, endMinute, 0, 0);

    if (nextTime <= now) {
        nextTime.setDate(nextTime.getDate() + 1);
    }

    return nextTime;
}

async function scheduleReminderJobs(userId, postId, postTitle, postDescription, postDomain, startTime, settings, customDelays = null) {
    const delays =
        customDelays ||
        getReminderDelays(
            (settings && settings.defaultReminder) || "2 hours"
        );

    const stopAfter =
        (settings && settings.stopAfter) || "Never";

    for (let i = 0; i < delays.length; i++) {
        const scheduledTime = new Date(startTime.getTime() + delays[i]);

        if (stopAfter !== "Never") {
            const stopAfterDays = { "1 day": 1, "3 days": 3, "7 days": 7 }[stopAfter];
            const postCreatedAt = new Date(startTime);
            const daysSinceCreation = (scheduledTime - postCreatedAt) / (1000 * 60 * 60 * 24);

            if (daysSinceCreation > stopAfterDays) {
                logger.info(`Stopping reminders for post ${postId} after ${stopAfterDays} days`);
                break;
            }
        }

        await db.collection("notification_queue").add({
            userId,
            postId,
            postTitle,
            postDescription,
            postDomain,
            reminderIndex: i,
            scheduledTime: admin.firestore.Timestamp.fromDate(scheduledTime),
            status: "pending",
            createdAt: admin.firestore.Timestamp.now(),
        });

        logger.info(`Scheduled reminder ${i + 1}/${delays.length} for user ${userId} at ${scheduledTime}`);
    }
}

exports.scheduleReminder = onRequest(
    { cors: true, timeoutSeconds: 60, secrets: [onesignalApiKey, onesignalAppId, openRouterApiKey] },
    async (req, res) => {
        try {
            const { userId, postId, postTitle, postDescription, postDomain, createdAt } = req.body;

            if (!userId || !postId || !postTitle) {
                return res.status(400).json({ error: "Missing required fields: userId, postId, postTitle" });
            }

            const userDoc = await db.collection("users").doc(userId).get();
            const userData = userDoc.data();
            const settings = (userData && userData.settings) || {};

            if (settings.notificationsEnabled === false) {
                return res.status(200).json({ message: "Notifications disabled for user" });
            }

            if (isQuietHours(settings)) {
                const nextAllowedTime = getNextAllowedTime(settings);
                await scheduleReminderJobs(userId, postId, postTitle, postDescription, postDomain, nextAllowedTime, settings);
            } else {
                const delays = getReminderDelays(settings.defaultReminder || "2 hours");
                await scheduleReminderJobs(userId, postId, postTitle, postDescription, postDomain, new Date(), settings, delays);
            }

            const createdDate = createdAt ? new Date(createdAt) : new Date();


            await db.collection("reminders").doc(`${userId}_${postId}`).set({
                userId,
                postId,
                postTitle,
                postDescription,
                postDomain,
                createdAt: admin.firestore.Timestamp.fromDate(createdDate),
                scheduledAt: admin.firestore.Timestamp.now(),
                status: "active",
            });

            res.status(200).json({ success: true, message: "Reminders scheduled" });
        } catch (error) {
            logger.error("Error in scheduleReminder:", error);
            res.status(500).json({ error: error.message });
        }
    }
);

exports.cancelReminders = onRequest(
    { cors: true, timeoutSeconds: 60, secrets: [onesignalApiKey, onesignalAppId, openRouterApiKey] },
    async (req, res) => {
        try {
            const { userId, postId } = req.body;

            if (!userId || !postId) {
                return res.status(400).json({ error: "Missing userId or postId" });
            }

            await db.collection("reminders").doc(`${userId}_${postId}`).update({ status: "cancelled" });

            const jobsRef = db.collection("notification_queue")
                .where("userId", "==", userId)
                .where("postId", "==", postId)
                .where("status", "==", "pending");

            const jobs = await jobsRef.get();
            const batch = db.batch();
            jobs.forEach(doc => {
                batch.update(doc.ref, { status: "cancelled" });
            });
            await batch.commit();

            res.status(200).json({ success: true, message: "Reminders cancelled" });
        } catch (error) {
            logger.error("Error in cancelReminders:", error);
            res.status(500).json({ error: error.message });
        }
    }
);

exports.processNotifications = onSchedule(
    { schedule: "* * * * *", timeoutSeconds: 300, memory: "256MiB", secrets: [onesignalApiKey, onesignalAppId, openRouterApiKey] },
    async (event) => {
        try {
            const now = new Date();
            logger.info("Processing notifications at:", now.toISOString());

            const dueNotifications = await db.collection("notification_queue")
                .where("status", "==", "pending")
                .where("scheduledTime", "<=", admin.firestore.Timestamp.fromDate(now))
                .limit(500)
                .get();

            if (dueNotifications.empty) {
                logger.info("No pending notifications due");
                return;
            }

            logger.info(`Found ${dueNotifications.size} notifications to process`);

            const userGroups = new Map();
            dueNotifications.forEach(doc => {
                const data = doc.data();
                if (!userGroups.has(data.userId)) {
                    userGroups.set(data.userId, []);
                }
                userGroups.get(data.userId).push({ docId: doc.id, ...data });
            });

            for (const [userId, notifications] of userGroups) {
                try {
                    const userDoc = await db.collection("users").doc(userId).get();
                    const userData = userDoc.data();
                    const settings = userData?.settings || {};

                    if (settings.notificationsEnabled === false) {
                        const batch = db.batch();
                        for (const notification of notifications) {
                            batch.update(db.collection("notification_queue").doc(notification.docId), {
                                status: "sent",
                                note: "Notifications disabled for user",
                            });
                        }
                        await batch.commit();
                        continue;
                    }

                    for (const notification of notifications) {
                        if (isQuietHours(settings)) {
                            const nextAllowedTime = getNextAllowedTime(settings);
                            await db.collection("notification_queue").doc(notification.docId).update({
                                scheduledTime: admin.firestore.Timestamp.fromDate(nextAllowedTime),
                                rescheduledCount: admin.firestore.FieldValue.increment(1),
                            });
                            continue;
                        }

                        const message = await generateAIMessage(
                            notification.reminderIndex,
                            notification.postTitle,
                            notification.postDescription,
                            notification.postDomain
                        );

                        await sendOneSignalNotification(userId, message.title, message.body, {
                            postId: notification.postId,
                            reminderIndex: notification.reminderIndex,
                            type: "reminder",
                        });

                        await db.collection("notification_queue").doc(notification.docId).update({
                            status: "sent",
                            sentAt: admin.firestore.Timestamp.now(),
                        });

                        logger.info(`Sent reminder ${notification.reminderIndex + 1} to user ${userId}`);
                        await new Promise(resolve => setTimeout(resolve, 100));
                    }
                } catch (error) {
                    logger.error(`Error processing notifications for user ${userId}:`, error);
                }
            }
        } catch (error) {
            logger.error("Error in processNotifications:", error);
        }
    }
);

exports.cleanupNotifications = onSchedule(
    { schedule: "0 2 * * *", timeoutSeconds: 300, memory: "256MiB" },
    async (event) => {
        try {
            const cutoffDate = new Date();
            cutoffDate.setDate(cutoffDate.getDate() - 30);

            const oldNotifications = await db.collection("notification_queue")
                .where("status", "in", ["sent", "cancelled"])
                .where("sentAt", "<=", admin.firestore.Timestamp.fromDate(cutoffDate))
                .limit(1000)
                .get();

            if (oldNotifications.empty) {
                logger.info("No old notifications to clean up");
                return;
            }

            const batch = db.batch();
            oldNotifications.forEach(doc => {
                batch.delete(doc.ref);
            });
            await batch.commit();

            logger.info(`Cleaned up ${oldNotifications.size} old notifications`);
        } catch (error) {
            logger.error("Error in cleanupNotifications:", error);
        }
    }
);

exports.weeklyRecap = onSchedule(
    {
        schedule: "0 * * * *",
        timeoutSeconds: 300,
        memory: "256MiB",
        secrets: [onesignalApiKey, onesignalAppId, openRouterApiKey],
    },
    async () => {
        try {
            logger.info("⏱ Weekly recap check running");

            const now = new Date();

            const londonParts = new Intl.DateTimeFormat("en-GB", {
                timeZone: "Europe/London",
                weekday: "short",
                hour: "numeric",
                hour12: false,
            }).formatToParts(now);

            const day = londonParts.find(p => p.type === "weekday")?.value;
            const hour = parseInt(
                londonParts.find(p => p.type === "hour")?.value || "0"
            );

            // ✅ time window safety
            if (day !== "Sun") return;
            if (hour < 10 || hour > 11) return;

            logger.info("🚀 Weekly recap window active");

            const usersSnap = await db.collection("users").get();

            for (const userDoc of usersSnap.docs) {
                const userId = userDoc.id;
                const user = userDoc.data();

                try {
                    // 🔒 CONDITIONS
                    if (!user.isPro) continue;

                    const settings = user.settings || {};
                    if (settings.notificationsEnabled === false) continue;
                    if (settings.weekRecapEnabled === false) continue;

                    // 🧠 TRACKING
                    const recapRef = db
                        .collection("users")
                        .doc(userId)
                        .collection("meta")
                        .doc("weekly_recap");

                    const recapDoc = await recapRef.get();
                    const weekKey = getWeekKey(now);

                    if (recapDoc.exists && recapDoc.data()?.lastSent === weekKey) {
                        continue;
                    }

                    // 📥 POSTS
                    const postsSnap = await db
                        .collection("users")
                        .doc(userId)
                        .collection("posts")
                        .get();

                    const posts = postsSnap.docs.map(d => d.data());
                    if (posts.length === 0) continue;

                    // 📥 COLLECTIONS
                    const collectionsSnap = await db
                        .collection("users")
                        .doc(userId)
                        .collection("collections")
                        .get();

                    const collectionMap = {};
                    collectionsSnap.docs.forEach(doc => {
                        collectionMap[doc.id] = doc.data().name;
                    });

                    // 📊 ANALYTICS
                    const total = posts.length;
                    const revisited = posts.filter(p => (p.visitCount || 0) > 0).length;
                    const revisitRate = Math.round((revisited / total) * 100);
                    const backlog = posts.filter(p => (p.visitCount || 0) === 0).length;

                    // 🔥 WORST COLLECTION
                    const stats = {};

                    posts.forEach(p => {
                        const key = p.collectionId || "uncategorized";

                        if (!stats[key]) {
                            stats[key] = { total: 0, revisited: 0 };
                        }

                        stats[key].total++;

                        if ((p.visitCount || 0) > 0) {
                            stats[key].revisited++;
                        }
                    });

                    let worstCollectionId = null;
                    let worstRate = 999;

                    for (const key in stats) {
                        const data = stats[key];
                        const rate = data.revisited / data.total;

                        if (rate < worstRate) {
                            worstRate = rate;
                            worstCollectionId = key;
                        }
                    }

                    const worstCollectionName =
                        collectionMap[worstCollectionId] || "your collection";

                    // 🤖 AI PROMPT
                    const prompt = `
You are a product writer for a calm, minimal productivity app.

This notification is a **WEEKLY RECAP**.
The user must immediately understand that this is a reflection of their week.

---

GOAL:
- Make it feel like a weekly summary
- Not a random reminder
- Not generic advice

---

TONE:
- calm
- honest
- slightly reflective
- emotionally intelligent
- NOT motivational
- NOT hype
- NOT corporate

---

USER DATA:
- Saved: ${total}
- Revisited: ${revisited}
- Revisit rate: ${revisitRate}%
- Unread: ${backlog}
- Weakest area: ${worstCollectionName}

---

WRITING RULES:

- Title MUST imply time context (weekly / this week / your week)
- Body MUST feel like a reflection, not instruction
- Max 10 words title
- Max 16 words body

- No:
  "we believe in you"
  "great job"
  "keep going"
  "don't forget"

- No exclamation marks
- No emojis

---

STRUCTURE:

Title → signals weekly recap  
Body → insight about behavior  

---

GOOD EXAMPLES:

"title": "Your week in saved links"
"body": "You saved ${total}, but revisited only ${revisited}"

"title": "This week, things piled up"
"body": "${backlog} links still untouched in ${worstCollectionName}"

"title": "Your weekly recap"
"body": "You revisited ${revisitRate}% of what you saved"

---

BAD EXAMPLES:

- "Unopened links linger..."
- "Don't forget to revisit"
- "Stay consistent"

---

Return ONLY JSON:

{
  "title": "...",
  "body": "..."
}
`;

                    let title = "Your weekly recap";
                    let body = `You revisited ${revisitRate}% of links`;

                    try {
                        const response = await axios.post(
                            OPENROUTER_API_URL,
                            {
                                model: "openai/gpt-4o-mini",
                                messages: [{ role: "user", content: prompt }],
                            },
                            {
                                headers: {
                                    Authorization: `Bearer ${openRouterApiKey.value()}`,
                                    "Content-Type": "application/json",
                                },
                            }
                        );

                        const ai = JSON.parse(response.data.choices[0].message.content);
                        title = ai.title;
                        body = ai.body;
                    } catch (e) {
                        logger.warn("AI failed, using fallback");
                    }

                    // 📲 SEND
                    await sendOneSignalNotification(userId, title, body, {
                        type: "weekly_recap",
                        revisitRate,
                        backlog,
                        weakest: worstCollectionName,
                    });

                    // 🧠 TRACK
                    await recapRef.set({
                        lastSent: weekKey,
                        sentAt: admin.firestore.Timestamp.now(),
                        title,
                        body,
                        weakest: worstCollectionName,
                    });

                    logger.info(`✅ Sent weekly recap to ${userId}`);

                } catch (err) {
                    logger.error(`❌ Error user ${userId}`, err);
                }
            }

        } catch (error) {
            logger.error("❌ Weekly recap job failed", error);
        }
    }
);

// helper
function getWeekKey(date) {
    const year = date.getFullYear();
    const firstDay = new Date(date.getFullYear(), 0, 1);
    const pastDays = (date - firstDay) / 86400000;
    const week = Math.ceil((pastDays + firstDay.getDay() + 1) / 7);
    return `${year}-W${week}`;
}

exports.testProcessNow = onRequest(
    {
        cors: true,
        timeoutSeconds: 300,
        memory: "256MiB",
        secrets: [onesignalApiKey, onesignalAppId, openRouterApiKey]
    },
    async (req, res) => {
        try {
            logger.info("🔧 Manual testProcessNow triggered");

            // Directly query and process pending notifications
            const now = new Date();
            const dueNotifications = await db.collection("notification_queue")
                .where("status", "==", "pending")
                .where("scheduledTime", "<=", admin.firestore.Timestamp.fromDate(now))
                .limit(500)
                .get();

            if (dueNotifications.empty) {
                res.status(200).json({ success: true, message: "No pending notifications" });
                return;
            }

            const userGroups = new Map();
            dueNotifications.forEach(doc => {
                const data = doc.data();
                if (!userGroups.has(data.userId)) {
                    userGroups.set(data.userId, []);
                }
                userGroups.get(data.userId).push({ docId: doc.id, ...data });
            });

            for (const [userId, notifications] of userGroups) {
                const userDoc = await db.collection("users").doc(userId).get();
                const userData = userDoc.data();
                const settings = userData?.settings || {};

                for (const notification of notifications) {
                    if (settings.notificationsEnabled !== false && !isQuietHours(settings)) {
                        const message = await generateAIMessage(
                            notification.reminderIndex,
                            notification.postTitle,
                            notification.postDescription,
                            notification.postDomain
                        );

                        await sendOneSignalNotification(userId, message.title, message.body, {
                            postId: notification.postId,
                            reminderIndex: notification.reminderIndex,
                            type: "reminder",
                        });

                        await db.collection("notification_queue").doc(notification.docId).update({
                            status: "sent",
                            sentAt: admin.firestore.Timestamp.now(),
                        });
                    }
                }
            }

            res.status(200).json({ success: true, message: `Processed ${dueNotifications.size} notifications` });
        } catch (error) {
            logger.error("Error in testProcessNow:", error);
            res.status(500).json({ success: false, error: error.message });
        }
    }


);


exports.testWeeklyRecap = onRequest(
    {
        secrets: [onesignalApiKey, onesignalAppId, openRouterApiKey],
    },
    async (req, res) => {
        try {
            logger.info("🧪 Manual weekly recap test triggered");

            const usersSnap = await db.collection("users").get();

            for (const userDoc of usersSnap.docs) {
                const userId = userDoc.id;

                try {
                    // 📥 POSTS
                    const postsSnap = await db
                        .collection("users")
                        .doc(userId)
                        .collection("posts")
                        .get();

                    const posts = postsSnap.docs.map((d) => d.data());
                    if (posts.length === 0) {
                        logger.info(`No posts for ${userId}`);
                        continue;
                    }

                    // 📥 COLLECTIONS
                    const collectionsSnap = await db
                        .collection("users")
                        .doc(userId)
                        .collection("collections")
                        .get();

                    const collectionMap = {};
                    collectionsSnap.docs.forEach((doc) => {
                        collectionMap[doc.id] = doc.data().name;
                    });

                    // 📊 ANALYTICS
                    const total = posts.length;
                    const revisited = posts.filter(
                        (p) => (p.visitCount || 0) > 0
                    ).length;
                    const revisitRate = Math.round((revisited / total) * 100);
                    const backlog = posts.filter(
                        (p) => (p.visitCount || 0) === 0
                    ).length;

                    // 🔥 WORST COLLECTION
                    const stats = {};

                    posts.forEach((p) => {
                        const key = p.collectionId || "uncategorized";

                        if (!stats[key]) {
                            stats[key] = { total: 0, revisited: 0 };
                        }

                        stats[key].total++;

                        if ((p.visitCount || 0) > 0) {
                            stats[key].revisited++;
                        }
                    });

                    let worstCollectionId = null;
                    let worstRate = 999;

                    for (const key in stats) {
                        const data = stats[key];
                        const rate = data.revisited / data.total;

                        if (rate < worstRate) {
                            worstRate = rate;
                            worstCollectionId = key;
                        }
                    }

                    const worstCollectionName =
                        collectionMap[worstCollectionId] || "your collection";

                    // 🤖 AI PROMPT
                    const prompt = `
You are a product writer for a calm, minimal productivity app.

This notification is a **WEEKLY RECAP**.
The user must immediately understand that this is a reflection of their week.

---

GOAL:
- Make it feel like a weekly summary
- Not a random reminder
- Not generic advice

---

TONE:
- calm
- honest
- slightly reflective
- emotionally intelligent
- NOT motivational
- NOT hype
- NOT corporate

---

USER DATA:
- Saved: ${total}
- Revisited: ${revisited}
- Revisit rate: ${revisitRate}%
- Unread: ${backlog}
- Weakest area: ${worstCollectionName}

---

WRITING RULES:

- Title MUST imply time context (weekly / this week / your week)
- Body MUST feel like a reflection, not instruction
- Max 10 words title
- Max 16 words body

- No:
  "we believe in you"
  "great job"
  "keep going"
  "don't forget"

- No exclamation marks
- No emojis

---

STRUCTURE:

Title → signals weekly recap  
Body → insight about behavior  

---

GOOD EXAMPLES:

"title": "Your week in saved links"
"body": "You saved ${total}, but revisited only ${revisited}"

"title": "This week, things piled up"
"body": "${backlog} links still untouched in ${worstCollectionName}"

"title": "Your weekly recap"
"body": "You revisited ${revisitRate}% of what you saved"

---

BAD EXAMPLES:

- "Unopened links linger..."
- "Don't forget to revisit"
- "Stay consistent"

---

Return ONLY JSON:

{
  "title": "...",
  "body": "..."
}
`;
                    let title = "Your weekly recap";
                    let body = `You revisited ${revisitRate}% of links`;

                    try {
                        const response = await axios.post(
                            OPENROUTER_API_URL,
                            {
                                model: "openai/gpt-4o-mini",
                                messages: [{ role: "user", content: prompt }],
                            },
                            {
                                headers: {
                                    Authorization: `Bearer ${openRouterApiKey.value()}`,
                                    "Content-Type": "application/json",
                                },
                            }
                        );

                        const ai = JSON.parse(
                            response.data.choices[0].message.content
                        );

                        title = ai.title;
                        body = ai.body;
                    } catch (e) {
                        logger.warn("AI failed, using fallback");
                    }

                    // 🧪 DEBUG (important)
                    logger.info({
                        userId,
                        title,
                        body,
                        appId: onesignalAppId.value(),
                        hasKey: !!onesignalApiKey.value(),
                    });

                    // 📲 SEND
                    await sendOneSignalNotification(userId, title, body, {
                        type: "test_weekly",
                        revisitRate,
                        backlog,
                        weakest: worstCollectionName,
                    });

                    logger.info(`🧪 Sent test recap to ${userId}`);
                } catch (err) {
                    logger.error(`❌ Error user ${userId}`, err);
                }
            }

            res.send("✅ Test weekly recap sent");
        } catch (error) {
            logger.error("❌ Test function failed", error);
            res.status(500).send("Error");
        }
    }
);