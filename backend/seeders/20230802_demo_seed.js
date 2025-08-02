// Sequelize seeder for demo data
'use strict';

module.exports = {
    up: async (queryInterface, Sequelize) => {
        // Seed Crops
        await queryInterface.bulkInsert('Crops', [
            {
                name: 'Maize',
                category: 'Cereal',
                unit_of_measure: 'kg',
                seasonal_months: [3, 4, 5, 9, 10, 11],
                description: 'Maize is a staple cereal crop.',
                image_url: 'https://example.com/maize.jpg',
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                name: 'Tomato',
                category: 'Vegetable',
                unit_of_measure: 'kg',
                seasonal_months: [1, 2, 3, 7, 8, 9],
                description: 'Tomato is a popular vegetable.',
                image_url: 'https://example.com/tomato.jpg',
                createdAt: new Date(),
                updatedAt: new Date()
            }
        ]);

        // Seed Users
        await queryInterface.bulkInsert('Users', [
            {
                phone_number: '0700000001',
                name: 'John Farmer',
                email: 'john@farm.com',
                user_type: 'farmer',
                password_hash: null,
                is_verified: true,
                is_active: true,
                district: 'Kapchorwa',
                subcounty: 'East',
                parish: 'Central',
                village: 'Green',
                farm_size: 10,
                specialization: ['Maize'],
                business_license: 'LIC123',
                vehicle_type: 'Truck',
                vehicle_registration: 'UAA123X',
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                phone_number: '0700000002',
                name: 'Sarah Buyer',
                email: 'sarah@market.com',
                user_type: 'buyer',
                password_hash: null,
                is_verified: true,
                is_active: true,
                district: 'Kween',
                subcounty: 'West',
                parish: 'North',
                village: 'Blue',
                farm_size: null,
                specialization: [''],
                business_license: null,
                vehicle_type: null,
                vehicle_registration: null,
                createdAt: new Date(),
                updatedAt: new Date()
            }
        ]);
    },

    down: async (queryInterface, Sequelize) => {
        await queryInterface.bulkDelete('Users', null, {});
        await queryInterface.bulkDelete('Crops', null, {});
    }
};
