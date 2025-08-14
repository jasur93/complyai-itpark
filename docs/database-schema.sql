-- Comply AI Database Schema
-- PostgreSQL Database Design for AI-Powered Compliance System

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- CORE ENTITIES
-- =============================================

-- Companies table
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    legal_name VARCHAR(255) NOT NULL,
    tax_id VARCHAR(50) UNIQUE NOT NULL,
    registration_number VARCHAR(50) UNIQUE NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(255),
    industry VARCHAR(100),
    company_size VARCHAR(20) CHECK (company_size IN ('small', 'medium', 'large')) DEFAULT 'small',
    it_park_resident_since DATE,
    status VARCHAR(20) CHECK (status IN ('active', 'inactive', 'suspended')) DEFAULT 'active',
    compliance_score INTEGER DEFAULT 0,
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('admin', 'manager', 'accountant', 'employee')) DEFAULT 'employee',
    phone VARCHAR(20),
    language VARCHAR(5) CHECK (language IN ('en', 'ru', 'uz')) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- IT Park administrators
CREATE TABLE it_park_admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(30) CHECK (role IN ('super_admin', 'compliance_officer', 'analyst')) DEFAULT 'analyst',
    permissions JSON,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- COMPLIANCE & RULES
-- =============================================

-- Compliance rules
CREATE TABLE compliance_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(20) CHECK (category IN ('financial', 'legal', 'operational', 'reporting')) NOT NULL,
    rule_type VARCHAR(20) CHECK (rule_type IN ('mandatory', 'recommended', 'conditional')) DEFAULT 'mandatory',
    severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
    frequency VARCHAR(20) CHECK (frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'annually')) NOT NULL,
    deadline_days INTEGER DEFAULT 30,
    rule_definition JSON NOT NULL, -- AI rule logic
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Company-specific rule configurations
CREATE TABLE company_compliance_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    rule_id UUID REFERENCES compliance_rules(id) ON DELETE CASCADE,
    is_enabled BOOLEAN DEFAULT true,
    custom_parameters JSON,
    next_due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, rule_id)
);

-- =============================================
-- REPORTING SYSTEM
-- =============================================

-- Report templates
CREATE TABLE report_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    template_type VARCHAR(20) CHECK (template_type IN ('quarterly', 'annual', 'business_trip', 'custom')) NOT NULL,
    format VARCHAR(10) CHECK (format IN ('pdf', 'excel', 'both')) DEFAULT 'both',
    template_data JSON NOT NULL, -- Template structure and fields
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Generated reports
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    template_id UUID REFERENCES report_templates(id),
    report_type VARCHAR(20) CHECK (report_type IN ('quarterly', 'annual', 'business_trip', 'custom')) NOT NULL,
    title VARCHAR(255) NOT NULL,
    reporting_period_start DATE,
    reporting_period_end DATE,
    status VARCHAR(20) CHECK (status IN ('draft', 'generated', 'signed', 'submitted', 'approved', 'rejected')) DEFAULT 'draft',
    generated_by UUID REFERENCES users(id),
    generated_at TIMESTAMP,
    signed_at TIMESTAMP,
    submitted_at TIMESTAMP,
    file_path VARCHAR(500),
    file_hash VARCHAR(64),
    signature_data JSON,
    ai_analysis JSON, -- AI-generated insights and validations
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- BUSINESS TRIPS
-- =============================================

-- Business trips
CREATE TABLE business_trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES users(id),
    trip_title VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    purpose TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_budget DECIMAL(12,2),
    total_expenses DECIMAL(12,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) CHECK (status IN ('planned', 'approved', 'in_progress', 'completed', 'reported')) DEFAULT 'planned',
    approval_status VARCHAR(20) CHECK (approval_status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trip expenses
CREATE TABLE trip_expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES business_trips(id) ON DELETE CASCADE,
    category VARCHAR(20) CHECK (category IN ('transport', 'accommodation', 'meals', 'materials', 'other')) NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    expense_date DATE NOT NULL,
    receipt_file VARCHAR(500),
    is_reimbursable BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trip reports
CREATE TABLE trip_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES business_trips(id) ON DELETE CASCADE,
    report_id UUID REFERENCES reports(id),
    summary TEXT,
    achievements TEXT,
    recommendations TEXT,
    attachments JSON, -- Array of file paths
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- AUDIT & MONITORING
-- =============================================

-- Audit logs
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    old_values JSON,
    new_values JSON,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Compliance violations
CREATE TABLE compliance_violations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    rule_id UUID REFERENCES compliance_rules(id),
    violation_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')) NOT NULL,
    description TEXT NOT NULL,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    resolution_notes TEXT,
    status VARCHAR(20) CHECK (status IN ('open', 'investigating', 'resolved', 'false_positive')) DEFAULT 'open',
    ai_confidence DECIMAL(3,2), -- AI confidence score 0.00-1.00
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Risk assessments
CREATE TABLE risk_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    assessment_type VARCHAR(50) NOT NULL,
    risk_score INTEGER NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),
    risk_factors JSON NOT NULL,
    recommendations JSON,
    assessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- NOTIFICATIONS & ALERTS
