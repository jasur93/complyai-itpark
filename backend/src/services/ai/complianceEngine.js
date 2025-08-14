const axios = require('axios');
const logger = require('../../utils/logger');

class ComplianceEngine {
  constructor() {
    this.openaiApiKey = process.env.OPENAI_API_KEY;
    this.openaiBaseUrl = 'https://api.openai.com/v1';
  }

  /**
   * Analyze financial data for compliance violations
   * @param {Object} financialData - Company financial data
   * @param {Array} complianceRules - Applicable compliance rules
   * @returns {Object} Analysis results with violations and risk score
   */
  async analyzeCompliance(financialData, complianceRules) {
    try {
      const analysis = {
        violations: [],
        riskScore: 0,
        recommendations: [],
        insights: []
      };

      // Rule-based compliance checking
      for (const rule of complianceRules) {
        const violation = await this.checkRule(financialData, rule);
        if (violation) {
          analysis.violations.push(violation);
        }
      }

      // AI-powered anomaly detection
      const anomalies = await this.detectAnomalies(financialData);
      analysis.insights.push(...anomalies);

      // Calculate risk score
      analysis.riskScore = this.calculateRiskScore(analysis.violations, anomalies);

      // Generate AI recommendations
      analysis.recommendations = await this.generateRecommendations(analysis);

      logger.info(`Compliance analysis completed for company. Risk score: ${analysis.riskScore}`);
      return analysis;

    } catch (error) {
      logger.error('Compliance analysis failed:', error);
      throw new Error('Failed to analyze compliance data');
    }
  }

  /**
   * Check individual compliance rule
   * @param {Object} data - Financial data
   * @param {Object} rule - Compliance rule
   * @returns {Object|null} Violation object or null
   */
  async checkRule(data, rule) {
    try {
      const ruleDefinition = rule.rule_definition;

      switch (ruleDefinition.type) {
        case 'report_submission':
          return this.checkReportSubmission(data, rule);
        case 'revenue_tracking':
          return this.checkRevenueTracking(data, rule);
        case 'tax_compliance':
          return this.checkTaxCompliance(data, rule);
        case 'trip_documentation':
          return this.checkTripDocumentation(data, rule);
        default:
          return null;
      }
    } catch (error) {
      logger.error(`Rule check failed for rule ${rule.id}:`, error);
      return null;
    }
  }

  /**
   * Check report submission compliance
   */
  checkReportSubmission(data, rule) {
    const { lastSubmissionDate, requiredFrequency } = data;
    const deadlineDays = rule.deadline_days;

    if (!lastSubmissionDate) {
      return {
        ruleId: rule.id,
        violationType: 'missing_submission',
        severity: rule.severity,
        description: `No ${rule.name} found`,
        detectedAt: new Date(),
        aiConfidence: 1.0
      };
    }

    const daysSinceSubmission = Math.floor(
      (new Date() - new Date(lastSubmissionDate)) / (1000 * 60 * 60 * 24)
    );

    if (daysSinceSubmission > deadlineDays) {
      return {
        ruleId: rule.id,
        violationType: 'overdue_submission',
        severity: rule.severity,
        description: `${rule.name} is ${daysSinceSubmission - deadlineDays} days overdue`,
        detectedAt: new Date(),
        aiConfidence: 1.0
      };
    }

    return null;
  }

  /**
   * Check revenue tracking compliance
   */
  checkRevenueTracking(data, rule) {
    const { monthlyRevenue, threshold } = data;
    const ruleThreshold = rule.rule_definition.threshold || 10000;

    if (!monthlyRevenue || monthlyRevenue.length === 0) {
      return {
        ruleId: rule.id,
        violationType: 'missing_revenue_data',
        severity: rule.severity,
        description: 'Monthly revenue data is missing',
        detectedAt: new Date(),
        aiConfidence: 1.0
      };
    }

    // Check for significant revenue drops
    const recentRevenue = monthlyRevenue.slice(-3); // Last 3 months
    const avgRevenue = recentRevenue.reduce((sum, r) => sum + r.amount, 0) / recentRevenue.length;

    if (avgRevenue < ruleThreshold) {
      return {
        ruleId: rule.id,
        violationType: 'low_revenue',
        severity: 'medium',
        description: `Average monthly revenue (${avgRevenue}) below threshold (${ruleThreshold})`,
        detectedAt: new Date(),
        aiConfidence: 0.85
      };
    }

    return null;
  }

