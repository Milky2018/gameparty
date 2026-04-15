#!/usr/bin/env node

const { chromium } = require('playwright');

const baseUrl = process.env.GAMEPARTY_WEB_BASE_URL || 'http://127.0.0.1:4173';
const smokeGames = (process.env.GAMEPARTY_WEB_SMOKE_GAMES ||
  'bejeweled,topdown_rogue_proto,celeste,mooncraft')
  .split(',')
  .map((game) => game.trim())
  .filter(Boolean);

async function assertGallery(page) {
  await page.goto(`${baseUrl}/index.html`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('a[href$=".html"]', { timeout: 15000 });
  for (const game of smokeGames) {
    const href = `./${game}.html`;
    const present = await page.locator(`a[href="${href}"]`).count();
    if (present === 0) {
      throw new Error(`Gallery is missing link for ${game}`);
    }
  }
}

async function assertGameBoot(page, game) {
  const pageErrors = [];
  const onPageError = (error) => {
    pageErrors.push(error.message);
  };
  page.on('pageerror', onPageError);

  await page.goto(`${baseUrl}/${game}.html`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#canvas', { timeout: 15000 });
  await page.waitForFunction(
    () => {
      const canvas = document.getElementById('canvas');
      return canvas instanceof HTMLCanvasElement &&
        canvas.width >= 512 &&
        canvas.height >= 288;
    },
    { timeout: 20000 },
  );

  if (pageErrors.length > 0) {
    throw new Error(`${game} raised page errors: ${pageErrors.join(' | ')}`);
  }

  const size = await page.evaluate(() => {
    const canvas = document.getElementById('canvas');
    return {
      width: canvas instanceof HTMLCanvasElement ? canvas.width : 0,
      height: canvas instanceof HTMLCanvasElement ? canvas.height : 0,
    };
  });
  console.log(`[web-smoke] ok ${game} ${size.width}x${size.height}`);
  page.off('pageerror', onPageError);
}

async function main() {
  const browser = await chromium.launch({
    headless: true,
    args: ['--enable-unsafe-webgpu'],
  });
  const page = await browser.newPage();
  try {
    await assertGallery(page);
    console.log(`[web-smoke] gallery ok ${baseUrl}`);
    for (const game of smokeGames) {
      await assertGameBoot(page, game);
    }
  } finally {
    await page.close();
    await browser.close();
  }
}

main().catch((error) => {
  console.error(`[web-smoke] ${error.stack || error.message}`);
  process.exitCode = 1;
});
