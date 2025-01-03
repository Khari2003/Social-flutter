const express = require('express');

const {getAllStores, postCreateStore, getAllStoresInArena} = require('../controller/location.controller')

const router = express.Router();

router.get('/getall', getAllStores)
router.post('/createStore', postCreateStore)
router.get('/storesinarena', getAllStoresInArena)

module.exports = router;