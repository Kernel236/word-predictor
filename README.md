<div align="center">

# 🔮 Word Predictor: N-gram Language Model

[![R](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)](https://www.r-project.org/)
[![RStudio](https://img.shields.io/badge/RStudio-4285F4?style=for-the-badge&logo=rstudio&logoColor=white)](https://rstudio.com/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Kernel236/word-predictor)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![R Version](https://img.shields.io/badge/R-%3E%3D4.0-blue.svg?style=flat-square)](https://www.r-project.org/)
[![Project Status](https://img.shields.io/badge/Status-Active%20Development-green.svg?style=flat-square)](https://github.com/Kernel236/word-predictor)
[![Last Updated](https://img.shields.io/badge/Last%20Updated-October%202025-orange.svg?style=flat-square)](https://github.com/Kernel236/word-predictor)


</div>

---

## 🎯 Project Overview

This project implements a **next-word prediction model** based on statistical n-gram analysis. The system analyzes frequency patterns in unigrams, bigrams, and trigrams to build a predictive language model suitable for text completion applications.

## 🗂️ Repository Structure

```
word-predictor/
├── README.md                          # Main project documentation
├── .gitignore                        # Git ignore rules (includes rsconnect/)
├── data/
│   ├── raw/                          # SwiftKey corpora (git-ignored)
│   │   ├── en_US.blogs.txt           # English blogs (~200MB)
│   │   ├── en_US.news.txt            # English news (~200MB)
│   │   ├── en_US.twitter.txt         # English tweets (~160MB)
│   │   └── de_DE.* / fi_FI.* / ru_RU.*  # German, Finnish, Russian
│   └── processed/                    # Optimized model files (git-ignored)
│       ├── uni_lookup.rds            # Unigram lookup (52,718 terms)
│       ├── bi_pruned.rds             # Bigram model (183,284 pairs)
│       ├── tri_pruned.rds            # Trigram model (508,003 triplets)
│       └── lang_meta.rds             # Model metadata & statistics
├── R/
│   ├── eda.R                         # Exploratory data analysis
│   ├── build_lang_model.R            # Model construction pipeline
│   ├── predict_demo.R                # CLI prediction demo
│   ├── run-model&eval.R              # Model evaluation & benchmarking
│   └── run-interpolation-eval.R      # Interpolated algorithm evaluation
├── reports/
│   ├── eda.Rmd                       # Research report (R Markdown)
│   └── cache/                        # Computation cache (git-ignored)
├── docs/                             # 📖 GitHub Pages (Live Demo)
│   ├── index.html                    # Published EDA report
│   └── word-predictor-pitch.html     # Capstone presentation
├── presentation/                     # 🎓 Academic Presentation
│   ├── word-predictor-pitch.Rmd      # 5-slide capstone presentation
│   ├── custom-slides.css             # Optimized slide styling
│   ├── mock-data.R                   # Presentation data generation
│   ├── plot_algorithm_comparison.png # Real benchmark results
│   ├── plot_latency_summary_long_long.png # Performance metrics
│   ├── ScreenshotClassicbootstraptheme.png # App screenshots
│   └── ScreenshoyCyberpunktheme.png  # Theme demonstrations
├── results/                          # Performance evaluation data
│   ├── plot_accuracy_at_k_*.png      # Accuracy visualizations
│   ├── plot_algorithm_comparison.png # Algorithm benchmarks
│   ├── plot_latency_summary_*.png    # Performance analysis
│   └── plot_rank_hit_distribution_*.png # Prediction distributions
├── word-predictor-app/              # 🔮 Interactive Shiny Application
│   ├── README.md                     # App-specific documentation
│   ├── ui.R                          # Dual-theme interface (Classic/Cyberpunk)
│   ├── server.R                      # Prediction server logic  
│   ├── utils.R                       # Core algorithm functions (path-aware)
│   ├── run_app.R                     # Launch script
│   ├── .Rprofile                     # Shinyapps.io deployment config
│   ├── uni_lookup.rds                # Model files (deployment copies)
│   ├── bi_pruned.rds                 # Bigram model (for shinyapps.io)
│   ├── tri_pruned.rds                # Trigram model (for shinyapps.io)
│   └── www/                          # Web assets & visualizations
│       ├── custom.css                # Dual-theme styling system
│       ├── custom.js                 # Theme toggle & Easter eggs
│       └── plot_*.png                # Performance graphs (copied)
└── word-predictor.Rproj             # RStudio project (git-ignored)
```

## 📖 Methodology

### 1️⃣ Data Preprocessing
- 📚 **Corpus Loading**: Multi-source English text data (blogs, news, social media)
- 🧹 **Text Cleaning**: Standardization, tokenization, and quality filtering
- 🎯 **Sampling Strategy**: Stratified 5% sample maintaining source proportions

### 2️⃣ N-gram Analysis
- ✂️ **Tokenization**: Generation of unigrams, bigrams, and trigrams
- 📊 **Frequency Calculation**: Statistical analysis of term occurrence patterns
- 📈 **Coverage Analysis**: Vocabulary size requirements for different coverage thresholds

### 3️⃣ Statistical Validation
- 📏 **Zipf's Law Verification**: Confirming power-law distributions in natural language
- 🕳️ **Sparsity Assessment**: Understanding vocabulary growth with n-gram order
- ⚡ **Coverage Efficiency**: Determining optimal vocabulary sizes

## 📊 Key Findings

<div align="center">
| N-gram Type | 50% Coverage | 90% Coverage | Final Model Size |
|-------------|--------------|--------------|------------------|
| 🔤 **Unigrams** | ~100 terms | ~1,000 terms | 52,718 terms |
| 🔤🔤 **Bigrams** | ~1,000 terms | ~10,000 terms | 183,284 pairs |
| 🔤🔤🔤 **Trigrams** | ~10,000+ terms | ~100,000+ terms | 508,003 triplets |

**Total Model**: 744K n-grams | **Compressed Size**: ~12MB

</div>

## 🔮 Interactive Application

The project culminates in a **dual-theme Shiny application** with advanced prediction algorithms and interactive features:

### 🚀 Live Demo Features
- 🎯 **Real-time Predictions**: Instant word suggestions as you type
- 🧠 **Dual Algorithm Modes**: Stupid Backoff vs. Interpolated+IDF
- 📊 **Performance Metrics**: Live timing and accuracy statistics
- 🎨 **Dual Theme System**: Classic Bootstrap + Cyberpunk mode with smooth transitions
- ⚙️ **Tunable Parameters**: Alpha penalties, lambda weights, and more
- 🎮 **Easter Eggs**: Hidden Konami code for special effects
- 📱 **Responsive Design**: Works on desktop and mobile devices

### 🎨 Theme Features
| Theme | Style | Features |
|-------|-------|----------|
| **Classic** | Professional Bootstrap | Clean, accessible, business-ready |
| **Cyberpunk** | Neon + Dark | Futuristic aesthetics, glow effects, animations |
| **Rainbow Mode** | Special Effect | 6-second rainbow animation (Easter egg) |

### 📈 Performance Metrics
| Metric | Stupid Backoff | Interpolated+IDF |
|--------|---------------|------------------|
| **Average Latency** | ~30ms | ~45ms |
| **Memory Usage** | 12MB | 12MB |
| **Accuracy Mode** | Fast & Efficient | Research-grade |

> 📋 **Full app documentation**: [word-redictor-app/README.md](word-redictor-app/README.md)

## 🎓 Academic Presentation

The project includes a **professional 5-slide presentation** suitable for capstone project submissions and academic conferences:

### 📑 Presentation Structure
1. **Project Overview** - Problem statement and methodology
2. **N-gram Language Model** - Technical approach and algorithms  
3. **Performance Analysis** - Real benchmark results and timing data
4. **Interactive Demo** - Application features and screenshots
5. **Custom Rcaptext Package** - Technical contributions and GitHub link

### 🌐 Live Presentation
- **Location**: [`presentation/word-predictor-pitch.Rmd`](presentation/word-predictor-pitch.Rmd)
- **Online Version**: [GitHub Pages Presentation](https://kernel236.github.io/word-predictor/word-predictor-pitch.html)
- **Format**: ioslides with custom CSS for professional appearance
- **Features**: Real screenshots, performance graphs, and interactive elements

### 📊 Presentation Assets
- **Real Screenshots**: Both Classic and Cyberpunk themes
- **Performance Graphs**: Actual benchmark results from model evaluation
- **Model Statistics**: N-gram distribution and efficiency metrics
- **GitHub Integration**: Direct links to source code and documentation

## 🔄 Project Workflow

### Phase 1: Data Exploration ✅
- **Script**: `R/eda.R`
- **Report**: `reports/eda.Rmd` → `docs/index.html`
- **Purpose**: Statistical analysis, Zipf's law validation, coverage optimization
- **Output**: [📊 EDA Report](https://kernel236.github.io/word-predictor/)

### Phase 2: Model Building ✅
- **Script**: `R/build_lang_model.R`
- **Output**: Optimized n-gram lookup tables (744K total terms)
- **Features**: Frequency pruning, back-off structure, memory optimization
- **Size**: ~12MB compressed model

### Phase 3: Algorithm Development ✅
- **Scripts**: `R/predict_demo.R`, `R/run-model&eval.R`
- **Algorithms**: Stupid Backoff + Interpolated IDF
- **Performance**: <50ms prediction latency, research-grade accuracy
- **Evaluation**: Comprehensive benchmarking with visualizations

### Phase 4: Interactive Application ✅
- **Location**: `word-predictor-app/`
- **Features**: Dual-theme system, dual algorithm modes, real-time metrics
- **Deployment**: Local development + shinyapps.io production ready
- **Tech Stack**: Shiny + custom CSS/JS + Rcaptext engine

### Phase 5: Academic Presentation ✅
- **Location**: `presentation/word-predictor-pitch.Rmd`
- **Format**: Professional 5-slide ioslides presentation
- **Content**: Real data, screenshots, performance benchmarks
- **Publishing**: GitHub Pages integration for online access

## 🚀 Quick Start

### Prerequisites
```bash
# R version 4.0+ required
R --version
```

### Installation
```bash
# Clone the repository
git clone https://github.com/Kernel236/word-predictor.git
cd word-predictor

# Open RStudio project
open word-predictor.Rproj
```

### Run Complete Pipeline
```r
# 1. Exploratory Data Analysis
source("R/eda.R")

# 2. Build optimized language model
source("R/build_lang_model.R")

# 3. Test CLI prediction demo
source("R/predict_demo.R")

# 4. Run evaluation benchmarks
source("R/run-model&eval.R")

# 5. Launch interactive app
setwd("word-predictor-app")
source("run_app.R")  # Opens at http://localhost:8080

# 6. Generate academic presentation
setwd("../presentation")
rmarkdown::render("word-predictor-pitch.Rmd")
```

### Quick App Launch
```bash
# Navigate to app directory
cd word-predictor-app/

# Launch with default settings
Rscript run_app.R

# Or with custom port
Rscript run_app.R 3838
```

### Quick Presentation Build
```bash
# Navigate to presentation directory
cd presentation/

# Render presentation to HTML
Rscript -e "rmarkdown::render('word-predictor-pitch.Rmd')"

# Open in browser (Linux/Mac)
open word-predictor-pitch.html
```

## ⚙️ Technical Dependencies

### 📦 R Packages
```r
# Core dependencies
library(Rcaptext)  # 🛠️ Custom text processing and n-gram analysis
library(dplyr)     # 📊 Data manipulation and transformation  
library(tidyr)     # 🔄 Data reshaping and organization
library(ggplot2)   # 📈 Statistical visualization
library(knitr)     # 📖 Report generation
```

### 💻 System Requirements
- 🖥️ **RAM**: Minimum 1GB available for processing
- 📊 **R Version**: 4.0+ recommended
- 📚 **Data**: English US text corpora (included in raw data)
- 💾 **Storage**: ~500MB for processed frequency tables
- 🌐 **Deployment**: Model files duplicated in app/ for shinyapps.io compatibility

## � Rcaptext Package: Custom Text Processing Engine

This project is powered by **Rcaptext**, a specialized R package developed specifically for text processing and n-gram analysis. The package provides a suite of functions tailored for natural language processing tasks of this project.

### 🌟 Key Features (so far...)

- 📚 **`load_corpus()`** - Efficient multi-file corpus loading with automatic source tagging
- 🧹 **`clean_text()`** - Advanced text preprocessing with configurable cleaning rules
- 🎲 **`sample_corpus()`** - Stratified sampling maintaining source proportions
- ✂️ **`tokenize_unigrams()`**, **`tokenize_bigrams()`**, **`tokenize_trigrams()`** - Optimized n-gram tokenization
- 📊 **`freq_unigrams()`**, **`freq_bigrams()`**, **`freq_trigrams()`** - Statistical frequency analysis
- 📈 **`coverage_from_freq()`** - Coverage analysis at specified thresholds
- 🎨 **`plot_top_terms()`**, **`plot_rank_frequency()`**, **`plot_cumulative_coverage()`** - Rich visualization functions

### 📦 Installation & Usage

```r
# Install development version
devtools::install_github("Kernel236/Rcaptext")

# Load the package
library(Rcaptext)

# Example workflow
corpus <- load_corpus("en_US", base_dir = "data/raw")
clean_corpus <- clean_text(corpus$text)
sample_data <- sample_corpus(corpus, prop = 0.05)
```

> 🔬 **Development Status**: Rcaptext is actively developed alongside this project, with new features and optimizations added based on real-world text processing needs.

## �📋 Advanced Usage

### 🔬 Running the Analysis
```r
# Load the project and run full analysis
source("R/eda.R")

# Generate EDA report (uses caching for improved performance)
rmarkdown::render("reports/eda.Rmd")

# Clear cache if needed (for fresh run)
knitr::clean_cache("reports/eda.Rmd")
```

> 💡 **Performance Tip**: The R Markdown report uses intelligent caching to optimize knitting performance.
> 
> - ⏱️ **First run**: Full processing time (may take several minutes)  
> - ⚡ **Subsequent runs**: Much faster execution using cached results
> - 📁 **Cache location**: `reports/cache/` directory (ignored by git)

### 📊 Using Processed Data
```r
# Load pre-computed frequency tables
freq_uni <- readRDS("data/processed/freq_uni_en_top100k.rds")
freq_bi  <- readRDS("data/processed/freq_bi_top100k.rds")
freq_tri <- readRDS("data/processed/freq_tri_top100k.rds")
```

## 🚀 Performance & Optimization

### 🎯 Model Performance
Based on comprehensive evaluation with `R/run-model&eval.R`:

- **Prediction Speed**: <50ms average latency
- **Model Size**: 744K n-grams compressed to ~12MB  
- **Memory Efficiency**: Optimized lookup structures
- **Accuracy**: Research-grade precision with proper back-off

### 📊 Benchmark Results
Performance data available in `results/` directory:

- � **Accuracy at K**: Hit rates for top-1, top-3, top-5 predictions
- ⏱️ **Latency Analysis**: Response time distributions and percentiles
- 🎯 **Rank Distribution**: Where correct predictions typically appear
- 📋 **Detailed CSVs**: `timing_summary_*.csv`, `hit_breakdown_*.csv`

### 💾 Technical Optimizations
- � **Smart Caching**: Knitr-based computation caching for development
- � **Frequency Pruning**: Removes low-frequency n-grams below thresholds
- 📦 **Compressed Storage**: RDS serialization for efficient I/O
- 🧠 **Memory Management**: Strategic sampling and garbage collection


## 🤝 Contributing

Contributions are welcome! Please ensure all code follows the established style conventions and includes appropriate documentation.

### 💡 How to Contribute
1. 🍴 Fork the repository
2. 🌟 Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. 💾 Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. 📤 Push to the branch (`git push origin feature/AmazingFeature`)
5. 🔄 Open a Pull Request

## 📄 License

This project is developed for educational and research purposes. Please respect the licensing terms of the original corpora datasets.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

<div align="center">

### 👨‍💻 Author

**Kernel236**

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Kernel236)

---

*Last Updated: October 29, 2025 | Project Status: 🟢 Complete & Deployed*

</div>