  /**
   * Detect anomalies using AI
   * @param {Object} data - Financial data
   * @returns {Array} Array of detected anomalies
   */
  async detectAnomalies(data) {
    try {
      if (!this.openaiApiKey) {
        logger.warn('OpenAI API key not configured, skipping AI anomaly detection');
        return [];
      }

      const prompt = `
        Analyze the following financial data for anomalies and compliance risks:

        ${JSON.stringify(data, null, 2)}

        Look for:
        1. Unusual spending patterns
        2. Revenue inconsistencies
        3. Missing documentation
        4. Potential compliance violations

        Return a JSON array of anomalies with: type, description, severity, confidence
      `;

      const response = await axios.post(
        `${this.openaiBaseUrl}/chat/completions`,
        {
          model: 'gpt-4',
          messages: [
            {
              role: 'system',
              content: 'You are a financial compliance expert. Analyze data and identify potential issues.'
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          temperature: 0.3,
          max_tokens: 1000
        },
        {
          headers: {
            'Authorization': `Bearer ${this.openaiApiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      const aiResponse = response.data.choices[0].message.content;

      try {
        const anomalies = JSON.parse(aiResponse);
        return Array.isArray(anomalies) ? anomalies : [];
      } catch (parseError) {
        logger.warn('Failed to parse AI anomaly response:', parseError);
        return [];
      }

    } catch (error) {
      logger.error('AI anomaly detection failed:', error);
      return [];
    }
  }

  /**
   * Calculate overall risk score
   * @param {Array} violations - Detected violations
   * @param {Array} anomalies - Detected anomalies
   * @returns {number} Risk score (0-100)
   */
  calculateRiskScore(violations, anomalies) {
    let score = 0;

    // Score based on violations
    violations.forEach(violation => {
      switch (violation.severity) {
        case 'critical':
          score += 25;
          break;
        case 'high':
          score += 15;
          break;
        case 'medium':
          score += 10;
          break;
        case 'low':
          score += 5;
          break;
      }
    });

    // Score based on anomalies
    anomalies.forEach(anomaly => {
      const confidenceWeight = anomaly.confidence || 0.5;
      switch (anomaly.severity) {
        case 'critical':
          score += 20 * confidenceWeight;
          break;
        case 'high':
          score += 12 * confidenceWeight;
          break;
        case 'medium':
          score += 8 * confidenceWeight;
          break;
        case 'low':
          score += 3 * confidenceWeight;
          break;
      }
    });

    return Math.min(Math.round(score), 100);
  }

  /**
   * Generate AI-powered recommendations
   * @param {Object} analysis - Compliance analysis results
   * @returns {Array} Array of recommendations
   */
  async generateRecommendations(analysis) {
    try {
      if (!this.openaiApiKey || analysis.violations.length === 0) {
        return [];
      }

      const prompt = `
        Based on the following compliance analysis, provide actionable recommendations:

        Violations: ${JSON.stringify(analysis.violations, null, 2)}
        Risk Score: ${analysis.riskScore}

        Provide 3-5 specific, actionable recommendations to address these issues.
        Format as JSON array with: priority, action, description, timeline
      `;

      const response = await axios.post(
        `${this.openaiBaseUrl}/chat/completions`,
        {
          model: 'gpt-4',
          messages: [
            {
              role: 'system',
              content: 'You are a compliance consultant. Provide practical recommendations to resolve compliance issues.'
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          temperature: 0.4,
          max_tokens: 800
        },
        {
          headers: {
            'Authorization': `Bearer ${this.openaiApiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      const aiResponse = response.data.choices[0].message.content;

      try {
        const recommendations = JSON.parse(aiResponse);
        return Array.isArray(recommendations) ? recommendations : [];
      } catch (parseError) {
        logger.warn('Failed to parse AI recommendations:', parseError);
        return [];
      }

    } catch (error) {
      logger.error('AI recommendation generation failed:', error);
      return [];
    }
  }
}

module.exports = new ComplianceEngine();