const mongoose = require('mongoose');
const PostSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    title:{
        type: String,
    },
    image: {
        type: String,
    },
    like:{
        type: Array,
    },
    comment:[
        {
            user: {
                type: mongoose.Schema.Types.ObjectId,
                required: true,
            },
            username: {
                type: String,
                required: true
            },
            profile:{
                type: String,
            },
            comment:{
                type: String,
                required: true
            }
        }
    ],
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now }
},{
    timestamps: true
})

module.exports = PostSchema.model('post', PostSchema)