// Sequelize migration for initial table creation
'use strict';

module.exports = {
    up: async (queryInterface, Sequelize) => {
        await queryInterface.createTable('Users', {
            id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
            phone_number: { type: Sequelize.STRING, unique: true, allowNull: false },
            name: { type: Sequelize.STRING, allowNull: false },
            email: { type: Sequelize.STRING },
            user_type: { type: Sequelize.STRING, allowNull: false },
            password_hash: { type: Sequelize.STRING },
            is_verified: { type: Sequelize.BOOLEAN, defaultValue: false },
            is_active: { type: Sequelize.BOOLEAN, defaultValue: true },
            profile_image_url: { type: Sequelize.TEXT },
            district: { type: Sequelize.STRING },
            subcounty: { type: Sequelize.STRING },
            parish: { type: Sequelize.STRING },
            village: { type: Sequelize.STRING },
            farm_size: { type: Sequelize.DECIMAL },
            specialization: { type: Sequelize.ARRAY(Sequelize.TEXT) },
            business_license: { type: Sequelize.STRING },
            vehicle_type: { type: Sequelize.STRING },
            vehicle_registration: { type: Sequelize.STRING },
            createdAt: { type: Sequelize.DATE, allowNull: false },
            updatedAt: { type: Sequelize.DATE, allowNull: false }
        });

        await queryInterface.createTable('Crops', {
            id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
            name: { type: Sequelize.STRING, allowNull: false },
            category: { type: Sequelize.STRING, allowNull: false },
            unit_of_measure: { type: Sequelize.STRING, allowNull: false, defaultValue: 'kg' },
            seasonal_months: { type: Sequelize.ARRAY(Sequelize.INTEGER) },
            description: { type: Sequelize.TEXT },
            image_url: { type: Sequelize.TEXT },
            createdAt: { type: Sequelize.DATE, allowNull: false },
            updatedAt: { type: Sequelize.DATE, allowNull: false }
        });

        await queryInterface.createTable('FarmerListings', {
            id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
            quantity: { type: Sequelize.DECIMAL, allowNull: false },
            unit_price: { type: Sequelize.DECIMAL },
            total_value: { type: Sequelize.DECIMAL },
            quality_grade: { type: Sequelize.STRING, defaultValue: 'standard' },
            harvest_date: { type: Sequelize.DATE },
            expiry_date: { type: Sequelize.DATE },
            description: { type: Sequelize.TEXT },
            images: { type: Sequelize.ARRAY(Sequelize.TEXT) },
            status: { type: Sequelize.STRING, defaultValue: 'available' },
            farmer_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'Users', key: 'id' } },
            crop_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'Crops', key: 'id' } },
            createdAt: { type: Sequelize.DATE, allowNull: false },
            updatedAt: { type: Sequelize.DATE, allowNull: false }
        });

        await queryInterface.createTable('Orders', {
            id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
            buyer_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'Users', key: 'id' } },
            listing_id: { type: Sequelize.UUID, allowNull: false, references: { model: 'FarmerListings', key: 'id' } },
            quantity: { type: Sequelize.DECIMAL, allowNull: false },
            total_price: { type: Sequelize.DECIMAL, allowNull: false },
            status: { type: Sequelize.STRING, defaultValue: 'pending' },
            createdAt: { type: Sequelize.DATE, allowNull: false },
            updatedAt: { type: Sequelize.DATE, allowNull: false }
        });
    },

    down: async (queryInterface, Sequelize) => {
        await queryInterface.dropTable('Orders');
        await queryInterface.dropTable('FarmerListings');
        await queryInterface.dropTable('Crops');
        await queryInterface.dropTable('Users');
    }
};
