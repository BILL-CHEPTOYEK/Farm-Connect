/**
 * Order Controller for SebeiConnect
 * Handles order creation, management, and tracking
 */

const db = require('../config/database');

// Create new order
const createOrder = async (req, res) => {
    try {
        const buyer_id = req.user.id;
        const {
            crop_id,
            quantity,
            delivery_address,
            delivery_date,
            message
        } = req.body;

        // Check if crop exists and has enough quantity
        const cropQuery = 'SELECT * FROM crops WHERE id = $1 AND status = $2';
        const cropResult = await db.query(cropQuery, [crop_id, 'available']);

        if (cropResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Crop not found or unavailable'
            });
        }

        const crop = cropResult.rows[0];

        if (crop.quantity_available < quantity) {
            return res.status(400).json({
                success: false,
                message: 'Insufficient quantity available'
            });
        }

        // Calculate total amount
        const total_amount = crop.price_per_unit * quantity;

        // Generate order number
        const orderNumber = `ORD-${Date.now()}-${Math.random().toString(36).substr(2, 5).toUpperCase()}`;

        // Create order
        const orderQuery = `
      INSERT INTO orders (
        order_number, buyer_id, farmer_id, crop_id, quantity,
        unit_price, total_amount, delivery_address, delivery_date,
        message, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *
    `;

        const orderValues = [
            orderNumber, buyer_id, crop.farmer_id, crop_id, quantity,
            crop.price_per_unit, total_amount, delivery_address, delivery_date,
            message, 'pending'
        ];

        const orderResult = await db.query(orderQuery, orderValues);

        // Update crop quantity
        const updateCropQuery = `
      UPDATE crops 
      SET quantity_available = quantity_available - $1,
          updated_at = NOW()
      WHERE id = $2
    `;
        await db.query(updateCropQuery, [quantity, crop_id]);

        res.status(201).json({
            success: true,
            message: 'Order created successfully',
            data: orderResult.rows[0]
        });
    } catch (error) {
        console.error('Error creating order:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create order'
        });
    }
};

// Get user's orders (buyer or farmer)
const getUserOrders = async (req, res) => {
    try {
        const user_id = req.user.id;
        const {
            role = 'buyer', // 'buyer' or 'farmer'
            status,
            page = 1,
            limit = 20
        } = req.query;

        const offset = (page - 1) * limit;
        let whereCondition = '';
        let params = [user_id];
        let paramIndex = 2;

        if (role === 'buyer') {
            whereCondition = 'o.buyer_id = $1';
        } else {
            whereCondition = 'o.farmer_id = $1';
        }

        if (status) {
            whereCondition += ` AND o.status = $${paramIndex}`;
            params.push(status);
            paramIndex++;
        }

        params.push(limit, offset);

        const query = `
      SELECT 
        o.*,
        c.name as crop_name,
        c.category as crop_category,
        c.unit as crop_unit,
        buyer.name as buyer_name,
        buyer.phone as buyer_phone,
        buyer.location as buyer_location,
        farmer.name as farmer_name,
        farmer.phone as farmer_phone,
        farmer.location as farmer_location
      FROM orders o
      LEFT JOIN crops c ON o.crop_id = c.id
      LEFT JOIN users buyer ON o.buyer_id = buyer.id
      LEFT JOIN users farmer ON o.farmer_id = farmer.id
      WHERE ${whereCondition}
      ORDER BY o.created_at DESC
      LIMIT $${paramIndex - 1} OFFSET $${paramIndex}
    `;

        const result = await db.query(query, params);

        // Get total count
        const countQuery = `
      SELECT COUNT(*) as total
      FROM orders o
      WHERE ${whereCondition}
    `;
        const countResult = await db.query(countQuery, params.slice(0, -2));
        const total = parseInt(countResult.rows[0].total);

        res.json({
            success: true,
            data: {
                orders: result.rows,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('Error fetching orders:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch orders'
        });
    }
};

// Get order by ID
const getOrderById = async (req, res) => {
    try {
        const { id } = req.params;
        const user_id = req.user.id;

        const query = `
      SELECT 
        o.*,
        c.name as crop_name,
        c.category as crop_category,
        c.unit as crop_unit,
        c.description as crop_description,
        buyer.name as buyer_name,
        buyer.phone as buyer_phone,
        buyer.email as buyer_email,
        buyer.location as buyer_location,
        farmer.name as farmer_name,
        farmer.phone as farmer_phone,
        farmer.email as farmer_email,
        farmer.location as farmer_location
      FROM orders o
      LEFT JOIN crops c ON o.crop_id = c.id
      LEFT JOIN users buyer ON o.buyer_id = buyer.id
      LEFT JOIN users farmer ON o.farmer_id = farmer.id
      WHERE o.id = $1 AND (o.buyer_id = $2 OR o.farmer_id = $2)
    `;

        const result = await db.query(query, [id, user_id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error fetching order:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch order'
        });
    }
};

// Update order status
const updateOrderStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, tracking_code } = req.body;
        const user_id = req.user.id;

        // Check if user is involved in this order
        const checkQuery = `
      SELECT * FROM orders 
      WHERE id = $1 AND (buyer_id = $2 OR farmer_id = $2)
    `;
        const checkResult = await db.query(checkQuery, [id, user_id]);

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        const order = checkResult.rows[0];

        // Validate status transitions
        const validTransitions = {
            'pending': ['confirmed', 'cancelled'],
            'confirmed': ['processing', 'cancelled'],
            'processing': ['in_transit', 'cancelled'],
            'in_transit': ['delivered'],
            'delivered': ['completed'],
            'cancelled': [],
            'completed': []
        };

        if (!validTransitions[order.status]?.includes(status)) {
            return res.status(400).json({
                success: false,
                message: `Cannot change status from ${order.status} to ${status}`
            });
        }

        // Update order
        let updateQuery = 'UPDATE orders SET status = $1, updated_at = NOW()';
        let params = [status];
        let paramIndex = 2;

        if (tracking_code) {
            updateQuery += `, tracking_code = $${paramIndex}`;
            params.push(tracking_code);
            paramIndex++;
        }

        if (status === 'delivered') {
            updateQuery += `, delivered_at = NOW()`;
        }

        updateQuery += ` WHERE id = $${paramIndex} RETURNING *`;
        params.push(id);

        const result = await db.query(updateQuery, params);

        res.json({
            success: true,
            message: 'Order status updated successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error updating order status:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update order status'
        });
    }
};

