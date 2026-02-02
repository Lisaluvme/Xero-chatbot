/**
 * Groq AI Client for Xero Accounting
 *
 * This module handles all interactions with Groq's fast AI models.
 * It processes user messages and determines whether to:
 * 1. Create invoices/quotations (returns structured JSON)
 * 2. Answer accounting questions (returns text response)
 *
 * API Documentation: https://console.groq.com/docs
 */

const Groq = require('groq-sdk');

/**
 * Request Queue for GLM API
 *
 * Prevents concurrency limit errors by ensuring only one request
 * is sent to GLM API at a time.
 */
class GLMRequestQueue {
  constructor() {
    this.queue = [];
    this.isProcessing = false;
  }

  async add(requestFn) {
    return new Promise((resolve, reject) => {
      this.queue.push({ requestFn, resolve, reject });
      this.process();
    });
  }

  async process() {
    if (this.isProcessing || this.queue.length === 0) {
      return;
    }

    this.isProcessing = true;
    const { requestFn, resolve, reject } = this.queue.shift();

    try {
      const result = await requestFn();
      resolve(result);
    } catch (error) {
      reject(error);
    } finally {
      this.isProcessing = false;
      // Small delay between requests to avoid rate limits
      setTimeout(() => this.process(), 500);
    }
  }
}

const glmQueue = new GLMRequestQueue();

/**
 * System Prompt for GLM-4-Flash - Xero JSON-Only Mode
 *
 * Strict JSON output mode for Xero document creation.
 * AI extracts structured data, backend handles validation and calculations.
 */
const SYSTEM_PROMPT = `You are a JSON extraction engine for Xero accounting documents.

CRITICAL RULES:
1. Output ONLY valid JSON. No markdown, no code blocks, no text, no explanations.
2. Do NOT calculate totals, tax, or discounts. Backend will calculate.
3. Do NOT guess or invent missing data.
4. If data is missing, output JSON with "missing_fields" array.
5. Use YYYY-MM-DD format for dates.
6. Default currency: MYR.

SUPPORTED DOCUMENT TYPES:
- quotation (DRAFT status in Xero)
- invoice (AUTHORISED status in Xero)

JSON SCHEMA - QUOTATION:
When user provides complete quotation data, output:
{
  "action": "create_quotation",
  "type": "ACCREC",
  "contact_name": "Customer Name Sdn Bhd",
  "date": "2026-01-30",
  "expiry_date": "2026-02-28",
  "line_items": [
    {
      "description": "Service or product description",
      "quantity": 1,
      "unit_amount": 1000,
      "tax_type": "NONE",
      "account_code": "200"
    }
  ],
  "currency_code": "MYR",
  "reference": "Optional reference number"
}

JSON SCHEMA - INVOICE:
When user provides complete invoice data, output:
{
  "action": "create_invoice",
  "type": "ACCREC",
  "contact_name": "Customer Name Sdn Bhd",
  "date": "2026-01-30",
  "due_date": "2026-02-28",
  "line_items": [
    {
      "description": "Service or product description",
      "quantity": 1,
      "unit_amount": 1000,
      "tax_type": "NONE",
      "account_code": "200"
    }
  ],
  "currency_code": "MYR",
  "reference": "Optional reference number"
}

MISSING DATA RESPONSE:
If required information is missing, output:
{
  "action": "request_info",
  "document_type": "quotation or invoice",
  "missing_fields": [
    "contact_name",
    "date",
    "line_items[0].description",
    "line_items[0].quantity"
  ],
  "message": "Please provide the following information to create the quotation"
}

REQUIRED FIELDS:
- contact_name (string)
- date (YYYY-MM-DD)
- line_items array with at least 1 item containing:
  - description (string)
  - quantity (number)
  - unit_amount (number)

OPTIONAL FIELDS:
- expiry_date (for quotations) or due_date (for invoices)
- line_items[].tax_type (default: "NONE")
- line_items[].account_code (default: "200")
- reference (string)
- currency_code (default: "MYR")

TAX TYPES (Malaysia):
- NONE (no tax)
- SST 6% (Sales and Service Tax)
- SST 10% (specific services)

DEFAULT VALUES:
- currency_code: "MYR"
- tax_type: "NONE"
- account_code: "200"
- quotation status: "DRAFT"
- invoice status: "AUTHORISED"
- type: "ACCREC"

Extract data from user input and output matching JSON schema only.
`;

