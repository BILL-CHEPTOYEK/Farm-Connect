// backend/middlewares/auth.js
const jwt = require('jsonwebtoken');
const pool = require('../config/database');

// JWT Authentication middleware
const authenticateToken = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return res.status(401).json({
            success: false,
            message: 'Access denied. No token provided.'
        });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Get user details from database
        const userQuery = 'SELECT * FROM users WHERE id = $1 AND is_active = true';
        const userResult = await pool.query(userQuery, [decoded.userId]);

        if (userResult.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Invalid token. User not found or inactive.'
            });
        }

        req.user = userResult.rows[0];
        next();
    } catch (error) {
        console.error('Authentication error:', error);
        return res.status(403).json({
            success: false,
            message: 'Invalid or expired token.'
        });
    }
};

// Role-based authorization middleware
const authorizeRoles = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required.'
            });
        }

        if (!roles.includes(req.user.user_type)) {
            return res.status(403).json({
                success: false,
                message: `Access denied. Required roles: ${roles.join(', ')}`
            });
        }

        next();
    };
};

// Optional authentication (allows both authenticated and guest access)
const optionalAuth = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            const userQuery = 'SELECT * FROM users WHERE id = $1 AND is_active = true';
            const userResult = await pool.query(userQuery, [decoded.userId]);

            if (userResult.rows.length > 0) {
                req.user = userResult.rows[0];
            }
        } catch (error) {
            // Token is invalid, but we continue without user context
            console.log('Optional auth failed:', error.message);
        }
    }

    next();
};

module.exports = authenticateToken;
module.exports.authenticateToken = authenticateToken;
module.exports.authorizeRoles = authorizeRoles;
module.exports.optionalAuth = optionalAuth;
