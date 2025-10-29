<div align="center">

# 🔮 Word Predictor 
### *Advanced N-gram Language Modeling Engine*

[![R](https://img.shields.io/badge/R-4.5%2B-blue?style=for-the-badge&logo=r)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-Interactive-00d4ff?style=for-the-badge&logo=rstudio)](https://shiny.rstudio.com/)
[![Status](https://img.shields.io/badge/Status-Active-00ff88?style=for-the-badge)](https://github.com)
[![License](https://img.shields.io/badge/License-Academic-ff0080?style=for-the-badge)](LICENSE)

*🎯 Word prediction engine with dual algorithm architecture*

[🚀 Quick Start](#-quick-start) • [📊 Features](#-features) • [🔧 Installation](#-installation) • [📖 Documentation](#-documentation)

---

![Word Predictor Demo](https://via.placeholder.com/800x400/0a0a0f/00ff88?text=WORD+PREDICTOR+DEMO)

</div>

## 🚀 Quick Start

```bash
# 🎯 Launch with auto-configuration
Rscript run_app.R                    # Default port 8080
Rscript run_app.R 3838              # Custom port

# 🛑 Stop application  
./stop_app.sh                       # Graceful shutdown
```

### Alternative Methods

<details>
<summary>🔧 <strong>Advanced Launch Options</strong></summary>

#### Method 1: Direct R Command
```r
shiny::runApp(host='0.0.0.0', port=8080)
```

#### Method 2: RStudio Integration
1. Open `server.R` or `ui.R` in RStudio
2. Click **"Run App"** button
3. App launches in viewer pane

#### Method 3: Terminal Background
```bash
nohup Rscript run_app.R &           # Background process
tail -f nohup.out                   # Monitor logs
```

</details>

## 📁 Project Structure

```
📦 word-redictor-app/
├── 🎮 server.R              # Server-side logic & algorithms
├── 🎨 ui.R                  # Cyberpunk UI interface
├── ⚙️  utils.R               # Core prediction utilities
├── 🚀 run_app.R             # Auto-launch script
├── 🛑 stop_app.sh           # Graceful shutdown
├── 📖 README.md             # This documentation
└── 🌐 www/                  # Web assets
    ├── 🎭 custom.css        # Cyberpunk theme
    └── ⚡ custom.js         # Interactive effects
```

## 🔧 Installation

### System Requirements
![R Version](https://img.shields.io/badge/R-4.5%2B-276DC3?style=flat-square&logo=r)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey?style=flat-square)

### 📦 R Dependencies
```r
# Core framework
install.packages(c("shiny", "dplyr", "DT"))

# Custom prediction engine
install.packages("Rcaptext")
```

### 🗃️ Data Requirements
```
📊 ../data/processed/
├── 🔤 uni_lookup.rds      # 52,718 unigrams
├── 🔗 bi_pruned.rds       # 183,284 bigrams  
└── 🧠 tri_pruned.rds      # 508,003 trigrams
```

> **Total Model Size:** 744K n-grams | **Memory:** ~12MB compressed

## 📊 Features

### 🧠 Dual Algorithm Architecture

<table>
<tr>
<td width="50%">

#### 🎯 **Stupid Backoff**
```
Fast & Efficient
├── 📈 O(1) lookup time
├── 🎛️ Alpha penalty tuning
├── 💾 Memory optimized
└── 🚀 <30ms predictions
```

</td>
<td width="50%">

#### 🧮 **Interpolated + IDF**
```
Advanced & Precise  
├── 🎯 Linear interpolation
├── 📊 IDF reranking boost
├── ⚙️  Lambda weight tuning
└── 🔬 Research-grade accuracy
```

</td>
</tr>
</table>

### ⚡ Performance Metrics

| Metric | Value | Status |
|--------|-------|--------|
| 🏃‍♂️ **Prediction Speed** | < 50ms | ![Fast](https://img.shields.io/badge/-FAST-00ff88) |
| 🧠 **Model Size** | 744K n-grams | ![Optimal](https://img.shields.io/badge/-OPTIMAL-00d4ff) |
| � **Memory Usage** | ~12MB | ![Efficient](https://img.shields.io/badge/-EFFICIENT-ff0080) |
| 🎯 **Accuracy** | Research-grade | ![High](https://img.shields.io/badge/-HIGH-00ff88) |

## 🌐 Access Points

Once launched, the application is available at:

| Environment | URL | Description |
|------------|-----|-------------|
| 🏠 **Local** | `http://localhost:8080` | Development access |
| 🌍 **Network** | `http://0.0.0.0:8080` | LAN/remote access |
| 🔧 **Custom** | `http://localhost:XXXX` | User-defined port |

## 🐛 Troubleshooting

<details>
<summary>🔍 <strong>Common Issues & Solutions</strong></summary>

### ❌ **Data Files Missing**
```bash
# Check data directory
ls -la ../data/processed/
# Expected: uni_lookup.rds, bi_pruned.rds, tri_pruned.rds
```

### ❌ **Package Not Found**
```r
# Install missing dependencies
install.packages(c("shiny", "dplyr", "DT", "Rcaptext"))
```

### ❌ **Port Already in Use**
```bash
# Check port usage
lsof -i :8080
# Kill conflicting process
kill -9 <PID>
```

### ❌ **Permission Denied**
```bash
# Make scripts executable
chmod +x run_app.R stop_app.sh
```

</details>

## 📖 Documentation

- 📋 **API Reference**: See inline code documentation
- 🎨 **UI Components**: Cyberpunk theme implementation
- 🧮 **Algorithms**: Detailed methodology in About tab
- 📊 **Performance**: Real-time metrics in application

---

<div align="center">

**🔮 Built with passion for NLP & cyberpunk aesthetics**

[![GitHub](https://img.shields.io/badge/GitHub-Kernel236-00ff88?style=for-the-badge&logo=github)](https://github.com/Kernel236)
[![Project](https://img.shields.io/badge/Project-Word%20Predictor-00d4ff?style=for-the-badge&logo=rstudio)](https://github.com/Kernel236/word-predictor)

*© 2025 N-gram Language Modeling Engine*

</div>

---
**© 2025 Word Predictor | N-gram Language Modeling**