const mongoose = require("mongoose");

const articleSchema = new mongoose.Schema(
  {
    user: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: "User" 
    },
    description: { 
      type: String, 
      max: 500 
    },
    imgurl: { 
      type: String 
    },
    likes: [{ 
      type: mongoose.Schema.Types.ObjectId, 
      ref: "User" 
    }],
    comment: [{ 
      type: mongoose.Schema.Types.ObjectId, 
      ref: "Comment" 
    }],
  },
  { timestamps: true }
);

const ArticleModel = mongoose.model("Article", articleSchema);
module.exports = ArticleModel;