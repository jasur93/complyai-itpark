const axios = require('axios');
const logger = require('../../utils/logger');

class VirtualAssistant {
  constructor() {
    this.openaiApiKey = process.env.OPENAI_API_KEY;
    this.openaiBaseUrl = 'https://api.openai.com/v1';
    this.knowledgeBase = this.initializeKnowledgeBase();
  }

  /**
   * Initialize knowledge base with IT Park regulations and compliance info
   */
  initializeKnowledgeBase() {
    return {
      itParkRules: {
        quarterlyReporting: {
          deadline: "30 days after quarter end",
          requiredDocuments: ["Trial Balance", "General Ledger", "Balance Sheet", "Income Statement"],
          submissionMethod: "Electronic submission via IT Park portal"
        },
        annualReporting: {
          deadline: "45 days after year end",
          requiredDocuments: ["Annual Financial Statements", "Tax Returns", "Audit Report"],
          submissionMethod: "Electronic submission with e-signature"
        },
        businessTrips: {
          documentation: "All business trips must be documented with receipts and purpose",
          approvalRequired: "Manager approval required for trips over $1000",
          reportingDeadline: "7 days after trip completion"
        },
        taxCompliance: {
          vatReporting: "Monthly VAT returns due by 20th of following month",
          incomeTax: "Annual income tax return due by March 31st",
          socialContributions: "Monthly social security contributions due by 25th"
        }
      },
      commonQuestions: {
        "when to submit quarterly report": "Quarterly reports must be submitted within 30 days after the end of each quarter (Q1: April 30, Q2: July 31, Q3: October 31, Q4: January 31).",
        "business trip documentation": "Business trips require: 1) Pre-approval for trips over $1000, 2) Receipts for all expenses, 3) Trip report within 7 days of return, 4) Electronic signature on expense report.",
        "compliance deadlines": "Key deadlines: Quarterly reports (30 days), Annual reports (45 days), VAT returns (20th of month), Business trip reports (7 days).",
        "e-signature requirements": "E-signatures are required for: Annual reports, Business trip expense reports, Tax submissions, and any document over $5000 value."
      }
    };
  }

  /**
   * Process user query and provide intelligent response
   * @param {string} query - User's question
   * @param {Object} context - User and company context
   * @returns {Object} Response with answer and suggestions
   */
  async processQuery(query, context = {}) {
    try {
      logger.info(`Processing virtual assistant query: ${query}`);

      // First, try to match with knowledge base
      const knowledgeResponse = this.searchKnowledgeBase(query);
      if (knowledgeResponse) {
        return {
          answer: knowledgeResponse,
          source: 'knowledge_base',
          confidence: 0.9,
          suggestions: this.generateSuggestions(query)
        };
      }

      // If no knowledge base match, use AI
      const aiResponse = await this.getAIResponse(query, context);
      return {
        answer: aiResponse.answer,
        source: 'ai',
        confidence: aiResponse.confidence,
        suggestions: this.generateSuggestions(query)
      };

    } catch (error) {
      logger.error('Virtual assistant query processing failed:', error);
      return {
        answer: "I'm sorry, I'm having trouble processing your request right now. Please try again later or contact support.",
        source: 'error',
        confidence: 0,
        suggestions: ["Contact support", "Try rephrasing your question", "Check the help documentation"]
      };
    }
  }

  /**
   * Search knowledge base for relevant information
   * @param {string} query - User query
   * @returns {string|null} Knowledge base response or null
   */
  searchKnowledgeBase(query) {
    const normalizedQuery = query.toLowerCase();

    // Check common questions
    for (const [key, answer] of Object.entries(this.knowledgeBase.commonQuestions)) {
      if (normalizedQuery.includes(key) || this.calculateSimilarity(normalizedQuery, key) > 0.7) {
        return answer;
      }
    }

    // Check specific topics
    if (normalizedQuery.includes('quarterly') && normalizedQuery.includes('report')) {
      const info = this.knowledgeBase.itParkRules.quarterlyReporting;
      return `Quarterly reports are due ${info.deadline}. Required documents: ${info.requiredDocuments.join(', ')}. ${info.submissionMethod}.`;
    }

    if (normalizedQuery.includes('annual') && normalizedQuery.includes('report')) {
      const info = this.knowledgeBase.itParkRules.annualReporting;
      return `Annual reports are due ${info.deadline}. Required documents: ${info.requiredDocuments.join(', ')}. ${info.submissionMethod}.`;
    }

    if (normalizedQuery.includes('business trip') || normalizedQuery.includes('travel')) {
      const info = this.knowledgeBase.itParkRules.businessTrips;
      return `Business trip requirements: ${info.documentation}. ${info.approvalRequired}. Reports due ${info.reportingDeadline}.`;
    }

    if (normalizedQuery.includes('tax') || normalizedQuery.includes('vat')) {
      const info = this.knowledgeBase.itParkRules.taxCompliance;
      return `Tax compliance requirements: ${info.vatReporting}. ${info.incomeTax}. ${info.socialContributions}.`;
    }

    return null;
  }