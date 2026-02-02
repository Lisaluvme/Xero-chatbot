/**
 * GLM-4-Flash API Client
 *
 * This module handles all interactions with the GLM-4-Flash API for AI responses.
 * It processes user messages and determines whether to create invoices/quotations
 * or answer accounting questions.
 */

const axios = require('axios');

/**
 * System prompt that defines the AI assistant's behavior
 */
const SYSTEM_PROMPT = `You are an AI accounting assistant integrated with Xero API. Your goal is to help the user:

1. **Answer Accounting Questions**
   - Explain accounting concepts concisely.
   - Provide insights on customers, invoices, quotations, and transactions.
   - Perform simple calculations like totals, taxes, and discounts.

2. **Create Documents in Xero**
   - Sales Quotations / Draft Invoices
   - Ask for required information: customer name/code, date, line items, quantity, price, tax.
   - Confirm details before generating.
   - Use Xero API to create drafts (simulate API calls in your responses, include JSON format for API).

3. **Guidelines**
   - Be concise, professional but friendly.
   - Always confirm missing information before generating a document.
   - Format currency as "RM X,XXX.XX".
   - Format dates as "YYYY-MM-DD".
   - If a calculation is needed (like subtotal, discount, tax), compute it accurately and include it in the output.

4. **Response Format**
   - For generating a quotation or invoice, output ONLY a valid JSON object (no markdown, no code blocks):
     {
       "action": "create_invoice",
       "customer_code": "CUST001",
       "customer_name": "Customer Name",
       "date": "2026-01-29",
       "due_date": "2026-02-05",
       "line_items": [
         { "description": "Item A", "quantity": 2, "unit_amount": 100, "tax_type": "NONE", "account_code": "200" }
       ],
       "subtotal": 200,
       "total_tax": 0,
       "total": 200,
       "reference": "QUO-001",
       "type": "ACCREC"
     }
   - For general questions, respond normally with text.
   - If information is missing, ask for it in a friendly way.

5. **Important**
   - When the user requests to create an invoice/quotation, extract all available information.
   - If any required field is missing, ask for it specifically.
   - Once all information is collected, output the JSON object.
   - Do NOT wrap JSON in \`\`\`json or \`\`\` code blocks. Output raw JSON only.
   - Default tax_type for Malaysia is "NONE" (unless user specifies tax).
   - Default account_code is "200" (Sales).
`;

/**
 * Chat with GLM-4-Flash API
 *
 * @param {string} userMessage - The user's message
 * @param {Array} conversationHistory - Previous conversation context
 * @returns {Promise<Object>} - AI response with content and metadata
 */
async function chatWithGLM(userMessage, conversationHistory = []) {
  try {
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

    // Make API request to GLM-4-Flash
    const response = await axios.post(
      process.env.GLM_API_URL || 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
      {
        model: 'glm-4-flash',
        messages: messages,
        temperature: 0.7,
        max_tokens: 2000,
        top_p: 0.9
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${process.env.GLM_API_KEY}`
        }
      }
    );

    // Extract AI response
    const aiContent = response.data.choices[0].message.content;
    const usage = response.data.usage || {};

    // Determine if response is JSON (invoice/quotation) or text (general response)
    let parsedJSON = null;
    let isJSON = false;

    // Try to parse as JSON
    try {
      // Clean the content - remove markdown code blocks if present
      const cleanedContent = aiContent
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();

      parsedJSON = JSON.parse(cleanedContent);
      isJSON = true;
    } catch (e) {
      // Not JSON, treat as regular text response
      isJSON = false;
    }

    return {
      success: true,
      content: aiContent,
      parsedJSON: parsedJSON,
      isJSON: isJSON,
      usage: usage,
      rawResponse: response.data
    };

  } catch (error) {
    console.error('GLM API Error:', error.response?.data || error.message);

    return {
      success: false,
      error: error.response?.data?.error?.message || error.message,
      content: 'Sorry, I encountered an error processing your request. Please try again.'
    };
  }
}

/**
 * Detect if user wants to create an invoice/quotation
 *
 * @param {string} message - User message
 * @returns {boolean} - True if intent is to create document
 */
function detectDocumentCreationIntent(message) {
  const keywords = [
    'create', 'generate', 'new', 'make', 'add', 'draft',
    'invoice', 'quotation', 'quote', 'bill', 'sales'
  ];

  const lowerMessage = message.toLowerCase();
  return keywords.some(keyword => lowerMessage.includes(keyword));
}

module.exports = {
  chatWithGLM,
  detectDocumentCreationIntent
};
