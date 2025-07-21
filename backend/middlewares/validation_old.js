// backend/middlewares/validation.js
const Joi = require('joi');

// Generic validation middleware
const validate = (schema, property = 'body') => {
    return (req, res, next) => {
        const { error } = schema.validate(req[property]);

        if (error) {
            return res.status(400).json({
                success: false,
                message: 'Validation error',
                errors: error.details.map(detail => ({
                    field: detail.path.join('.'),
                    message: detail.message
                }))
            });
        }

        next();
    };
};

// User registration validation schema
const userRegistrationSchema = Joi.object({
    phone_number: Joi.string()
        .pattern(/^\+256[0-9]{9}$/)
        .required()
        .messages({
            'string.pattern.base': 'Phone number must be in format +256XXXXXXXXX'
        }),
    name: Joi.string().min(2).max(100).required(),
    email: Joi.string().email().optional(),
    user_type: Joi.string().valid('farmer', 'agent', 'buyer', 'delivery_agent').required(),
    password: Joi.string().min(6).optional(), // Optional for USSD users
    district: Joi.string().max(50).required(),
    subcounty: Joi.string().max(50).optional(),
    parish: Joi.string().max(50).optional(),
    village: Joi.string().max(50).optional(),
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

// Farmer listing validation schema
const farmerListingSchema = Joi.object({
    crop_id: Joi.string().uuid().required(),
    quantity: Joi.number().positive().required(),
    unit_price: Joi.number().positive().optional(),
    quality_grade: Joi.string().valid('premium', 'standard', 'basic').default('standard'),
    harvest_date: Joi.date().optional(),
    expiry_date: Joi.date().greater(Joi.ref('harvest_date')).optional(),
    description: Joi.string().max(500).optional()
});

// Buyer order validation schema
const buyerOrderSchema = Joi.object({
    crop_id: Joi.string().uuid().required(),
    quantity_requested: Joi.number().positive().required(),
    max_price_per_unit: Joi.number().positive().optional(),
    total_budget: Joi.number().positive().optional(),
    delivery_location: Joi.string().max(200).required(),
    delivery_date: Joi.date().min('now').optional(),
    special_requirements: Joi.string().max(500).optional()
});

// Price alert validation schema
const priceAlertSchema = Joi.object({
    crop_id: Joi.string().uuid().required(),
    location: Joi.string().max(100).optional(),
    target_price: Joi.number().positive().required(),
    alert_condition: Joi.string().valid('above', 'below', 'equal').required()
});

// Review validation schema
const reviewSchema = Joi.object({
    reviewee_id: Joi.string().uuid().required(),
    order_match_id: Joi.string().uuid().optional(),
    delivery_id: Joi.string().uuid().optional(),
    rating: Joi.number().integer().min(1).max(5).required(),
    review_text: Joi.string().max(500).optional(),
    review_type: Joi.string().valid('farmer', 'buyer', 'agent', 'delivery').required()
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
    validate,
    userRegistrationSchema,
    userLoginSchema,
    farmerListingSchema,
    buyerOrderSchema,
    priceAlertSchema,
    reviewSchema,
    validateCrop,
    validateOrder
};
