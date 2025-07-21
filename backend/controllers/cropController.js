/**
 * Crop Controller for SebeiConnect
 * Handles crop listing, searching, and management
 */

const db = require('../config/database');

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
        let whereConditions = ['c.status = $1'];
        let params = ['available'];
        let paramIndex = 2;

        // Add search filter
        if (search) {
            whereConditions.push(`(c.name ILIKE $${paramIndex} OR u.name ILIKE $${paramIndex} OR c.location ILIKE $${paramIndex})`);
            params.push(`%${search}%`);
            paramIndex++;
        }

        // Add category filter
        if (category && category !== 'all') {
            whereConditions.push(`c.category = $${paramIndex}`);
            params.push(category);
            paramIndex++;
        }

        // Add location filter
        if (location) {
            whereConditions.push(`c.location ILIKE $${paramIndex}`);
            params.push(`%${location}%`);
            paramIndex++;
        }

        // Add price range filter
        if (minPrice) {
            whereConditions.push(`c.price_per_unit >= $${paramIndex}`);
            params.push(minPrice);
            paramIndex++;
        }

        if (maxPrice) {
            whereConditions.push(`c.price_per_unit <= $${paramIndex}`);
            params.push(maxPrice);
            paramIndex++;
        }

        const whereClause = whereConditions.join(' AND ');

        // Add pagination params
        params.push(limit, offset);

        const query = `
      SELECT 
        c.*,
        u.name as farmer_name,
        u.phone as farmer_phone,
        u.verified as farmer_verified,
        COALESCE(AVG(r.rating), 0) as avg_rating,
        COUNT(r.id) as review_count
      FROM crops c
      LEFT JOIN users u ON c.farmer_id = u.id
      LEFT JOIN reviews r ON u.id = r.reviewed_user_id
      WHERE ${whereClause}
      GROUP BY c.id, u.id
      ORDER BY ${sortBy} ${sortOrder}
      LIMIT $${paramIndex - 1} OFFSET $${paramIndex}
    `;

        const result = await db.query(query, params);

        // Get total count for pagination
        const countQuery = `
      SELECT COUNT(DISTINCT c.id) as total
      FROM crops c
      LEFT JOIN users u ON c.farmer_id = u.id
      WHERE ${whereClause}
    `;
        const countResult = await db.query(countQuery, params.slice(0, -2));
        const total = parseInt(countResult.rows[0].total);

        res.json({
            success: true,
            data: {
                crops: result.rows,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
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

        const query = `
      SELECT 
        c.*,
        u.name as farmer_name,
        u.phone as farmer_phone,
        u.email as farmer_email,
        u.location as farmer_location,
        u.verified as farmer_verified,
        COALESCE(AVG(r.rating), 0) as avg_rating,
        COUNT(r.id) as review_count
      FROM crops c
      LEFT JOIN users u ON c.farmer_id = u.id
      LEFT JOIN reviews r ON u.id = r.reviewed_user_id
      WHERE c.id = $1
      GROUP BY c.id, u.id
    `;

        const result = await db.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Crop not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
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

        const query = `
      INSERT INTO crops (
        farmer_id, name, category, description, price_per_unit, unit,
        quantity_available, location, harvest_date, expiry_date,
        organic, quality_grade, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *
    `;

        const values = [
            farmer_id, name, category, description, price_per_unit, unit,
            quantity_available, location, harvest_date, expiry_date,
            organic || false, quality_grade || 'standard', 'available'
        ];

        const result = await db.query(query, values);

        res.status(201).json({
            success: true,
            message: 'Crop listed successfully',
            data: result.rows[0]
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
        const checkQuery = 'SELECT farmer_id FROM crops WHERE id = $1';
        const checkResult = await db.query(checkQuery, [id]);

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Crop not found'
            });
        }

        if (checkResult.rows[0].farmer_id !== farmer_id) {
            return res.status(403).json({
                success: false,
                message: 'You can only update your own crops'
            });
        }

        // Build dynamic update query
        const allowedFields = [
            'name', 'category', 'description', 'price_per_unit', 'unit',
            'quantity_available', 'location', 'harvest_date', 'expiry_date',
            'organic', 'quality_grade', 'status'
        ];

        const updates = [];
        const values = [];
        let paramIndex = 1;

        Object.keys(updateFields).forEach(field => {
            if (allowedFields.includes(field)) {
                updates.push(`${field} = $${paramIndex}`);
                values.push(updateFields[field]);
                paramIndex++;
            }
        });

        if (updates.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No valid fields to update'
            });
        }

        updates.push(`updated_at = NOW()`);
        values.push(id);

        const query = `
      UPDATE crops 
      SET ${updates.join(', ')}
      WHERE id = $${paramIndex}
      RETURNING *
    `;

        const result = await db.query(query, values);

        res.json({
            success: true,
            message: 'Crop updated successfully',
            data: result.rows[0]
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
        const checkQuery = 'SELECT farmer_id FROM crops WHERE id = $1';
        const checkResult = await db.query(checkQuery, [id]);

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Crop not found'
            });
        }

        if (checkResult.rows[0].farmer_id !== farmer_id) {
            return res.status(403).json({
                success: false,
                message: 'You can only delete your own crops'
            });
        }

        // Soft delete (update status to 'deleted')
        const query = 'UPDATE crops SET status = $1, updated_at = NOW() WHERE id = $2';
        await db.query(query, ['deleted', id]);

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

        const query = `
      SELECT 
        c.*,
        COUNT(o.id) as order_count,
        SUM(CASE WHEN o.status = 'completed' THEN o.total_amount ELSE 0 END) as total_earnings
      FROM crops c
      LEFT JOIN orders o ON c.id = o.crop_id
      WHERE c.farmer_id = $1 AND c.status = $2
      GROUP BY c.id
      ORDER BY c.created_at DESC
    `;

        const result = await db.query(query, [farmer_id, status]);

        res.json({
            success: true,
            data: result.rows
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
        const query = `
      SELECT 
        category,
        COUNT(*) as count
      FROM crops
      WHERE status = 'available'
      GROUP BY category
      ORDER BY count DESC
    `;

        const result = await db.query(query);

        const categories = [
            { id: 'all', name: 'All Crops', count: result.rows.reduce((sum, cat) => sum + parseInt(cat.count), 0) },
            ...result.rows.map(row => ({
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
