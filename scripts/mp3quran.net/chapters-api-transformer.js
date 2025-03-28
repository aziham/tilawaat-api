import fs from 'fs';

async function transformChapters() {
  const url = 'https://www.mp3quran.net/api/v3/suwar?language=eng';

  try {
    const response = await fetch(url);
    const data = await response.json();

    if (!data.suwar || !Array.isArray(data.suwar)) {
      throw new Error('Invalid API response format');
    }

    // Transform the data
    const transformedData = data.suwar.map(({ id, name, type }) => ({
      id,
      name: name.trim(), // Trim spaces
      type
    }));

    console.log(transformedData); // Log result

    // Optional: Save to a JSON file
    fs.writeFileSync('chapters.json', JSON.stringify(transformedData, null, 2));
    console.log('Data saved to chapters.json');
  } catch (error) {
    console.error('Error fetching or processing data:', error.message);
  }
}

transformChapters();
