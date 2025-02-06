const router = require("express").Router();
const authController = require("../controller/auth.controller");
const commentController = require("../controller/comment.controller");

router.post("/", authController.verify, commentController.addComment);
router.get("/:ArticleId", commentController.getbyPostId);

module.exports = router;
