const UserModel = require('../../models/user.model')
const bcryptjs = require('bcryptjs')
const jwt = require('jsonwebtoken')

async function registerUser(req, res){
    try {
        const {username, email, password, profile} = req.body

        const checkEmail = await UserModel.findOne({email})

        if(checkEmail){
            return res.status(400).json({
                message: 'Already user exit',
                error: true
            })
        }

        const salt = await bcryptjs.genSalt(10);
        const hashedPassword = await bcryptjs.hash(password, salt);

        const payload = {
            username,
            email,
            profile,
            password: hashedPassword
        }

        const user = new UserModel(payload)
        const userSave = await user.save()

        return res.status(201).json({
            message:"create successfully",
            data: userSave,
            success: true
        })
    } catch (error) {
        return res.status(500).json({
            message: error.message || error,
            error:true
        })
    }
}

async function checkPassword(req,res) {
    try {
        const { password, userId } = req.body

        const user = await UserModel.findById(userId)

        const verifyPassword = await bcryptjs.compare(password, user.password)

        if(!verifyPassword){
            return res.status(400).json({
                message:"Check password",
                error: true
            })
        }

        const tokenData = {
            id: user._id,
            email: user.email
        }
        const token = await jwt.sign(tokenData, process.env.JWT_SECREAT_KEY,{expiresIn:'1d'})

        const cookieOptions = {
            http: true,
            secure: true
        }

        return res.cookie('token', token, cookieOptions).status(200).json({
            message:"Login successfully",
            token: token,
            success: true
        })
    } catch (error) {
        return res.status(500).json({
            message: error.message || error,
            error:true
        })
    }
}

module.exports = {registerUser, checkPassword}