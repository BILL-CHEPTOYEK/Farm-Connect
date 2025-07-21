/**
 * Order Routes for SebeiConnect API
 */

const express = require('express');
const router = express.Router();
const {
    createOrder,
    getUserOrders,
    getOrderById,
    updateOrderStatus,
    cancelOrder,
    getOrderStats
} = require('../controllers/orderController');
const auth = require('../middlewares/auth');
const { validateOrder } = require('../middlewares/validation');

// All order routes require authentication
router.use(auth);

// Order management
router.post('/', validateOrder, createOrder);
router.get('/', getUserOrders);
router.get('/stats', getOrderStats);
router.get('/:id', getOrderById);
router.put('/:id/status', updateOrderStatus);
router.put('/:id/cancel', cancelOrder);

module.exports = router;
