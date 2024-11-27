const router = require('express').Router();
const path = require('path')

router.get('/find',(req,res)=>{
    res.sendFile(path.join(__dirname, '../view/find.html'));
})

module.exports = router