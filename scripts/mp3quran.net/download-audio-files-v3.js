import fs from 'fs';
import path from 'path';
import { promisify } from 'util';
import stream from 'stream';
import { argv } from 'process';

const pipeline = promisify(stream.pipeline);
const API_URL = 'https://www.mp3quran.net/api/v3/reciters?language=eng';
const RECITERS_FILE = path.join(process.cwd(), 'reciters.json'); // Cache file
const BASE_DIR = path.join(process.cwd(), 'reciters');

// Fetch reciters, using cache if available
async function fetchReciters() {
  if (fs.existsSync(RECITERS_FILE)) {
    console.log('Using cached reciters list...');
    return JSON.parse(fs.readFileSync(RECITERS_FILE, 'utf8')).reciters || [];
  } else {
    console.log('Fetching reciters list...');
    const response = await fetch(API_URL);
    const data = await response.json();
    fs.writeFileSync(RECITERS_FILE, JSON.stringify(data, null, 2)); // Cache the data
    return data.reciters || [];
  }
}

async function downloadFile(url, dest) {
  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`Failed to download ${url}`);
    await pipeline(res.body, fs.createWriteStream(dest));
    console.log(`Downloaded: ${dest}`);
  } catch (error) {
    console.error(`Error downloading ${url}:`, error.message);
  }
}

async function downloadReciterData(reciter, testMode, matchReciterMoshaf) {
  const reciterDir = path.join(BASE_DIR, String(reciter.id), 'waveforms');
  if (!fs.existsSync(reciterDir)) fs.mkdirSync(reciterDir, { recursive: true });

  for (const moshaf of reciter.moshaf) {
    if (matchReciterMoshaf && moshaf.id !== reciter.id) {
      continue;
    }

    const surahList = moshaf.surah_list.split(',');

    for (let surah of surahList) {
      const surahNum = surah.padStart(3, '0');
      const fileUrl = `${moshaf.server}${surahNum}.mp3`;
      const filePath = path.join(reciterDir, `${surahNum}.mp3`);

      if (!fs.existsSync(filePath)) {
        await downloadFile(fileUrl, filePath);
        if (testMode) break; // If test mode is on, only download the first MP3 and then break
      }
    }
  }
}

async function main() {
  const testMode = argv.includes('--test');
  const matchReciterMoshaf = argv.includes('--match-reciter-moshaf');

  const reciters = await fetchReciters();
  for (const reciter of reciters) {
    await downloadReciterData(reciter, testMode, matchReciterMoshaf);
  }

  console.log('All downloads completed.');
}

main().catch(console.error);
