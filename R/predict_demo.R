# ==============================================================================
# Next-Word Prediction Demonstration Script
# ==============================================================================
# This script demonstrates how to use pre-trained language model files for
# real-time next-word prediction using Stupid Backoff algorithm.
#
# Requirements: Run build_lang_model.R first to generate RDS lookup tables
# Author: Kernel236
# Created: 2025
# ==============================================================================

# Load required libraries
library(Rcaptext)  # Custom prediction functions
library(dplyr)     # Data manipulation
library(here)      # Project-relative paths

# ==============================================================================
# CONFIGURATION
# ==============================================================================

OUT_DIR <- "data/processed"  # Directory containing model files
ALPHA   <- 0.4              # Stupid backoff penalty parameter
TOP_K   <- 5                # Number of top predictions to return

# ==============================================================================
# 1. LOAD PRE-TRAINED MODEL LOOKUP TABLES
# ==============================================================================

message(">> Loading pre-trained language model...")

# Load unigram lookup table (fallback probabilities)
# Structure: next (word), p (probability)
uni_lookup <- readRDS(here::here(OUT_DIR, "uni_lookup.rds"))

# Load pruned bigram conditional probabilities
# Structure: w1 (context), w2 (next word), n (count), p_cond (P(w2|w1))
bi_pruned  <- readRDS(here::here(OUT_DIR, "bi_pruned.rds"))

# Load pruned trigram conditional probabilities  
# Structure: w1, w2 (context), w3 (next word), n (count), p_cond (P(w3|w1,w2))
tri_pruned <- readRDS(here::here(OUT_DIR, "tri_pruned.rds"))

message(">> Model loaded successfully!")

# ==============================================================================
# 2. PREDICTION FUNCTION
# ==============================================================================

# The predict_next() function implements Stupid Backoff algorithm:
# 1. Try trigram: P(w|w1,w2) if context has 2+ words
# 2. Backoff to bigram: α * P(w|w2) if trigram not found
# 3. Backoff to unigram: α² * P(w) if bigram not found
# 
# Function signature:
# predict_next(input, tri_pruned, bi_pruned, uni_lookup, alpha = 0.4, top_k = 3)
#
# This function is provided by the Rcaptext package

# ==============================================================================
# 3. DEMONSTRATION QUERIES
# ==============================================================================

message(">> Running prediction examples...")

# Define test queries covering different scenarios
queries <- c(
  "When you breathe, I want to be the air for you. I'll be there for you, I'd live and I'd",         # Common bigram context
  "Guy at my table's wife got up to go to the bathroom and I asked about dessert and he started telling me about his",         # Preposition phrase
  "I'd give anything to see arctic monkeys this",         
  "Talking to your mom has the same effect as a hug and helps reduce your",     # Polite expression
  "When you were in Holland you were like 1 inch away from me but you hadn't time to take a",       
  "I'd just like all of these questions answered, a presentation of evidence, and a jury to settle the",
  "I can't deal with unsymetrical things. I can't even hold an uneven number of bags of groceries in each",
  "Every inch of you is perfect from the bottom to the",
  "I’m thankful my childhood was filled with imagination and bruises from playing",
  "I like how the same people are in almost all of Adam Sandler's"
)

# Run predictions for all queries
res <- lapply(queries, function(q) {
  tibble::tibble(
    input = q,
    prediction = list(
      predict_next(
        q, 
        tri_pruned, 
        bi_pruned, 
        uni_lookup,
        alpha = ALPHA,   # Backoff penalty
        top_k = TOP_K    # Number of predictions
      )
    )
  )
}) %>% dplyr::bind_rows()

# ==============================================================================
# 4. RESULTS DISPLAY
# ==============================================================================

# Expand nested predictions into long format for easy viewing
res_long <- res %>%
  tidyr::unnest(prediction)

# Display results
message("\n>> Prediction Results:")
message("   Format: input phrase -> predicted next words (with scores)")
print(res_long)

# ==============================================================================
# EXAMPLE OUTPUT INTERPRETATION
# ==============================================================================
# 
# For input "i love", the model might predict:
#   - "you" (score: 0.15)   -> trigram or bigram match
#   - "it" (score: 0.12)    -> high-frequency continuation
#   - "the" (score: 0.08)   -> common article
#
# Higher scores indicate more likely next words based on training data.
# Scores combine conditional probabilities with backoff penalties.
#
# ==============================================================================
# END OF SCRIPT
# ==============================================================================