# 🤖 Xero AI Chatbot - Complete Project

**Production-ready AI accounting chatbot** with GLM-4-Flash and Xero API integration.

Split into **frontend → Netlify** and **backend → Render** for easy deployment.

---

## 🌟 Features

- 🤖 **AI-Powered Chat** - GLM-4-Flash for intelligent responses
- 📄 **Document Creation** - Auto-generate invoices & quotations in Xero
- 💰 **Accounting Support** - Answer questions, perform calculations
- 🔐 **OAuth 2.0** - Secure Xero authentication
- 🎨 **Modern UI** - Clean, responsive chat interface
- 🚀 **Production-Ready** - Deploy to Render + Netlify

---

## 📁 Project Structure

```
xero-chatbot/
│
├── backend/              # Node.js/Express API
│   ├── server.js        # Main Express server
│   ├── glmClient.js     # GLM-4-Flash integration
│   ├── xeroClient.js    # Xero API integration
│   ├── package.json
│   ├── .env.example
│   └── README.md
│
├── frontend/            # Vanilla JS frontend
│   ├── index.html      # Main HTML
│   ├── style.css       # Styles
│   ├── app.js          # Frontend logic
│   ├── netlify.toml    # Netlify config
│   ├── package.json
│   └── README.md
│
├── DEPLOYMENT.md        # Complete deployment guide
├── EXAMPLES.md          # Example chat messages
└── README.md           # This file
```

---

## 🚀 Quick Start

### 1. Clone/Download

```bash
cd /Users/mgmadmin/Desktop/Xero\ Chatbot
```

### 2. Backend Setup

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your API keys
npm start
```

### 3. Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

### 4. Test Locally

- Backend: http://localhost:3000
- Frontend: http://localhost:8080 (or similar)

---

## 📋 Prerequisites

### Required Accounts

| Service | Link | Purpose |
|---------|------|---------|
| Render | https://render.com | Backend hosting |
| Netlify | https://netlify.com | Frontend hosting |
| Xero | https://developer.xero.com | Accounting API |
| Zhipu AI | https://open.bigmodel.cn | GLM-4-Flash API |

### Required API Keys

- [ ] GLM-4-Flash API Key
- [ ] Xero Client ID
- [ ] Xero Client Secret

---

## 🔑 Environment Variables

### Backend (`.env`)

```bash
# GLM-4-Flash
GLM_API_KEY=your_glm_api_key

# Xero OAuth
XERO_CLIENT_ID=your_xero_client_id
XERO_CLIENT_SECRET=your_xero_client_secret
XERO_REDIRECT_URI=https://your-backend.onrender.com/callback
XERO_SCOPE=accounting.transactions accounting.contacts accounting.settings offline_access

# Server
PORT=3000
FRONTEND_URL=https://your-frontend.netlify.app
```

### Frontend (`app.js`)

```javascript
const API_BASE_URL = 'https://your-backend.onrender.com';
```

---

## 🌐 Deployment

### Backend → Render

1. Go to https://dashboard.render.com/
2. **New +** → **Web Service**
3. Connect GitHub
4. Configure:
   - Root: `backend`
   - Build: `npm install`
   - Start: `node server.js`
5. Add environment variables
6. Deploy

**Full Guide**: See [DEPLOYMENT.md](./DEPLOYMENT.md)

---

### Frontend → Netlify

**Option 1: Drag & Drop**
- Open https://app.netlify.com/
- Drag `frontend` folder
- Done!

**Option 2: CLI**
```bash
npm install -g netlify-cli
cd frontend
netlify deploy --prod
```

**Full Guide**: See [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## 💬 Usage Examples

### Create Invoice

```
Create an invoice for ABC Company, 2 items: Web Design RM2000, Hosting RM500
```

### Calculate Total

```
Calculate total for 10 items at RM50 each with 10% discount
```

### Ask Question

```
What's the difference between a quote and an invoice?
```

**More Examples**: See [EXAMPLES.md](./EXAMPLES.md)

---

## 📚 API Endpoints

### Backend Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/login` | Initiate Xero OAuth |
| GET | `/callback` | OAuth callback |
| GET | `/status` | Check Xero status |
| POST | `/chat` | Main chat endpoint |
| POST | `/create-invoice` | Create invoice |
| POST | `/disconnect` | Disconnect Xero |

**Full API Docs**: See [backend/README.md](./backend/README.md)

---

## 🛠️ Tech Stack

### Backend

- **Node.js** - Runtime
- **Express** - Web framework
- **Axios** - HTTP client
- **GLM-4-Flash** - Zhipu AI
- **Xero API** - Accounting

### Frontend

- **Vanilla JavaScript** - No framework
- **CSS3** - Modern styling
- **HTML5** - Markup
- **Fetch API** - HTTP requests

---

## 🔐 Security

- Never commit `.env` files
- Use HTTPS in production
- Implement rate limiting
- Validate all inputs
- Secure Xero credentials

---

## 📖 Documentation

| File | Description |
|------|-------------|
| [DEPLOYMENT.md](./DEPLOYMENT.md) | Complete deployment guide |
| [EXAMPLES.md](./EXAMPLES.md) | Example chat messages |
| [backend/README.md](./backend/README.md) | Backend documentation |
| [frontend/README.md](./frontend/README.md) | Frontend documentation |

---

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| CORS errors | Update `FRONTEND_URL` in backend |
| Xero OAuth fails | Check `XERO_REDIRECT_URI` |
| Can't connect | Verify `API_BASE_URL` in frontend |
| Token refresh fails | Reconnect Xero account |

**Full Troubleshooting**: See [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## ✅ Features Checklist

- [x] GLM-4-Flash AI integration
- [x] Xero OAuth 2.0 flow
- [x] Invoice/quotation creation
- [x] Chat conversation history
- [x] Token refresh handling
- [x] Responsive UI design
- [x] Error handling
- [x] Production deployment guide
- [x] Example messages
- [x] Complete documentation

---

## 🚀 Next Steps

1. **Get API Keys** - GLM-4-Flash, Xero
2. **Deploy Backend** - To Render
3. **Deploy Frontend** - To Netlify
4. **Configure Xero** - Set redirect URI
5. **Test** - Try example messages
6. **Customize** - Add your branding

---

## 📞 Support

- **Xero API**: https://developer.xero.com/documentation/
- **GLM-4-Flash**: https://open.bigmodel.cn/dev/api
- **Render**: https://render.com/docs
- **Netlify**: https://docs.netlify.com/

---

## 📄 License

ISC License

---

## 🙏 Credits

Built with:
- GLM-4-Flash by Zhipu AI
- Xero Accounting API
- Render & Netlify hosting

---

**Version**: 1.0.0
**Last Updated**: 2026-01-29