-- =============================================

-- Notification templates
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    template_type VARCHAR(50) NOT NULL,
    channel VARCHAR(20) CHECK (channel IN ('email', 'telegram', 'sms', 'push')) NOT NULL,
    language VARCHAR(5) DEFAULT 'en',
    subject VARCHAR(255),
    content TEXT NOT NULL,
    variables JSON, -- Template variables
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    template_id UUID REFERENCES notification_templates(id),
    channel VARCHAR(20) CHECK (channel IN ('email', 'telegram', 'sms', 'push')) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    subject VARCHAR(255),
    content TEXT NOT NULL,
    status VARCHAR(20) CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'read')) DEFAULT 'pending',
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    read_at TIMESTAMP,
    error_message TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Alert rules
CREATE TABLE alert_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    trigger_conditions JSON NOT NULL,
    notification_channels JSON NOT NULL, -- Array of channels
    escalation_rules JSON,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- AI & ANALYTICS
-- =============================================

-- AI model configurations
CREATE TABLE ai_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    model_type VARCHAR(50) NOT NULL,
    version VARCHAR(20) NOT NULL,
    configuration JSON NOT NULL,
    training_data_info JSON,
    performance_metrics JSON,
    is_active BOOLEAN DEFAULT true,
    deployed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI predictions and insights
CREATE TABLE ai_insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    model_id UUID REFERENCES ai_models(id),
    insight_type VARCHAR(50) NOT NULL,
    confidence_score DECIMAL(3,2) NOT NULL,
    prediction_data JSON NOT NULL,
    actual_outcome JSON,
    feedback_score INTEGER, -- User feedback on accuracy
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Virtual assistant conversations
CREATE TABLE assistant_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    session_id UUID NOT NULL,
    message_type VARCHAR(20) CHECK (message_type IN ('user', 'assistant')) NOT NULL,
    content TEXT NOT NULL,
    context JSON,
    response_time_ms INTEGER,
    satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- EXTERNAL INTEGRATIONS
-- =============================================

-- Integration configurations
CREATE TABLE integrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    integration_type VARCHAR(50) NOT NULL, -- 'quickbooks', '1c', 'erp', 'eimzo'
    name VARCHAR(255) NOT NULL,
    configuration JSON NOT NULL,
    credentials_encrypted TEXT,
    status VARCHAR(20) CHECK (status IN ('active', 'inactive', 'error', 'pending')) DEFAULT 'pending',
    last_sync_at TIMESTAMP,
    sync_frequency VARCHAR(20) DEFAULT 'daily',
    error_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Integration sync logs
CREATE TABLE integration_sync_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_id UUID REFERENCES integrations(id) ON DELETE CASCADE,
    sync_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) CHECK (status IN ('started', 'completed', 'failed')) NOT NULL,
    records_processed INTEGER DEFAULT 0,
    records_created INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    error_details JSON,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- =============================================
-- PERFORMANCE & MOTIVATION
-- =============================================

-- Company performance metrics
CREATE TABLE company_performance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    metric_type VARCHAR(50) NOT NULL,
    metric_value DECIMAL(10,2) NOT NULL,
    measurement_period_start DATE NOT NULL,
    measurement_period_end DATE NOT NULL,
    benchmark_value DECIMAL(10,2),
    industry_average DECIMAL(10,2),
    ranking INTEGER,
    improvement_percentage DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Awards and recognitions
