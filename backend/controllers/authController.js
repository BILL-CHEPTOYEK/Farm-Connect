// backend/controllers/authController.js
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');

// Generate JWT token
const generateToken = (userId, userType) => {
    return jwt.sign(
        { userId, userType },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
    );
};

// Register new user
const register = async (req, res) => {
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

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
        const existingUser = await client.query(
            'SELECT id FROM users WHERE phone_number = $1',
            [phone_number]
        );

        if (existingUser.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({
                success: false,
                message: 'User with this phone number already exists'
            });
        }

        // Hash password if provided (not required for USSD-only farmers)
        let password_hash = null;
        if (password) {
            password_hash = await bcrypt.hash(password, 12);
        }

        // Insert new user
        const insertQuery = `
      INSERT INTO users (
        phone_number, name, email, user_type, password_hash,
        district, subcounty, parish, village, farm_size,
        specialization, business_license, vehicle_type, vehicle_registration,
        is_verified
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      RETURNING id, phone_number, name, email, user_type, district, created_at
    `;

        const result = await client.query(insertQuery, [
            phone_number, name, email, user_type, password_hash,
            district, subcounty, parish, village, farm_size,
            specialization, business_license, vehicle_type, vehicle_registration,
            true // Auto-verify for now, implement SMS verification later
        ]);

        await client.query('COMMIT');

        const user = result.rows[0];
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
        await client.query('ROLLBACK');
        console.error('Registration error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error during registration'
        });
    } finally {
        client.release();
    }
};

// User login
const login = async (req, res) => {
    try {
        const { phone_number, password } = req.body;

        // Find user by phone number
        const userQuery = `
      SELECT id, phone_number, name, email, user_type, password_hash, is_verified, is_active
      FROM users 
      WHERE phone_number = $1
    `;

        const result = await pool.query(userQuery, [phone_number]);

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Invalid phone number or password'
            });
        }

        const user = result.rows[0];

        // Check if user is active and verified
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

        // Check password
        if (!user.password_hash || !await bcrypt.compare(password, user.password_hash)) {
            return res.status(401).json({
                success: false,
                message: 'Invalid phone number or password'
            });
        }

        // Generate token
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

        const userQuery = `
      SELECT 
        id, phone_number, name, email, user_type, district, subcounty, 
        parish, village, farm_size, specialization, business_license,
        vehicle_type, vehicle_registration, profile_image_url, created_at
      FROM users 
      WHERE id = $1
    `;

        const result = await pool.query(userQuery, [userId]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        res.json({
            success: true,
            data: { user: result.rows[0] }
        });

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
        const {
            name,
            email,
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

        const updateQuery = `
      UPDATE users SET
        name = COALESCE($1, name),
        email = COALESCE($2, email),
        district = COALESCE($3, district),
        subcounty = COALESCE($4, subcounty),
        parish = COALESCE($5, parish),
        village = COALESCE($6, village),
        farm_size = COALESCE($7, farm_size),
        specialization = COALESCE($8, specialization),
        business_license = COALESCE($9, business_license),
        vehicle_type = COALESCE($10, vehicle_type),
        vehicle_registration = COALESCE($11, vehicle_registration),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $12
      RETURNING id, name, email, district, subcounty, parish, village
    `;

        const result = await pool.query(updateQuery, [
            name, email, district, subcounty, parish, village,
            farm_size, specialization, business_license, vehicle_type,
            vehicle_registration, userId
        ]);

        res.json({
            success: true,
            message: 'Profile updated successfully',
            data: { user: result.rows[0] }
        });

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
