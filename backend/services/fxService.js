// backend/services/fxService.js
const puppeteer = require('puppeteer');

const scrapeBOJRates = async () => {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const page = await browser.newPage();
  try {
    await page.goto('https://www.boj.org.jm/', { waitUntil: 'networkidle2' });
    
    // Select the rates from the table (selector depends on BOJ site structure)
    const rates = await page.evaluate(() => {
      // This is a placeholder logic. Real BOJ site scraping requires finding exact selectors.
      const usdSell = document.querySelector('.usd-sell')?.innerText || '155.00';
      const cadSell = document.querySelector('.cad-sell')?.innerText || '115.00';
      const gbpSell = document.querySelector('.gbp-sell')?.innerText || '195.00';
      
      return {
        USD: parseFloat(usdSell.replace(/[^0-9.]/g, '')),
        CAD: parseFloat(cadSell.replace(/[^0-9.]/g, '')),
        GBP: parseFloat(gbpSell.replace(/[^0-9.]/g, '')),
      };
    });

    return rates;
  } catch (error) {
    console.error('Error scraping BOJ rates:', error);
    // Fallback to cached rates from database or hardcoded defaults
    return { USD: 155.20, CAD: 114.50, GBP: 198.10 };
  } finally {
    await browser.close();
  }
};

module.exports = { scrapeBOJRates };
