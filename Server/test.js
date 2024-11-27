const axios = require('axios');

async function getIpLocation() {
  try {
    const response = await axios.get('http://ip-api.com/json');
    const { lat, lon } = response.data;
    console.log(`Latitude: ${lat}, Longitude: ${lon}`);
  } catch (error) {
    console.error('Error fetching IP location:', error.message);
  }
}

getIpLocation();
