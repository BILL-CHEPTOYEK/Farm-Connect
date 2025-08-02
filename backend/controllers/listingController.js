const { FarmerListing, Crop, User } = require('../models');

// Get all listings
const getAllListings = async (req, res) => {
    try {
        const listings = await FarmerListing.findAll({
            include: [
                { model: Crop, attributes: ['id', 'name', 'category'] },
                { model: User, attributes: ['id', 'name', 'phone_number'] }
            ]
        });
        res.json({ success: true, data: listings });
    } catch (error) {
        console.error('Get listings error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Create a new listing
const createListing = async (req, res) => {
    try {
        const {
            crop_id,
            user_id,
            price,
            quantity,
            description,
            available_from,
            available_to,
            location
        } = req.body;
        const listing = await FarmerListing.create({
            crop_id,
            user_id,
            price,
            quantity,
            description,
            available_from,
            available_to,
            location
        });
        res.status(201).json({ success: true, data: listing });
    } catch (error) {
        console.error('Create listing error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Update a listing
const updateListing = async (req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body;
        const [updated] = await FarmerListing.update(updates, { where: { id } });
        if (updated) {
            const listing = await FarmerListing.findByPk(id);
            res.json({ success: true, message: 'Listing updated', data: listing });
        } else {
            res.status(404).json({ success: false, message: 'Listing not found' });
        }
    } catch (error) {
        console.error('Update listing error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Delete a listing
const deleteListing = async (req, res) => {
    try {
        const { id } = req.params;
        const deleted = await FarmerListing.destroy({ where: { id } });
        if (deleted) {
            res.json({ success: true, message: 'Listing deleted' });
        } else {
            res.status(404).json({ success: false, message: 'Listing not found' });
        }
    } catch (error) {
        console.error('Delete listing error:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

module.exports = {
    getAllListings,
    createListing,
    updateListing,
    deleteListing
};
