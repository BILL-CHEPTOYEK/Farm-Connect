/**
 * Crop Routes for SebeiConnect API
 */

const express = require('express');
const router = express.Router();
const {
    getAllCrops,
    getCropById,
    createCrop,
    updateCrop,
    deleteCrop,
    getFarmerCrops,
    getCropCategories
} = require('../controllers/cropController');
const auth = require('../middlewares/auth');
const { validateCrop } = require('../middlewares/validation');

// Public routes
router.get('/', getAllCrops);
router.get('/categories', getCropCategories);
router.get('/:id', getCropById);

// Protected routes (require authentication)
router.use(auth);

// Farmer routes
router.post('/', validateCrop, createCrop);
router.get('/farmer/my-crops', getFarmerCrops);
router.put('/:id', updateCrop);
router.delete('/:id', deleteCrop);

module.exports = router;
