// backend/controllers/authController.js
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User } = require('../models');

const generateToken = (userId, userType) => {
    return jwt.sign(
        { userId, userType },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
    );
};

// Register new user
const register = async (req, res) => {
    try {
        const {
            phone_number,
            name,
            email,
            user_type,
            password,
            district,
            subcounty,
            parish,
            village,
            farm_size,
            specialization,
            business_license,
            vehicle_type,
            vehicle_registration
        } = req.body;

        // Check if user already exists
        const existingUser = await User.findOne({ where: { phone_number } });
        if (existingUser) {
            return res.status(400).json({
                success: false,
                message: 'User with this phone number already exists'
            });
        }

        // Hash password if provided
        let password_hash = null;
        if (password) {
            password_hash = await bcrypt.hash(password, 12);
        }

        // Create new user
        const user = await User.create({
            phone_number,
            name,
            email,
            user_type,
            password_hash,
            district,
            subcounty,
            parish,
            village,
            farm_size,
            specialization,
            business_license,
            vehicle_type,
            vehicle_registration,
            is_verified: true // Auto-verify for now
        });

        const token = generateToken(user.id, user.user_type);

        res.status(201).json({
            success: true,
            message: 'User registered successfully',
            data: {
                user: {
                    id: user.id,
                    phone_number: user.phone_number,
                    name: user.name,
                    email: user.email,
                    user_type: user.user_type,
                    district: user.district
                },
                token
            }
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error during registration'
        });
    }
};

// User login
const login = async (req, res) => {
    try {
        const { phone_number, password } = req.body;
        const user = await User.findOne({ where: { phone_number } });
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Invalid phone number or password'
            });
        }
        if (!user.is_active) {
            return res.status(401).json({
                success: false,
                message: 'Account is deactivated. Please contact support.'
            });
        }
        if (!user.is_verified) {
            return res.status(401).json({
                success: false,
                message: 'Account not verified. Please verify your phone number.'
            });
        }
        if (!user.password_hash || !await bcrypt.compare(password, user.password_hash)) {
            return res.status(401).json({
                success: false,
                message: 'Invalid phone number or password'
            });
        }
        const token = generateToken(user.id, user.user_type);
        res.json({
            success: true,
            message: 'Login successful',
            data: {
                user: {
                    id: user.id,
                    phone_number: user.phone_number,
                    name: user.name,
                    email: user.email,
                    user_type: user.user_type
                },
                token
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error during login'
        });
    }
};

// Get current user profile
const getProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const user = await User.findByPk(userId);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }
        res.json({ success: true, data: { user } });
    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
};

// Update user profile
const updateProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const updates = req.body;
        const [updated] = await User.update(updates, { where: { id: userId } });
        if (updated) {
            const user = await User.findByPk(userId);
            res.json({ success: true, message: 'Profile updated successfully', data: { user } });
        } else {
            res.status(404).json({ success: false, message: 'User not found' });
        }
    } catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
};

module.exports = {
    register,
    login,
    getProfile,
    updateProfile
};
