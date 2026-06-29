const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const https = require('https');

const serviceAccount = require('C:/Users/samue/Desktop/habesha-hub-7bd1d-firebase-adminsdk-fbsvc-783a8d4517.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const ANTHROPIC_KEY = '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';

async function translateToEnglish(text) {
  if (!text || text.trim() === '') return text;
  
  // Skip if already mostly English
  const norwegianWords = ['og', 'er', 'for', 'til', 'med', 'av', 'på', 'det', 'en', 'et', 'den', 'de', 'som', 'ikke', 'har', 'kan', 'fra'];
  const words = text.toLowerCase().split(/\s+/);
  const norwegianCount = words.filter(w => norwegianWords.includes(w)).length;
  if (norwegianCount === 0) return text; // Already English

  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 300,
      messages: [{
        role: 'user',
        content: `Translate this business description to English. Return ONLY the translated text, nothing else:\n\n${text}`
      }]
    });

    const req = https.request({
      hostname: 'api.anthropic.com',
      path: '/v1/messages',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ANTHROPIC_KEY,
        'anthropic-version': '2023-06-01',
        'Content-Length': Buffer.byteLength(body)
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve(parsed.content[0].text.trim());
        } catch (e) {
          resolve(text); // Return original if error
        }
      });
    });

    req.on('error', () => resolve(text));
    req.write(body);
    req.end();
  });
}

async function translateAll() {
  const snap = await db.collection('businesses').get();
  console.log(`Found ${snap.size} businesses\n`);
  
  let updated = 0;
  let skipped = 0;
  let failed = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const desc = data.description;
    
    if (!desc || desc.trim() === '') {
      skipped++;
      continue;
    }

    try {
      const translated = await translateToEnglish(desc);
      
      if (translated !== desc) {
        await db.collection('businesses').doc(doc.id).update({ description: translated });
        console.log(`✅ ${data.name}`);
        console.log(`   NO: ${desc.substring(0, 60)}...`);
        console.log(`   EN: ${translated.substring(0, 60)}...\n`);
        updated++;
      } else {
        console.log(`⏭ ${data.name} (already English)`);
        skipped++;
      }

      // Small delay to avoid rate limiting
      await new Promise(r => setTimeout(r, 500));
    } catch (e) {
      console.log(`❌ ${data.name}: ${e.message}`);
      failed++;
    }
  }

  console.log(`\n✅ Updated: ${updated} | ⏭ Skipped: ${skipped} | ❌ Failed: ${failed}`);
  process.exit(0);
}

translateAll();
