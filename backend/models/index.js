const { Sequelize, DataTypes } = require('sequelize');
require('dotenv').config();

const sequelize = new Sequelize(
    process.env.DB_NAME,
    process.env.DB_USER,
    process.env.DB_PASSWORD,
    {
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        dialect: 'postgres',
        logging: false,
    }
);

// User Model
const User = sequelize.define('User', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    phone_number: { type: DataTypes.STRING, unique: true, allowNull: false },
    name: { type: DataTypes.STRING, allowNull: false },
    email: { type: DataTypes.STRING },
    user_type: { type: DataTypes.STRING, allowNull: false },
    password_hash: { type: DataTypes.STRING },
    is_verified: { type: DataTypes.BOOLEAN, defaultValue: false },
    is_active: { type: DataTypes.BOOLEAN, defaultValue: true },
    profile_image_url: { type: DataTypes.TEXT },
    district: { type: DataTypes.STRING },
    subcounty: { type: DataTypes.STRING },
    parish: { type: DataTypes.STRING },
    village: { type: DataTypes.STRING },
    farm_size: { type: DataTypes.DECIMAL },
    specialization: { type: DataTypes.ARRAY(DataTypes.TEXT) },
    business_license: { type: DataTypes.STRING },
    vehicle_type: { type: DataTypes.STRING },
    vehicle_registration: { type: DataTypes.STRING },
}, { timestamps: true });

// Crop Model
const Crop = sequelize.define('Crop', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    name: { type: DataTypes.STRING, allowNull: false },
    category: { type: DataTypes.STRING, allowNull: false },
    unit_of_measure: { type: DataTypes.STRING, allowNull: false, defaultValue: 'kg' },
    seasonal_months: { type: DataTypes.ARRAY(DataTypes.INTEGER) },
    description: { type: DataTypes.TEXT },
    image_url: { type: DataTypes.TEXT },
}, { timestamps: true });

// FarmerListing Model
const FarmerListing = sequelize.define('FarmerListing', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    quantity: { type: DataTypes.DECIMAL, allowNull: false },
    unit_price: { type: DataTypes.DECIMAL },
    total_value: { type: DataTypes.DECIMAL },
    quality_grade: { type: DataTypes.STRING, defaultValue: 'standard' },
    harvest_date: { type: DataTypes.DATE },
    expiry_date: { type: DataTypes.DATE },
    description: { type: DataTypes.TEXT },
    images: { type: DataTypes.ARRAY(DataTypes.TEXT) },
    status: { type: DataTypes.STRING, defaultValue: 'available' },
}, { timestamps: true });

// Order Model
const Order = sequelize.define('Order', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    buyer_id: { type: DataTypes.UUID, allowNull: false },
    listing_id: { type: DataTypes.UUID, allowNull: false },
    quantity: { type: DataTypes.DECIMAL, allowNull: false },
    total_price: { type: DataTypes.DECIMAL, allowNull: false },
    status: { type: DataTypes.STRING, defaultValue: 'pending' },
}, { timestamps: true });

// Associations
User.hasMany(FarmerListing, { foreignKey: 'farmer_id' });
FarmerListing.belongsTo(User, { foreignKey: 'farmer_id' });
Crop.hasMany(FarmerListing, { foreignKey: 'crop_id' });
FarmerListing.belongsTo(Crop, { foreignKey: 'crop_id' });

// Order associations
User.hasMany(Order, { foreignKey: 'buyer_id', as: 'orders' });
Order.belongsTo(User, { foreignKey: 'buyer_id', as: 'buyer' });
FarmerListing.hasMany(Order, { foreignKey: 'listing_id' });
Order.belongsTo(FarmerListing, { foreignKey: 'listing_id' });

module.exports = { sequelize, User, Crop, FarmerListing, Order };