// Cancel order
const cancelOrder = async (req, res) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;
        const user_id = req.user.id;

        // Check if user can cancel this order
        const checkQuery = `
      SELECT * FROM orders 
      WHERE id = $1 AND (buyer_id = $2 OR farmer_id = $2)
    `;
        const checkResult = await db.query(checkQuery, [id, user_id]);

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        const order = checkResult.rows[0];

        // Check if order can be cancelled
        if (!['pending', 'confirmed', 'processing'].includes(order.status)) {
            return res.status(400).json({
                success: false,
                message: 'Order cannot be cancelled at this stage'
            });
        }

        // Cancel order and restore crop quantity
        const cancelQuery = `
      UPDATE orders 
      SET status = 'cancelled', 
          cancellation_reason = $1,
          cancelled_at = NOW(),
          updated_at = NOW()
      WHERE id = $2
      RETURNING *
    `;

        const result = await db.query(cancelQuery, [reason, id]);

        // Restore crop quantity
        const restoreQuery = `
      UPDATE crops 
      SET quantity_available = quantity_available + $1,
          updated_at = NOW()
      WHERE id = $2
    `;
        await db.query(restoreQuery, [order.quantity, order.crop_id]);

        res.json({
            success: true,
            message: 'Order cancelled successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error cancelling order:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to cancel order'
        });
    }
};

// Get order statistics
const getOrderStats = async (req, res) => {
    try {
        const user_id = req.user.id;
        const { role = 'buyer' } = req.query;

        let userCondition = role === 'buyer' ? 'buyer_id' : 'farmer_id';

        const statsQuery = `
      SELECT 
        COUNT(*) as total_orders,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_orders,
        COUNT(CASE WHEN status IN ('confirmed', 'processing', 'in_transit') THEN 1 END) as active_orders,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_orders,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_orders,
        COALESCE(SUM(CASE WHEN status = 'completed' THEN total_amount ELSE 0 END), 0) as total_earnings
      FROM orders
      WHERE ${userCondition} = $1
    `;

        const result = await db.query(statsQuery, [user_id]);

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error fetching order stats:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch order statistics'
        });
    }
};

module.exports = {
    createOrder,
    getUserOrders,
    getOrderById,
    updateOrderStatus,
    cancelOrder,
    getOrderStats
};
