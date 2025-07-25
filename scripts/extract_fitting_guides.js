const fs = require('fs');
const path = require('path');
const https = require('https');

const FITTING_GUIDES_API = 'https://payload.sojo.uk/api/fittingGuide';
const OUTPUT_FILE = path.join(__dirname, '..', 'extracted_data', 'fitting_guides.json');
const SERVICES_FILE = path.join(__dirname, '..', 'extracted_data', 'services.json');

// Helper function to make API requests with delay
function makeRequest(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      
      // Handle HTTP errors
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP Error: ${res.statusCode} - ${res.statusMessage}`));
        return;
      }

      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error(`JSON Parse Error: ${e.message}`));
        }
      });
    }).on('error', (e) => reject(new Error(`Network Error: ${e.message}`)));
  });
}

// Helper function to get fitting guide for a specific service
async function getFittingGuideForService(serviceId) {
  try {
    const url = `${FITTING_GUIDES_API}?limit=0&depth=100&where[service][equals]=${serviceId}`;
    return await makeRequest(url);
  } catch (error) {
    console.error(`Error fetching fitting guide for service ${serviceId}:`, error);
    throw error;
  }
}

// Add delay between requests
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function extractFittingGuides() {
  try {
    console.log('Reading services file...');
    if (!fs.existsSync(SERVICES_FILE)) {
      throw new Error(`Services file not found at: ${SERVICES_FILE}`);
    }

    // Read services file to get service IDs
    const servicesData = JSON.parse(fs.readFileSync(SERVICES_FILE, 'utf8'));
    if (!servicesData || !Array.isArray(servicesData.services)) {
      throw new Error('Invalid services data format');
    }

    const services = servicesData.services;
    console.log(`Found ${services.length} services`);

    // Object to store fitting guide information
    const fittingGuidesInfo = {
      totalServices: services.length,
      servicesWithGuides: 0,
      servicesWithoutGuides: 0,
      guides: {},
      serviceInfo: {}
    };

    // Fetch fitting guides for each service
    console.log(`Fetching fitting guides for ${services.length} services...`);
    
    for (let i = 0; i < services.length; i++) {
      const service = services[i];
      const serviceId = service.id;
      const serviceName = service.name || 'Unknown Service';

      console.log(`[${i + 1}/${services.length}] Processing ${serviceName} (${serviceId})...`);
      
      try {
        const guideData = await getFittingGuideForService(serviceId);
        
        // Store service info
        fittingGuidesInfo.serviceInfo[serviceId] = {
          name: serviceName,
          hasFittingGuide: guideData.docs && guideData.docs.length > 0,
          serviceType: service.serviceType || 'Unknown Type'
        };

        if (guideData.docs && guideData.docs.length > 0) {
          fittingGuidesInfo.guides[serviceId] = guideData.docs[0];
          fittingGuidesInfo.servicesWithGuides++;
          console.log(`✓ Found fitting guide for ${serviceName}`);
        } else {
          fittingGuidesInfo.servicesWithoutGuides++;
          console.log(`✗ No fitting guide for ${serviceName}`);
        }

        // Add a small delay between requests to avoid rate limiting
        await delay(100);
      } catch (error) {
        console.error(`Failed to fetch fitting guide for ${serviceName}:`, error);
        fittingGuidesInfo.servicesWithoutGuides++;
        fittingGuidesInfo.serviceInfo[serviceId].error = error.message;
        continue;
      }
    }

    // Write the data to a JSON file
    console.log('\nWriting fitting guides to file...');
    fs.writeFileSync(
      OUTPUT_FILE,
      JSON.stringify(fittingGuidesInfo, null, 2),
      'utf8'
    );

    console.log(`\nSummary:`);
    console.log(`Total services processed: ${fittingGuidesInfo.totalServices}`);
    console.log(`Services with fitting guides: ${fittingGuidesInfo.servicesWithGuides}`);
    console.log(`Services without fitting guides: ${fittingGuidesInfo.servicesWithoutGuides}`);
    console.log(`\nData saved to: ${OUTPUT_FILE}`);
  } catch (error) {
    console.error('Error in extractFittingGuides:', error);
    process.exit(1);
  }
}

extractFittingGuides(); 