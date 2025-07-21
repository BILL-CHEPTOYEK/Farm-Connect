/**
 * Validation middleware for SebeiConnect API
 * Uses Joi for input validation
 */

const Joi = require('joi');

// User registration validation schema
const userRegistrationSchema = Joi.object({
    name: Joi.string().min(2).max(100).required(),
    phone_number: Joi.string()
        .pattern(/^\+256[0-9]{9}$/)
        .required()
        .messages({
            'string.pattern.base': 'Phone number must be in format +256XXXXXXXXX'
        }),
    email: Joi.string().email().optional(),
    password: Joi.string()
        .min(6)
        .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
        .required()
        .messages({
            'string.min': 'Password must be at least 6 characters long',
            'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, and one number'
        }),
    user_type: Joi.string().valid('farmer', 'buyer', 'agent', 'delivery_agent').required(),
    location: Joi.string().min(2).max(100).required(),

    // Optional fields based on user type
    farm_size: Joi.number().positive().optional(),
    specialization: Joi.array().items(Joi.string()).optional(),
    business_license: Joi.string().max(100).optional(),
    vehicle_type: Joi.string().max(50).optional(),
    vehicle_registration: Joi.string().max(50).optional()
});

// User login validation schema
const userLoginSchema = Joi.object({
    phone_number: Joi.string()
        .pattern(/^\+256[0-9]{9}$/)
        .required(),
    password: Joi.string().required()
});

// Crop validation schema
const cropSchema = Joi.object({
    name: Joi.string().min(2).max(100).required(),
    category: Joi.string().valid('grains', 'vegetables', 'fruits', 'tubers', 'legumes', 'other').required(),
    description: Joi.string().max(1000),
    price_per_unit: Joi.number().positive().required(),
    unit: Joi.string().valid('kg', 'sack', 'bag', 'bunch', 'crate', 'piece', 'liter').required(),
    quantity_available: Joi.number().positive().required(),
    location: Joi.string().min(2).max(100).required(),
    harvest_date: Joi.date().max('now'),
    expiry_date: Joi.date().greater(Joi.ref('harvest_date')),
    organic: Joi.boolean(),
    quality_grade: Joi.string().valid('premium', 'grade_a', 'standard', 'grade_b')
});

// Order validation schema
const orderSchema = Joi.object({
    crop_id: Joi.number().integer().positive().required(),
    quantity: Joi.number().positive().required(),
    delivery_address: Joi.string().min(10).max(500).required(),
    delivery_date: Joi.date().greater('now').required(),
    message: Joi.string().max(500)
});

// Validation middleware for user registration
const validateRegister = (req, res, next) => {
    const { error } = userRegistrationSchema.validate(req.body);
    if (error) {
        return res.status(400).json({
            success: false,
            message: 'Validation error',
            errors: error.details.map(detail => detail.message)
        });
    }
    next();
};

// Validation middleware for user login
const validateLogin = (req, res, next) => {
    const { error } = userLoginSchema.validate(req.body);
    if (error) {
        return res.status(400).json({
            success: false,
            message: 'Validation error',
            errors: error.details.map(detail => detail.message)
        });
    }
    next();
};

// Validation middleware for crops
const validateCrop = (req, res, next) => {
    const { error } = cropSchema.validate(req.body);
    if (error) {
        return res.status(400).json({
            success: false,
            message: 'Validation error',
            errors: error.details.map(detail => detail.message)
        });
    }
    next();
};

// Validation middleware for orders
const validateOrder = (req, res, next) => {
    const { error } = orderSchema.validate(req.body);
    if (error) {
        return res.status(400).json({
            success: false,
            message: 'Validation error',
            errors: error.details.map(detail => detail.message)
        });
    }
    next();
};

module.exports = {
    validateRegister,
    validateLogin,
    validateCrop,
    validateOrder
};
