const express = require('express');
const { updateTrafficDataVietnam, getAllTrafficData, getTrafficDataByCoordinates } = require('../controller/traffic.controller')

const router = express.Router();

// router.post('/update', updateTrafficDataVietnam)
router.get('/all', getAllTrafficData)
router.get('/trafficMy', getTrafficDataByCoordinates)

module.exports = router;