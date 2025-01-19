const express = require('express');
const cors = require('cors');
const connectDb = require('./config/connectDB');
const StoreRouter = require('./router/store.router')
const TrafficRouter = require('./router/traffic.router')
const cookieParser = require('cookie-parser');

require('dotenv').config();

const app = express();

// Kết nối đến MongoDB Atlas
connectDb();

// Cấu hình CORS
app.use(cors({
    origin: '*',  
    credentials: true  
}));

app.use(express.json());
app.use(cookieParser());

const PORT = process.env.PORT || 4000;

app.get('/', (req, res) => {
    res.json({
        message: "Server running"
    });
});

app.use('/store', StoreRouter);
app.use('/traffic', TrafficRouter);

// Xử lý các yêu cầu preflight
app.options('*', cors());

// Kết nối database và khởi động server

app.listen(PORT, '0.0.0.0',() => {
    console.log("Server:" + PORT);
});

