const mongoose = require('mongoose')

const connectDB = async()=>{
    try {
        if (!process.env.MONGODB_URI) {
            throw new Error('MONGODB_URI is undefined');
        }
        await mongoose.connect(process.env.MONGODB_URI)
        console.log('Connected to MongoDB successfully');
    } catch (error) {
        console.log("Error connecting to MongoDB: " + error.message || error);
    }
}

module.exports = connectDB