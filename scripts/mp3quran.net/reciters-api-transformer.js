import fs from 'fs';

const API_URL = 'https://www.mp3quran.net/api/v3/reciters?language=eng';

async function transformRecitersAndRecitations() {
  try {
    const response = await fetch(API_URL);
    const data = await response.json();
    const reciters = [];
    const recitations = [];

    data.reciters.forEach((reciter) => {
      // Add reciter info
      reciters.push({
        id: reciter.id,
        name: reciter.name,
        letter: reciter.letter
      });

      // Find the matching moshaf where `moshaf.id === reciter.id`
      const matchingMoshaf = reciter.moshaf.find((m) => m.id === reciter.id);
      if (matchingMoshaf) {
        recitations.push({
          id: reciter.id,
          narration_id: matchingMoshaf.name, // Replace with actual ID later
          server: matchingMoshaf.server,
          available_chapters: matchingMoshaf.surah_list.split(',').map(Number)
        });
      }
    });

    // Write JSON files
    fs.writeFileSync('reciters.json', JSON.stringify(reciters, null, 2));
    fs.writeFileSync('recitations.json', JSON.stringify(recitations, null, 2));

    console.log('✅ Files generated successfully!');
  } catch (error) {
    console.error('❌ Error fetching or processing data:', error);
  }
}

transformRecitersAndRecitations();