/**
 * Chat with Groq AI API
 *
 * @param {string} userMessage - The user's message
 * @param {Array} conversationHistory - Previous conversation for context
 * @returns {Promise<Object>} - AI response with content and metadata
 */
async function chatWithGLM(userMessage, conversationHistory = []) {
  // Use request queue to prevent concurrency limit errors
  return glmQueue.add(async () => {
    try {
      // Initialize Groq client
      const groq = new Groq({
        apiKey: process.env.GROQ_API_KEY || process.env.GLM_API_KEY
      });

      // Build messages array with system prompt and conversation history
      const messages = [
        {
          role: 'system',
          content: SYSTEM_PROMPT
        },
        ...conversationHistory,
        {
          role: 'user',
          content: userMessage
        }
      ];

      // Make API request to Groq (using llama-3.3-70b-versatile - fast and capable)
      const response = await groq.chat.completions.create({
        model: 'llama-3.3-70b-versatile',
        messages: messages,
        temperature: 0.7,
        max_tokens: 2000,
        top_p: 0.9
      });

      // Extract AI response content
      const aiContent = response.choices[0].message.content;
      const usage = response.usage || {};

      // Try to parse response as JSON (for invoice/quotation creation)
      let parsedJSON = null;
      let isJSON = false;

      try {
        // Clean the content - remove markdown code blocks if AI added them
        const cleanedContent = aiContent
          .replace(/```json\n?/g, '')
          .replace(/```\n?/g, '')
          .trim();

        // Try to parse as JSON
        parsedJSON = JSON.parse(cleanedContent);

        // Verify it's a valid response object (create_quotation, create_invoice, or request_info)
        if (parsedJSON && (
          parsedJSON.action === 'create_invoice' ||
          parsedJSON.action === 'create_quotation' ||
          parsedJSON.action === 'request_info'
        )) {
          isJSON = true;
        }
      } catch (parseError) {
        // Not valid JSON, treat as regular text response
        isJSON = false;
      }

      return {
        success: true,
        content: aiContent,
        parsedJSON: parsedJSON,
        isJSON: isJSON,
        usage: usage,
        model: 'llama-3.3-70b-versatile'
      };

    } catch (error) {
      // Handle API errors
      console.error('Groq API Error:', error.response?.data || error.message);

      return {
        success: false,
        error: error.response?.data?.error?.message || error.message,
        content: 'Sorry, I encountered an error processing your request. Please try again.',
        isJSON: false
      };
    }
  });
}

/**
 * Detect if user wants to create a document
 *
 * This is a helper function to identify user intent early.
 *
 * @param {string} message - User message
 * @returns {boolean} - True if intent appears to be document creation
 */
function detectDocumentCreationIntent(message) {
  const keywords = [
    'create', 'generate', 'new', 'make', 'add', 'draft', 'prepare',
    'invoice', 'quotation', 'quote', 'bill', 'sales',
    'purchase order', 'po', 'delivery order', 'do'
  ];

  const lowerMessage = message.toLowerCase();
  return keywords.some(keyword => lowerMessage.includes(keyword));
}

/**
 * Format currency for display
 *
 * @param {number} amount - Amount to format
 * @returns {string} - Formatted currency string (e.g., "RM 1,234.56")
 */
function formatCurrency(amount) {
  return `RM ${parseFloat(amount).toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,')}`;
}

module.exports = {
  chatWithGLM,
  detectDocumentCreationIntent,
  formatCurrency
};
