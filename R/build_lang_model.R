# ==============================================================================
# Language Model Builder for Next-Word Prediction
# ==============================================================================
# This script builds a production-ready n-gram language model optimized for
# real-time word prediction. The pipeline includes corpus loading, cleaning,
# sampling, tokenization, frequency analysis, pruning, and model export.
#
# Output: Pruned conditional probability lookup tables (RDS format)
# Author: Kernel236
# Created: 2025
# ==============================================================================

# Load required libraries
library(Rcaptext)  # Custom text processing and n-gram functions
library(dplyr)     # Data manipulation
library(here)      # Project-relative paths

# ==============================================================================
# CONFIGURATION PARAMETERS
# ==============================================================================

# --- Corpus Configuration ---
LANG            <- "en_US"        # Language/locale for corpus loading
RAW_DIR         <- "data/raw"     # Raw text data directory
OUT_DIR         <- "data/processed"  # Output directory for model files

# --- Sampling Parameters ---
SEED            <- 123            # Random seed for reproducibility
PROP_SAMPLE     <- 0.10          # Sample proportion per source (10% = faster, less RAM)
MIN_CHARS       <- 5             # Minimum characters per text for quality control

# --- Pruning Thresholds ---
# These parameters control model size vs. coverage trade-off
MIN_COUNT_BI    <- 2             # Minimum frequency to keep bigram
MIN_COUNT_TRI   <- 2             # Minimum frequency to keep trigram
TOPN_BI         <- 12            # Top-N bigrams to keep per context word
TOPN_TRI        <- 8             # Top-N trigrams to keep per context pair

# --- Backoff Parameter ---
ALPHA_BACKOFF   <- 0.4           # Stupid backoff penalty (used in prediction)

# ==============================================================================
# 1. CORPUS LOADING AND TEXT PREPROCESSING
# ==============================================================================

message(">> Loading corpus: ", LANG)
# Load multi-file corpus with automatic source tagging (blogs, news, twitter)
corpus_raw <- load_corpus(LANG, base_dir = RAW_DIR)

message(">> Cleaning text")
# Apply comprehensive text cleaning pipeline:
# - Lowercase normalization
# - Special character handling
# - Whitespace normalization
# - Profanity filtering (optional)
corpus <- corpus_raw %>%
  mutate(text_clean = clean_text(text))

# Memory cleanup - remove raw corpus to free RAM
rm(corpus_raw)
gc()  # Force garbage collection

# ==============================================================================
# 2. STRATIFIED CORPUS SAMPLING
# ==============================================================================

message(">> Sampling corpus by source (prop = ", PROP_SAMPLE, ")")
# Create balanced sample maintaining proportional representation across sources
# This reduces memory footprint while preserving statistical properties
set.seed(SEED)
small <- sample_corpus(
  corpus,
  prop = PROP_SAMPLE,    # Sample 10% from each source
  min_chars = MIN_CHARS, # Filter out very short texts
  seed = SEED            # Ensure reproducibility
)

# Memory cleanup - remove full corpus
rm(corpus)
gc()

# ==============================================================================
# 3. N-GRAM TOKENIZATION AND FREQUENCY ANALYSIS
# ==============================================================================

message(">> Tokenize & frequencies (UNI/BI/TRI)")

# --- Unigrams: Individual words ---
# Generate unigram tokens and calculate frequency distribution
uni <- tokenize_unigrams(small, text_col = "text_clean")
freq_uni <- freq_unigrams(uni)  # Returns: word, n (count), p (probability)
rm(uni)  # Free memory immediately after use

# --- Bigrams: Word pairs ---
# Generate bigram tokens and calculate conditional probabilities
bi  <- tokenize_bigrams(small, text_col = "text_clean")
freq_bi  <- freq_bigrams(bi)    # Returns: w1, w2, n, p (global probability)
rm(bi)

# --- Trigrams: Word triplets ---
# Generate trigram tokens and calculate conditional probabilities
tri <- tokenize_trigrams(small, text_col = "text_clean")
freq_tri <- freq_trigrams(tri)  # Returns: w1, w2, w3, n, p (global probability)
rm(tri)
gc()  # Clean up all tokenization objects

# ==============================================================================
# 4. VOCABULARY FILTERING (OPTIONAL)
# ==============================================================================

message(">> Filtering likely non-English unigrams")
# Apply language-specific filtering to remove:
# - Non-English words and misspellings
# - Very short tokens (likely typos)
# - Preserves stopwords (essential for natural language)
# - Re-normalizes probabilities after filtering
freq_uni_en <- filter_non_english_unigrams(
  freq_uni, 
  dict = "en_US",          # Use English US dictionary
  min_len = 2,             # Minimum word length
  keep_stopwords = TRUE    # Retain function words
)

# ==============================================================================
# 5. MODEL BUILDING WITH PRUNING AND EXPORT
# ==============================================================================

message(">> Building pruned language model and saving RDS")
# Build optimized language model with aggressive pruning for production use
# This function:
# 1. Converts global probabilities to conditional probabilities P(w|context)
# 2. Applies frequency thresholds to remove rare n-grams
# 3. Keeps only top-N predictions per context for memory efficiency
# 4. Exports separate lookup tables for fast prediction
lm_obj <- build_pruned_lang_model(
  freq_uni = freq_uni_en,
  freq_bi  = freq_bi,
  freq_tri = freq_tri,
  min_count_bi  = MIN_COUNT_BI,   # Remove bigrams with count < 2
  min_count_tri = MIN_COUNT_TRI,  # Remove trigrams with count < 2
  topN_bi  = TOPN_BI,             # Keep top 12 bigrams per w1
  topN_tri = TOPN_TRI,            # Keep top 8 trigrams per (w1, w2)
  save     = TRUE,                # Auto-save lookup tables as RDS
  out_dir  = OUT_DIR              # Output directory
)

# Memory cleanup - remove large frequency tables
rm(freq_uni_en, freq_bi, freq_tri, freq_uni)
gc()

# ==============================================================================
# 6. MODEL STATISTICS AND REPORTING
# ==============================================================================

# Display model size statistics (before/after pruning)
print(lm_obj$meta$sizes)

message(">> Model building completed successfully!")
message(">> Output files saved to: ", here::here(OUT_DIR))
message(">> Files created:")
message("   - uni_lookup.rds  : Unigram fallback probabilities")
message("   - bi_pruned.rds   : Pruned bigram conditional probabilities")
message("   - tri_pruned.rds  : Pruned trigram conditional probabilities")

# ==============================================================================
# END OF SCRIPT
# ==============================================================================