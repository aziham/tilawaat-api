import fs from 'fs/promises';
import path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';

// Convert exec to promise-based
const execPromise = promisify(exec);

// Parse command line arguments
const args = process.argv.slice(2);
const isTestMode = args.includes('--test');
const useAria = args.includes('--aria2c');

// Read the recitations data
const loadRecitations = async () => {
  const data = await fs.readFile('../../endpoint/recitations.json', 'utf8');
  return JSON.parse(data);
};

// Create directory if it doesn't exist
const ensureDir = async (dirPath) => {
  try {
    await fs.access(dirPath);
  } catch (error) {
    await fs.mkdir(dirPath, { recursive: true });
  }
};

// Download MP3 file using aria2c
const downloadMP3WithAria = async (url, filePath) => {
  try {
    const command = `aria2c "${url}" -d "${path.dirname(
      filePath
    )}" -o "${path.basename(
      filePath
    )}" --connect-timeout=30 --retry-wait=2 --max-tries=5 --quiet`;

    console.log(`Starting aria2c download: ${url}`);
    await execPromise(command);
    console.log(`Downloaded with aria2c: ${filePath}`);
  } catch (error) {
    console.error(`Error downloading with aria2c ${url}: ${error.message}`);
  }
};

// Download MP3 file using fetch
const downloadMP3WithFetch = async (url, filePath) => {
  try {
    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(
        `Failed to fetch ${url}: ${response.status} ${response.statusText}`
      );
    }

    const buffer = await response.arrayBuffer();
    await fs.writeFile(filePath, Buffer.from(buffer));
    console.log(`Downloaded: ${filePath}`);
  } catch (error) {
    console.error(`Error downloading ${url}: ${error.message}`);
  }
};

// Download MP3 file using the selected method
const downloadMP3 = async (url, filePath) => {
  if (useAria) {
    return downloadMP3WithAria(url, filePath);
  } else {
    return downloadMP3WithFetch(url, filePath);
  }
};

// Main function
const downloadAllRecitations = async () => {
  try {
    const recitations = await loadRecitations();

    if (isTestMode) {
      console.log(
        'Running in TEST MODE - downloading only selected chapters per recitation'
      );
    }

    if (useAria) {
      console.log('Using aria2c for downloads');

      // Check if aria2c is installed
      try {
        await execPromise('aria2c --version');
      } catch (error) {
        console.error(
          'Error: aria2c is not installed or not in PATH. Please install aria2c to use the --aria2c flag.'
        );
        process.exit(1);
      }
    }

    for (const recitation of recitations) {
      const recitationId = recitation.id;
      const server = recitation.server;
      const chapters = recitation.available_chapters;

      // Create directory for this recitation
      const recitationDir = path.join(
        './recitations',
        recitationId.toString(),
        'waveforms'
      );
      await ensureDir(recitationDir);

      // In test mode, download specific test chapters (1, 99, 114) if available
      const chaptersToDownload = isTestMode
        ? [1, 99, 114].filter((id) => chapters.includes(id))
        : chapters;

      // Download each chapter MP3
      for (const chapterId of chaptersToDownload) {
        // Format chapter ID with leading zeros (e.g., 001, 099, 114)
        const paddedChapterId = chapterId.toString().padStart(3, '0');
        const mp3Url = `${server}${paddedChapterId}.mp3`;
        const outputPath = path.join(recitationDir, `${paddedChapterId}.mp3`);

        // Check if file already exists to avoid re-downloading
        try {
          await fs.access(outputPath);
          console.log(`Skipping (already exists): ${outputPath}`);
        } catch {
          await downloadMP3(mp3Url, outputPath);

          // Add a small delay to avoid overwhelming the server
          await new Promise((resolve) => setTimeout(resolve, 100));
        }
      }

      console.log(`Completed recitation ID: ${recitationId}`);
    }

    console.log('All downloads completed');
    if (isTestMode) {
      console.log('Test mode completed successfully');
    }
  } catch (error) {
    console.error('Error in main process:', error);
  }
};

// Run the download process
downloadAllRecitations();
