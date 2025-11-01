const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyAdmin, verifyToken } = require('../middleware/auth');

// Dashboard KPI
router.get('/dashboard/kpi', verifyAdmin, adminController.getDashboardKpi);

// User Management
router.get('/users', verifyAdmin, adminController.getUsers);
router.get('/users/:id', verifyAdmin, adminController.getUserById);
router.put('/users/:id', verifyAdmin, adminController.updateUser);
router.delete('/users/:id', verifyAdmin, adminController.deleteUser);
router.put('/users/:id/status', verifyAdmin, adminController.updateUserStatus);

// Role Management
router.get('/roles', verifyAdmin, adminController.getRoles);
// router.post('/roles', verifyAdmin, adminController.createRole);
// router.put('/roles/:id', verifyAdmin, adminController.updateRole);
// router.delete('/roles/:id', verifyAdmin, adminController.deleteRole);

// Application Review
router.get('/applications', verifyAdmin, adminController.getApplications);
router.get('/applications/:id', verifyAdmin, adminController.getApplicationById);
router.put('/applications/:id/approve', verifyAdmin, adminController.approveApplication);
router.put('/applications/:id/reject', verifyAdmin, adminController.rejectApplication);

// System Statistics
router.get('/stats/users', verifyAdmin, adminController.getUserStats);
router.get('/stats/hotels', verifyAdmin, adminController.getHotelStats);
router.get('/stats/bookings', verifyAdmin, adminController.getBookingStats);
router.get('/stats/revenue', verifyAdmin, adminController.getRevenueStats);

// System Management
router.get('/system/health', verifyAdmin, adminController.getSystemHealth);
router.get('/system/logs', verifyAdmin, adminController.getSystemLogs);
router.post('/system/backup', verifyAdmin, adminController.createBackup);

// Hotel Management (Admin only)
router.put('/hotels/:id/status', verifyAdmin, adminController.updateHotelStatus);

module.exports = router;
