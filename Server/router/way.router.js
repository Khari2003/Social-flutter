const express = require('express');
const wayIndex = require('../controller/way.controller')

const router = express.Router();

router.get('/way', wayIndex)

module.exports = router;