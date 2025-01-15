const express = require('express');

const {getAllStores, postCreateStore} = require('../controller/location.controller')

const router = express.Router();

router.get('/getall', getAllStores)
router.post('/createStore', postCreateStore)

module.exports = router;