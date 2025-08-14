const TelegramBot = require('node-telegram-bot-api');
const logger = require('../../utils/logger');
const virtualAssistant = require('../ai/virtualAssistant');

class TelegramBotService {
  constructor() {
    this.token = process.env.TELEGRAM_BOT_TOKEN;
    this.bot = null;
    this.isInitialized = false;
    this.userSessions = new Map(); // Store user conversation sessions
  }

  /**
   * Initialize Telegram bot
   */
  async initialize() {
    try {
      if (!this.token) {
        logger.warn('Telegram bot token not provided, bot service disabled');
        return;
      }

      this.bot = new TelegramBot(this.token, { polling: true });
      this.setupEventHandlers();
      this.isInitialized = true;

      logger.info('Telegram bot initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize Telegram bot:', error);
    }
  }

  /**
   * Setup bot event handlers
   */
  setupEventHandlers() {
    // Handle /start command
    this.bot.onText(/\/start/, async (msg) => {
      const chatId = msg.chat.id;
      const welcomeMessage = `
🤖 Welcome to Comply AI Assistant!

I can help you with:
• Compliance deadlines and requirements
• Business trip documentation
• Report submission guidelines
• Tax and legal obligations
• IT Park regulations

Type your question or use these commands:
/help - Show available commands
/deadlines - Check upcoming deadlines
/status - Check compliance status
/trip - Business trip assistance

How can I help you today?
      `;

      await this.sendMessage(chatId, welcomeMessage);
    });

    // Handle /help command
    this.bot.onText(/\/help/, async (msg) => {
      const chatId = msg.chat.id;
      const helpMessage = `
📋 Available Commands:

/start - Start conversation
/help - Show this help message
/deadlines - View upcoming compliance deadlines
/status - Check your company's compliance status
/trip - Get business trip documentation help
/report - Generate or check report status
/contact - Contact support

You can also ask me questions in natural language like:
• "When is my quarterly report due?"
• "What documents do I need for a business trip?"
• "How do I submit my annual report?"
      `;

      await this.sendMessage(chatId, helpMessage);
    });

    // Handle /deadlines command
    this.bot.onText(/\/deadlines/, async (msg) => {
      const chatId = msg.chat.id;
      // This would typically fetch real deadline data from the database
      const deadlinesMessage = `
📅 Upcoming Deadlines:

🔴 Critical (Due Soon):
• Q4 2024 Report - Due Jan 31, 2025 (5 days)
• VAT Return - Due Jan 20, 2025 (2 days)

🟡 Important (Due This Month):
• Business Trip Report - Due Jan 25, 2025
• Monthly Revenue Tracking - Due Jan 31, 2025

🟢 Upcoming (Next Month):
• Annual Tax Return - Due Mar 31, 2025

Need help with any of these? Just ask!
      `;

      await this.sendMessage(chatId, deadlinesMessage);
    });

    // Handle general messages (AI assistant)
    this.bot.on('message', async (msg) => {
      const chatId = msg.chat.id;
      const messageText = msg.text;

      // Skip if it's a command (already handled above)
      if (messageText && messageText.startsWith('/')) {
        return;
      }

      try {
        // Get user context (in real app, fetch from database)
        const userContext = {
          chatId: chatId,
          userId: msg.from.id,
          username: msg.from.username,
          // companyId would be fetched from user registration
        };

        // Process query with virtual assistant
        const response = await virtualAssistant.processQuery(messageText, userContext);

        let replyMessage = response.answer;

        // Add suggestions if available
        if (response.suggestions && response.suggestions.length > 0) {
          replyMessage += '\n\n💡 You might also want to:\n';
          response.suggestions.forEach((suggestion, index) => {
            replyMessage += `${index + 1}. ${suggestion}\n`;
          });
        }

        await this.sendMessage(chatId, replyMessage);

      } catch (error) {
        logger.error('Error processing Telegram message:', error);
        await this.sendMessage(chatId, 'Sorry, I encountered an error processing your request. Please try again.');
      }
    });

    // Handle callback queries (inline keyboard buttons)
    this.bot.on('callback_query', async (callbackQuery) => {
      const message = callbackQuery.message;
      const data = callbackQuery.data;
      const chatId = message.chat.id;

      try {
        await this.handleCallbackQuery(chatId, data, callbackQuery);
      } catch (error) {
        logger.error('Error handling callback query:', error);
      }
    });

    // Handle errors
    this.bot.on('error', (error) => {
      logger.error('Telegram bot error:', error);
    });
  }