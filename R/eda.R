# ==============================================================================
# Exploratory Data Analysis for Word Prediction Project
# ==============================================================================
# This script performs comprehensive exploratory data analysis on text corpus
# to understand n-gram frequency distributions and coverage patterns.
# Author: Kernel236
# Created: 2025
# ==============================================================================

# Load required libraries
library(Rcaptext)  # Custom text processing functions
library(dplyr)     # Data manipulation

# ==============================================================================
# 1. DATA LOADING AND PREPROCESSING
# ==============================================================================

# Load the English US corpus from raw data directory
corpus_raw <- load_corpus("en_US", base_dir = "data/raw")

# Clean text data using custom preprocessing functions
corpus <- corpus_raw %>%
  mutate(text_clean = clean_text(text))

# Verify data integrity - check source distribution
print("Original corpus distribution by source:")
print(corpus %>% count(source))

# Create reproducible sample for analysis (5% of total corpus)
# Using minimum character threshold to ensure quality samples
set.seed(123)  # For reproducible sampling
small <- sample_corpus(corpus, prop = 0.05, min_chars = 5)

# Verify sample distribution maintains original proportions
print("Sample corpus distribution by source:")
print(small %>% count(source))

# Memory cleanup - remove large objects no longer needed
rm(corpus_raw, corpus)
gc()  # Force garbage collection


# ==============================================================================
# 2. N-GRAM TOKENIZATION
# ==============================================================================

# Generate n-grams from cleaned text corpus
# Each tokenization preserves word boundaries and maintains sequence order
uni <- tokenize_unigrams(small, text_col = "text_clean")   # Single words
bi  <- tokenize_bigrams(small,  text_col = "text_clean")   # Word pairs
tri <- tokenize_trigrams(small, text_col = "text_clean")   # Word triplets

# ==============================================================================
# 3. FREQUENCY ANALYSIS
# ==============================================================================

# Calculate frequency distributions for each n-gram type
# Returns: word/phrase, count (n), and probability (p) for each term
freq_uni <- freq_unigrams(uni)    # Columns: word, n, p
freq_bi  <- freq_bigrams(bi)      # Columns: w1, w2, n, p (combined as 'word')
freq_tri <- freq_trigrams(tri)    # Columns: w1, w2, w3, n, p (combined as 'word')

# ==============================================================================
# 4. COVERAGE ANALYSIS
# ==============================================================================

# Calculate coverage statistics to understand how many unique terms are needed
# to capture 50% and 90% of total probability mass
# This helps determine vocabulary size requirements for prediction models

cov_uni <- coverage_from_freq(freq_uni, thresholds = c(0.5, 0.9), name_col = "word")$summary |>
  dplyr::mutate(type = "unigrams")
cov_bi  <- coverage_from_freq(freq_bi,  thresholds = c(0.5, 0.9))$summary |>
  dplyr::mutate(type = "bigrams")
cov_tri <- coverage_from_freq(freq_tri, thresholds = c(0.5, 0.9))$summary |>
  dplyr::mutate(type = "trigrams")

# Create summary table comparing coverage across n-gram types
coverage_table <- dplyr::bind_rows(cov_uni, cov_bi, cov_tri) |>
  dplyr::select(type, threshold, n_unique) |>
  tidyr::pivot_wider(names_from = threshold, values_from = n_unique, names_prefix = "cov_")

print("Coverage Analysis Summary:")
print("Number of unique terms needed to achieve specified coverage thresholds:")
print(coverage_table)

# ==============================================================================
# 5. VISUALIZATION AND ANALYSIS
# ==============================================================================

# Generate comprehensive visualizations to understand n-gram distributions

# --- UNIGRAM ANALYSIS ---
print("Generating unigram visualizations...")

# Top 25 most frequent unigrams (dominated by stopwords - expected behavior)
plot_top_terms(freq_uni, top = 25, name_col = "word")

# Zipf's law verification: rank-frequency plot should show linear relationship in log-log scale
plot_rank_frequency(freq_uni, top = 10000, name_col = "word", p_col = "p")

# Cumulative coverage curve with threshold markers (50% and 90% coverage points)
plot_cumulative_coverage_with_marks(freq_uni, thresholds = c(0.5, 0.9))

# --- BIGRAM ANALYSIS ---
print("Generating bigram visualizations...")

# Most frequent word pairs - reveals common phrases and collocations
plot_top_terms(freq_bi, top = 25, name_col = "word")

# Zipf's law for bigrams - typically shows steeper decline than unigrams
plot_rank_frequency(freq_bi, top = 10000, name_col = "word", p_col = "p")

# Coverage analysis for bigrams - requires more terms for same coverage level
plot_cumulative_coverage_with_marks(freq_bi, thresholds = c(0.5, 0.9))

# --- TRIGRAM ANALYSIS ---
print("Generating trigram visualizations...")

# Most frequent three-word sequences - captures longer phrases and expressions
plot_top_terms(freq_tri, top = 25, name_col = "word")

# Rank-frequency for trigrams - shows sparsity challenges for longer n-grams
plot_rank_frequency(freq_tri, top = 10000, name_col = "word", p_col = "p")

# Coverage analysis reveals vocabulary explosion problem for trigrams
plot_cumulative_coverage_with_marks(freq_tri, thresholds = c(0.5, 0.9))

# ==============================================================================
# 6. DATA EXPORT FOR MODEL BUILDING
# ==============================================================================

# Save processed frequency tables for use in prediction algorithms
# These files will serve as the foundation for n-gram language models

print("Saving frequency tables to processed data directory...")

# Export frequency distributions (keeping top 100k most frequent terms)
saveRDS(freq_uni, "data/processed/freq_uni_en_top100k.rds")  # Unigram frequencies
saveRDS(freq_bi,  "data/processed/freq_bi_top100k.rds")     # Bigram frequencies  
saveRDS(freq_tri, "data/processed/freq_tri_top100k.rds")    # Trigram frequencies

print("EDA completed successfully!")
print("Frequency tables saved to data/processed/ directory")
