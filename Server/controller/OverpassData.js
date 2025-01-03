const axios = require('axios');

// Hàm lấy dữ liệu từ Overpass API theo phạm vi
const overpassData = async (lat, lng, radius) => {
    // Tính toán phạm vi bbox từ bán kính (theo đơn vị mét)
    const earthRadius = 6371000; // Bán kính Trái Đất tính theo mét
    const latDiff = (radius / earthRadius) * (180 / Math.PI);
    const lngDiff = (radius / earthRadius) * (180 / Math.PI) / Math.cos(lat * Math.PI / 180);

    const minLat = lat - latDiff;
    const maxLat = lat + latDiff;
    const minLng = lng - lngDiff;
    const maxLng = lng + lngDiff;

    const overpassQuery = `
        [out:json];
        (
            way["highway"~"primary|secondary|tertiary|residential"](${minLat},${minLng},${maxLat},${maxLng});
            node(w);
        );
        out body;
    `;

    try {
        const response = await axios.post('https://overpass-api.de/api/interpreter', overpassQuery, {
            headers: {
                'Content-Type': 'text/plain',
            },
        });
        return response.data.elements;
    } catch (error) {
        console.error('Error fetching data from Overpass API:', error.message);
        throw new Error('Unable to fetch Overpass data.');
    }
};

module.exports = overpassData