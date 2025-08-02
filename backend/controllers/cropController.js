/**
 * Crop Controller for SebeiConnect
 * Handles crop listing, searching, and management
 */

const { Crop, User, FarmerListing, Review } = require('../models');

// Get all crops with pagination and filtering
const getAllCrops = async (req, res) => {
    try {
        const {
            page = 1,
            limit = 20,
            category,
            location,
            search,
            minPrice,
            maxPrice,
            sortBy = 'created_at',
            sortOrder = 'DESC'
        } = req.query;

        const offset = (page - 1) * limit;
        let whereConditions = {};
        let include = [
            {
                model: FarmerListing,
                include: [
                    {
                        model: User,
                        attributes: ['name', 'phone_number', 'is_verified'],
                    }
                ]
            }
        ];

        // Add search filter
        if (search) {
            whereConditions[Op.or] = [
                { name: { [Op.iLike]: `%${search}%` } },
                { '$FarmerListings.User.name$': { [Op.iLike]: `%${search}%` } },
                { location: { [Op.iLike]: `%${search}%` } }
            ];
        }

        // Add category filter
        if (category && category !== 'all') {
            whereConditions.category = category;
        }

        // Add location filter
        if (location) {
            whereConditions.location = { [Op.iLike]: `%${location}%` };
        }

        // Add price range filter
        if (minPrice) {
            whereConditions.price_per_unit = { [Op.gte]: minPrice };
        }

        if (maxPrice) {
            whereConditions.price_per_unit = { [Op.lte]: maxPrice };
        }

        // corrected sortBy to use correct column name
        const validSortBy = ['createdAt', 'updatedAt', 'name', 'category'].includes(sortBy) ? sortBy : 'createdAt';
        const result = await Crop.findAndCountAll({
            where: whereConditions,
            include,
            order: [[validSortBy, sortOrder]],
            limit,
            offset
        });

        res.json({
            success: true,
            data: result.rows,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total: result.count,
                pages: Math.ceil(result.count / limit)
            }
        });
    } catch (error) {
        console.error('Error fetching crops:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch crops'
        });
    }
};

// Get single crop by ID
const getCropById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await Crop.findOne({
            where: { id },
            include: [
                {
                    model: User,
                    as: 'farmer',
                    attributes: ['name', 'phone', 'email', 'location', 'verified']
                },
                {
                    model: Review,
                    as: 'reviews',
                    attributes: ['id']
                }
            ]
        });

        if (!result) {
            return res.status(404).json({
                success: false,
                message: 'Crop not found'
            });
        }

        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        console.error('Error fetching crop:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch crop'
        });
    }
};

// Create new crop listing
const createCrop = async (req, res) => {
    try {
        const {
            name,
            category,
            description,
            price_per_unit,
            unit,
            quantity_available,
            location,
            harvest_date,
            expiry_date,
            organic,
            quality_grade
        } = req.body;

        const farmer_id = req.user.id;

        const crop = await Crop.create({
            farmer_id,
            name,
            category,
            description,
            price_per_unit,
            unit,
            quantity_available,
            location,
            harvest_date,
            expiry_date,
            organic: organic || false,
            quality_grade: quality_grade || 'standard',
            status: 'available'
        });

        res.status(201).json({
            success: true,
            message: 'Crop listed successfully',
            data: crop
        });
    } catch (error) {
        console.error('Error creating crop:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create crop listing'
        });
    }
};

// Update crop listing
const updateCrop = async (req, res) => {
    try {
        const { id } = req.params;
        const farmer_id = req.user.id;
        const updateFields = req.body;

        // Check if crop belongs to the farmer
        const crop = await Crop.findOne({ where: { id } });

        if (!crop) {
            return res.status(404).json({
                success: false,
                message: 'Crop not found'
            });
        }

        if (crop.farmer_id !== farmer_id) {
            return res.status(403).json({
                success: false,
                message: 'You can only update your own crops'
            });
        }

        // Update crop
        await Crop.update(updateFields, { where: { id } });

        const updatedCrop = await Crop.findByPk(id);

        res.json({
            success: true,
            message: 'Crop updated successfully',
            data: updatedCrop
        });
    } catch (error) {
        console.error('Error updating crop:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update crop'
        });
    }
};

// Delete crop listing
const deleteCrop = async (req, res) => {
    try {
        const { id } = req.params;
        const farmer_id = req.user.id;

        // Check if crop belongs to the farmer
        const crop = await Crop.findOne({ where: { id } });

        if (!crop) {
            return res.status(404).json({
                success: false,
                message: 'Crop not found'
            });
        }

        if (crop.farmer_id !== farmer_id) {
            return res.status(403).json({
                success: false,
                message: 'You can only delete your own crops'
            });
        }

        // Soft delete (update status to 'deleted')
        await Crop.update({ status: 'deleted' }, { where: { id } });

        res.json({
            success: true,
            message: 'Crop deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting crop:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete crop'
        });
    }
};

// Get farmer's crops
const getFarmerCrops = async (req, res) => {
    try {
        const farmer_id = req.user.id;
        const { status = 'available' } = req.query;

        const result = await Crop.findAll({
            where: { farmer_id, status },
            include: [
                {
                    model: Order,
                    as: 'orders',
                    attributes: ['id', 'status', 'total_amount'],
                    required: false
                }
            ],
            order: [['created_at', 'DESC']]
        });

        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        console.error('Error fetching farmer crops:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch your crops'
        });
    }
};

// Get crop categories with counts
const getCropCategories = async (req, res) => {
    try {
        const result = await Crop.findAll({
            attributes: ['category', [db.fn('COUNT', db.col('id')), 'count']],
            where: { status: 'available' },
            group: ['category'],
            order: [[db.fn('COUNT', db.col('id')), 'DESC']]
        });

        const categories = [
            { id: 'all', name: 'All Crops', count: result.reduce((sum, cat) => sum + parseInt(cat.count), 0) },
            ...result.map(row => ({
                id: row.category,
                name: row.category.charAt(0).toUpperCase() + row.category.slice(1),
                count: parseInt(row.count)
            }))
        ];

        res.json({
            success: true,
            data: categories
        });
    } catch (error) {
        console.error('Error fetching categories:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch categories'
        });
    }
};

module.exports = {
    getAllCrops,
    getCropById,
    createCrop,
    updateCrop,
    deleteCrop,
    getFarmerCrops,
    getCropCategories
};
