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
├── README.md                    # Project documentation
├── word-predictor.Rproj        # RStudio project configuration
├── data/
│   ├── raw/                    # Original text corpora
│   │   ├── en_US.blogs.txt     # Blog posts corpus
│   │   ├── en_US.news.txt      # News articles corpus
│   │   ├── en_US.twitter.txt   # Twitter messages corpus
│   │   └── [other languages]   # Additional language datasets
│   └── processed/              # Processed frequency tables
│       ├── freq_uni_en_top100k.rds  # Unigram frequencies
│       ├── freq_bi_top100k.rds       # Bigram frequencies
│       └── freq_tri_top100k.rds      # Trigram frequencies
├── R/
│   └── eda.R                   # Exploratory data analysis script
├── reports/
│   ├── eda.Rmd                # EDA report and visualizations
│   └── cache/                 # Cached computation results (git-ignored)
└── app/                       # [Future] Shiny application
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

| N-gram Type | 50% Coverage | 90% Coverage | Key Insight |
|-------------|--------------|--------------|-------------|
| 🔤 **Unigrams** | ~100 terms | ~1,000 terms | High efficiency |
| 🔤🔤 **Bigrams** | ~1,000 terms | ~10,000 terms | Moderate growth |
| 🔤🔤🔤 **Trigrams** | ~10,000+ terms | ~100,000+ terms | Exponential explosion |

</div>

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

### Run Analysis
```r
# Load and run full analysis
source("R/eda.R")

# Generate interactive report
rmarkdown::render("reports/eda.Rmd")
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

## 🚀 Performance Optimization

### 💾 Caching System
- 🔄 **Automatic Caching**: Heavy computations cached using knitr's caching system
- 🎯 **Dependency Tracking**: Smart cache invalidation based on chunk dependencies  
- 📁 **Storage**: Cache files in `reports/cache/` (excluded from version control)
- ⚡ **Benefits**: Reduces report generation from minutes to seconds after first run

### 🧠 Memory Management
- 🗑️ **Garbage Collection**: Automatic cleanup of large temporary objects
- 🎲 **Strategic Sampling**: Uses 5% corpus sample for optimal analysis depth vs performance
- 📦 **Efficient Storage**: RDS format for compressed serialization of frequency tables


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

*Last Updated: October 2025 | Project Status: 🟢 Active Development*

</div>