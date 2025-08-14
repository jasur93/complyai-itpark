const express = require('express');
const { body, param, query } = require('express-validator');
const businessTripsController = require('../controllers/businessTripsController');
const { requireRole, requireCompanyAccess } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = express.Router();

// Validation schemas
const createTripValidation = [
  body('tripTitle').notEmpty().withMessage('Trip title is required'),
  body('destination').notEmpty().withMessage('Destination is required'),
  body('purpose').notEmpty().withMessage('Purpose is required'),
  body('startDate').isISO8601().withMessage('Valid start date is required'),
  body('endDate').isISO8601().withMessage('Valid end date is required'),
  body('totalBudget').optional().isFloat({ min: 0 }).withMessage('Budget must be a positive number'),
  body('currency').optional().isLength({ min: 3, max: 3 }).withMessage('Currency must be 3 characters')
];

const updateTripValidation = [
  param('id').isUUID().withMessage('Valid trip ID is required'),
  body('tripTitle').optional().notEmpty().withMessage('Trip title cannot be empty'),
  body('destination').optional().notEmpty().withMessage('Destination cannot be empty'),
  body('purpose').optional().notEmpty().withMessage('Purpose cannot be empty'),
  body('startDate').optional().isISO8601().withMessage('Valid start date is required'),
  body('endDate').optional().isISO8601().withMessage('Valid end date is required'),
  body('totalBudget').optional().isFloat({ min: 0 }).withMessage('Budget must be a positive number')
];

const addExpenseValidation = [
  param('id').isUUID().withMessage('Valid trip ID is required'),
  body('category').isIn(['transport', 'accommodation', 'meals', 'materials', 'other']).withMessage('Invalid expense category'),
  body('description').notEmpty().withMessage('Expense description is required'),
  body('amount').isFloat({ min: 0 }).withMessage('Amount must be a positive number'),
  body('expenseDate').isISO8601().withMessage('Valid expense date is required'),
  body('currency').optional().isLength({ min: 3, max: 3 }).withMessage('Currency must be 3 characters')
];

// Routes

/**
 * @route   GET /api/business-trips
 * @desc    Get all business trips for the user's company
 * @access  Private
 */
router.get('/',
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('status').optional().isIn(['planned', 'approved', 'in_progress', 'completed', 'reported']).withMessage('Invalid status'),
    query('employeeId').optional().isUUID().withMessage('Valid employee ID required')
  ],
  validate,
  businessTripsController.getAllTrips
);

/**
 * @route   GET /api/business-trips/:id
 * @desc    Get a specific business trip
 * @access  Private
 */
router.get('/:id',
  [param('id').isUUID().withMessage('Valid trip ID is required')],
  validate,
  businessTripsController.getTripById
);

/**
 * @route   POST /api/business-trips
 * @desc    Create a new business trip
 * @access  Private (Employee, Manager, Admin)
 */
router.post('/',
  createTripValidation,
  validate,
  requireRole(['employee', 'manager', 'admin']),
  businessTripsController.createTrip
);

/**
 * @route   PUT /api/business-trips/:id
 * @desc    Update a business trip
 * @access  Private (Trip creator, Manager, Admin)
 */
router.put('/:id',
  updateTripValidation,
  validate,
  businessTripsController.updateTrip
);

/**
 * @route   DELETE /api/business-trips/:id
 * @desc    Delete a business trip
 * @access  Private (Trip creator, Manager, Admin)
 */
router.delete('/:id',
  [param('id').isUUID().withMessage('Valid trip ID is required')],
  validate,
  businessTripsController.deleteTrip
);

/**
 * @route   POST /api/business-trips/:id/approve
 * @desc    Approve a business trip
 * @access  Private (Manager, Admin)
 */
router.post('/:id/approve',
  [param('id').isUUID().withMessage('Valid trip ID is required')],
  validate,
  requireRole(['manager', 'admin']),
  businessTripsController.approveTrip
);

/**
 * @route   POST /api/business-trips/:id/reject
 * @desc    Reject a business trip
 * @access  Private (Manager, Admin)
 */
router.post('/:id/reject',
  [
    param('id').isUUID().withMessage('Valid trip ID is required'),
    body('reason').notEmpty().withMessage('Rejection reason is required')
  ],
  validate,
  requireRole(['manager', 'admin']),
  businessTripsController.rejectTrip
);

/**
 * @route   POST /api/business-trips/:id/expenses
 * @desc    Add expense to a business trip
 * @access  Private (Trip creator, Manager, Admin)
 */
router.post('/:id/expenses',
  addExpenseValidation,
  validate,
  businessTripsController.addExpense
);

/**
 * @route   GET /api/business-trips/:id/expenses
 * @desc    Get all expenses for a business trip
 * @access  Private
 */
router.get('/:id/expenses',
  [param('id').isUUID().withMessage('Valid trip ID is required')],
  validate,
  businessTripsController.getTripExpenses
);

/**
 * @route   PUT /api/business-trips/:id/expenses/:expenseId
 * @desc    Update a trip expense
 * @access  Private (Trip creator, Manager, Admin)
 */
router.put('/:id/expenses/:expenseId',
  [
    param('id').isUUID().withMessage('Valid trip ID is required'),
    param('expenseId').isUUID().withMessage('Valid expense ID is required'),
    body('category').optional().isIn(['transport', 'accommodation', 'meals', 'materials', 'other']).withMessage('Invalid expense category'),
    body('description').optional().notEmpty().withMessage('Expense description cannot be empty'),
    body('amount').optional().isFloat({ min: 0 }).withMessage('Amount must be a positive number'),
    body('expenseDate').optional().isISO8601().withMessage('Valid expense date is required')
  ],
  validate,
  businessTripsController.updateExpense
);

/**
 * @route   DELETE /api/business-trips/:id/expenses/:expenseId
 * @desc    Delete a trip expense
 * @access  Private (Trip creator, Manager, Admin)
 */
router.delete('/:id/expenses/:expenseId',
  [
    param('id').isUUID().withMessage('Valid trip ID is required'),
    param('expenseId').isUUID().withMessage('Valid expense ID is required')
  ],
  validate,
  businessTripsController.deleteExpense
);

/**
 * @route   POST /api/business-trips/:id/report
 * @desc    Generate trip report with e-signature
 * @access  Private (Trip creator, Manager, Admin)
 */
router.post('/:id/report',
  [
    param('id').isUUID().withMessage('Valid trip ID is required'),
    body('summary').notEmpty().withMessage('Trip summary is required'),
    body('achievements').optional().isString(),
    body('recommendations').optional().isString(),
    body('signatureProvider').optional().isIn(['eimzo', 'internal']).withMessage('Invalid signature provider')
  ],
  validate,
  businessTripsController.generateTripReport
);

module.exports = router;