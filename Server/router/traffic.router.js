const express = require('express');
const { getAllTrafficData, getTrafficDataByCoordinates, getTrafficDataByGrid } = require('../controller/traffic/traffic.controller');

const router = express.Router();

router.get('/all', async (req, res) => {
    const { page = 1, limit = 20 } = req.query;
    try {
        const data = await getAllTrafficData(parseInt(page), parseInt(limit));
        res.json({ data, page, limit });
    } catch (error) {
        res.status(500).send({ error: 'Lỗi khi lấy dữ liệu giao thông.' });
    }
});

router.get('/trafficMy', async (req, res) => {
    const { latitude, longitude, provinces } = req.query;
    if (!latitude || !longitude || !provinces) {
        return res.status(400).send({ error: 'Cần cung cấp đầy đủ thông tin tọa độ và danh sách tỉnh.' });
    }

    try {
        const data = await getTrafficDataByCoordinates(parseFloat(latitude), parseFloat(longitude), JSON.parse(provinces));
        res.json(data);
    } catch (error) {
        res.status(500).send({ error: 'Lỗi khi lấy dữ liệu giao thông theo tọa độ.' });
    }
});

router.get('/grid', async (req, res) => {
    const { province, page = 1, limit = 20 } = req.query;

    if (!province) {
        return res.status(400).send({ error: 'Cần cung cấp tỉnh.' });
    }

    try {
        const data = await getTrafficDataByGrid(province, parseInt(page), parseInt(limit));
        res.json({ data, page, limit });
    } catch (error) {
        res.status(500).send({ error: 'Lỗi khi lấy dữ liệu giao thông theo lưới.' });
    }
});

module.exports = router;