CREATE TABLE company_awards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    award_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    criteria_met JSON,
    award_date DATE NOT NULL,
    certificate_path VARCHAR(500),
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Core entity indexes
CREATE INDEX idx_companies_status ON companies(status);
CREATE INDEX idx_companies_risk_level ON companies(risk_level);
CREATE INDEX idx_companies_compliance_score ON companies(compliance_score);
CREATE INDEX idx_users_company_id ON users(company_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Compliance and rules indexes
CREATE INDEX idx_compliance_rules_category ON compliance_rules(category);
CREATE INDEX idx_compliance_rules_frequency ON compliance_rules(frequency);
CREATE INDEX idx_company_compliance_rules_company_id ON company_compliance_rules(company_id);
CREATE INDEX idx_company_compliance_rules_next_due_date ON company_compliance_rules(next_due_date);

-- Reporting indexes
CREATE INDEX idx_reports_company_id ON reports(company_id);
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_report_type ON reports(report_type);
CREATE INDEX idx_reports_reporting_period ON reports(reporting_period_start, reporting_period_end);

-- Business trips indexes
CREATE INDEX idx_business_trips_company_id ON business_trips(company_id);
CREATE INDEX idx_business_trips_employee_id ON business_trips(employee_id);
CREATE INDEX idx_business_trips_status ON business_trips(status);
CREATE INDEX idx_business_trips_dates ON business_trips(start_date, end_date);

-- Audit and monitoring indexes
CREATE INDEX idx_audit_logs_company_id ON audit_logs(company_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_compliance_violations_company_id ON compliance_violations(company_id);
CREATE INDEX idx_compliance_violations_status ON compliance_violations(status);
CREATE INDEX idx_compliance_violations_severity ON compliance_violations(severity);

-- Notifications indexes
CREATE INDEX idx_notifications_company_id ON notifications(company_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- AI and analytics indexes
CREATE INDEX idx_ai_insights_company_id ON ai_insights(company_id);
CREATE INDEX idx_ai_insights_insight_type ON ai_insights(insight_type);
CREATE INDEX idx_assistant_conversations_company_id ON assistant_conversations(company_id);
CREATE INDEX idx_assistant_conversations_session_id ON assistant_conversations(session_id);

-- Integration indexes
CREATE INDEX idx_integrations_company_id ON integrations(company_id);
CREATE INDEX idx_integrations_type ON integrations(integration_type);
CREATE INDEX idx_integration_sync_logs_integration_id ON integration_sync_logs(integration_id);
CREATE INDEX idx_integration_sync_logs_started_at ON integration_sync_logs(started_at);

-- Performance indexes
CREATE INDEX idx_company_performance_company_id ON company_performance(company_id);
CREATE INDEX idx_company_performance_metric_type ON company_performance(metric_type);
CREATE INDEX idx_company_performance_period ON company_performance(measurement_period_start, measurement_period_end);

-- =============================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update triggers to relevant tables
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_compliance_rules_updated_at BEFORE UPDATE ON compliance_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_business_trips_updated_at BEFORE UPDATE ON business_trips
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_integrations_updated_at BEFORE UPDATE ON integrations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- INITIAL DATA SETUP
-- =============================================

-- Insert default compliance rules
INSERT INTO compliance_rules (name, description, category, rule_type, severity, frequency, deadline_days, rule_definition) VALUES
('Quarterly Financial Report', 'Submit quarterly financial statements to IT Park', 'financial', 'mandatory', 'high', 'quarterly', 30, '{"type": "report_submission", "format": "quarterly_pack"}'),
('Annual Tax Report', 'Submit annual tax compliance report', 'legal', 'mandatory', 'critical', 'annually', 45, '{"type": "tax_compliance", "documents": ["tax_return", "audit_report"]}'),
('Monthly Revenue Tracking', 'Track and report monthly revenue figures', 'financial', 'mandatory', 'medium', 'monthly', 15, '{"type": "revenue_tracking", "threshold": 10000}'),
('Business Trip Documentation', 'Document all business trips with proper receipts', 'operational', 'mandatory', 'medium', 'monthly', 7, '{"type": "trip_documentation", "required_fields": ["purpose", "expenses", "receipts"]}');

-- Insert default report templates
INSERT INTO report_templates (name, description, template_type, format, template_data) VALUES
('IT Park Quarterly Pack', 'Standard quarterly reporting package for IT Park', 'quarterly', 'both', '{"sections": ["trial_balance", "general_ledger", "balance_sheet", "income_statement", "cash_flow"], "format": "it_park_standard"}'),
('Annual Compliance Report', 'Comprehensive annual compliance and tax report', 'annual', 'pdf', '{"sections": ["executive_summary", "financial_statements", "tax_compliance", "audit_findings"], "certification_required": true}'),
('Business Trip Report', 'Standard business trip expense and summary report', 'business_trip', 'pdf', '{"sections": ["trip_summary", "expenses", "receipts", "outcomes"], "signature_required": true}');

-- Insert default notification templates
INSERT INTO notification_templates (name, template_type, channel, language, subject, content, variables) VALUES
('Deadline Reminder', 'deadline_reminder', 'email', 'en', 'Compliance Deadline Approaching: {{rule_name}}', 'Dear {{user_name}}, your {{rule_name}} is due on {{due_date}}. Please ensure timely submission.', '["user_name", "rule_name", "due_date"]'),
('Violation Alert', 'violation_alert', 'telegram', 'en', '🚨 Compliance Violation Detected', 'Violation detected: {{violation_type}} for {{company_name}}. Severity: {{severity}}. Please review immediately.', '["violation_type", "company_name", "severity"]'),
('Report Generated', 'report_generated', 'email', 'en', 'Report Ready: {{report_title}}', 'Your {{report_type}} report has been generated and is ready for review and signature.', '["report_title", "report_type"]');

-- Insert default AI models
INSERT INTO ai_models (name, model_type, version, configuration, performance_metrics, is_active, deployed_at) VALUES
('Compliance Risk Scorer', 'risk_assessment', '1.0', '{"algorithm": "ensemble", "features": ["financial_ratios", "submission_history", "violation_count"]}', '{"accuracy": 0.87, "precision": 0.82, "recall": 0.91}', true, CURRENT_TIMESTAMP),
('Anomaly Detector', 'anomaly_detection', '1.0', '{"algorithm": "isolation_forest", "threshold": 0.1}', '{"false_positive_rate": 0.05, "detection_rate": 0.93}', true, CURRENT_TIMESTAMP),
('Virtual Assistant', 'nlp_chatbot', '1.0', '{"model": "gpt-4", "context_window": 4000, "temperature": 0.7}', '{"response_accuracy": 0.94, "user_satisfaction": 4.2}', true, CURRENT_TIMESTAMP);