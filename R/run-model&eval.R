# scripts/run_model_build_and_eval.R
# Pipeline completa: split -> build model -> test windows -> eval -> export risultati

# ---- Librerie ----
library(Rcaptext)
library(dplyr)
library(here)
library(ggplot2)
library(readr)
library(tidyr)

# ---- Parametri generali ----
LANG             <- "en_US"
RAW_DIR          <- "data/raw"          # dove hai i txt (già usato in load_corpus)
OUT_DIR          <- "data/processed"    # dove salvi RDS del modello
RESULTS_DIR      <- "results"           # dove salvi CSV/PNG con metriche/plot

SEED             <- 123
PROP_TEST        <- 0.05   
TEST_PROP_ROWS   <- 0.5    
MIN_WORDS_TEST   <- 3      # minimo 3 parole per riga per generare trigrammi

# Parametri di build (training)
ENSURE_CLEAN     <- TRUE
MIN_CHARS        <- 1
SAMPLE_PROP_TRAIN<- 0.12   # 10% del TRAIN per ridurre RAM
OOV_FILTER       <- TRUE
DICT             <- "en_US"
MIN_LEN_OOV      <- 2
KEEP_STOPWORDS   <- TRUE

# Pruning
MIN_COUNT_BI     <- 2
MIN_COUNT_TRI    <- 2
TOPN_BI          <- 12
TOPN_TRI         <- 8

# Predizione / valutazione
ALPHA            <- 0.4
KS               <- c(1, 2, 3)
TIMEIT           <- TRUE
TIMING_N         <- 300
MAX_EVAL_CASES   <- 10000   # NULL = tutti, oppure 10000 per velocità

# UI Settings
USE_PROGRESS     <- TRUE   # Progress bars con progressr + cli

# ---- Setup cartelle output ----
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)
if (!dir.exists(RESULTS_DIR)) dir.create(RESULTS_DIR, recursive = TRUE, showWarnings = FALSE)

# ---- 1) Carica corpus e assicurati che abbia text_clean ----
message(">> Loading full corpus and ensuring text_clean ...")
corpus_raw <- load_corpus(LANG, base_dir = RAW_DIR)
corpus <- corpus_raw %>%
  mutate(text_clean = clean_text(text))
rm(corpus_raw); gc()

# ---- 2) Split train/test a livello riga (stratificato per source) ----
message(">> Splitting train/test (prop_test = ", PROP_TEST, ") ...")
split <- split_corpus(corpus, prop_test = PROP_TEST, by_source = TRUE, seed = SEED)
train <- split$train
test  <- split$test
rm(corpus); rm(split); gc()

# ---- 3) Build modello sul TRAIN (salva RDS) ----
message(">> Building model on TRAIN ...")

# Setup progressr handler (opzionale, solo se USE_PROGRESS = TRUE)
if (USE_PROGRESS) {
  progressr::handlers(global = TRUE)
  progressr::handlers("cli")
}

model_obj <- build_model(
  train_corpus   = train,
  text_col       = "text_clean",
  ensure_clean   = ENSURE_CLEAN,
  min_chars      = MIN_CHARS,
  sample_prop    = SAMPLE_PROP_TRAIN,
  seed           = SEED,
  oov_filter     = OOV_FILTER,
  dict           = DICT,
  min_len_oov    = MIN_LEN_OOV,
  keep_stopwords = KEEP_STOPWORDS,
  min_count_bi   = MIN_COUNT_BI,
  min_count_tri  = MIN_COUNT_TRI,
  topN_bi        = TOPN_BI,
  topN_tri       = TOPN_TRI,
  out_dir        = OUT_DIR,
  save           = TRUE,
  return_freq    = FALSE,
  use_progress   = USE_PROGRESS  
)

# ---- 4) Prepara il TEST set di finestre (w1,w2 -> target) ----
message(">> Building test windows from TEST ...")
test_windows <- make_test_trigrams(
  corpus          = test,
  text_col        = "text_clean",
  prop            = TEST_PROP_ROWS,
  seed            = SEED,
  min_words       = MIN_WORDS_TEST,
  by_source       = TRUE,
  drop_na_targets = TRUE,
  use_progress    = USE_PROGRESS  
)

# ---- 5) Carica gli RDS del modello (o usa model_obj$*) ----
uni_lookup <- readRDS(here::here(OUT_DIR, "uni_lookup.rds"))
bi_pruned  <- readRDS(here::here(OUT_DIR, "bi_pruned.rds"))
tri_pruned <- readRDS(here::here(OUT_DIR, "tri_pruned.rds"))
rm(model_obj); gc()

# ---- 6) Valuta accuracy@k e timing ----
message(">> Evaluating model ...")
eval_res <- evaluate_accuracy_at_k(
  test_windows    = test_windows,
  tri_pruned      = tri_pruned,
  bi_pruned       = bi_pruned,
  uni_lookup      = uni_lookup,
  alpha           = ALPHA,
  ks              = KS,
  timeit          = TIMEIT,
  timing_n        = TIMING_N,
  seed            = SEED,
  max_eval_cases  = MAX_EVAL_CASES,  
  use_progress    = USE_PROGRESS     
)

# ---- 7) Tabelle e Plot ----
message(">> Generating results tables and plots ...")

# Accuracy table
acc_tbl <- eval_res$accuracy %>%
  mutate(accuracy_pct = paste0(round(accuracy*100, 1), "%"))
readr::write_csv(acc_tbl, file = here::here(RESULTS_DIR, "accuracy_at_k.csv"))

# Timing summary
if (!is.null(eval_res$timing)) {
  timing_tbl <- eval_res$timing %>%
    mutate(across(everything(), ~round(., 2)))
  readr::write_csv(timing_tbl, file = here::here(RESULTS_DIR, "timing_summary.csv"))
}

# Hit breakdown
Kmax <- max(eval_res$accuracy$k)
pred_cols <- paste0("pred", seq_len(Kmax))
per_case <- eval_res$per_case

per_case$hit_top1 <- per_case$pred1 == per_case$target
per_case$hit_any  <- apply(per_case[pred_cols], 1, function(row) {
  target_val <- per_case$target[as.integer(rownames(as.data.frame(t(row))))]
  any(row == target_val, na.rm = TRUE)
})

hit_breakdown <- tibble::tibble(
  metric = c("Top-1 hits", "Top-K hits", "Total cases"),
  value  = c(sum(per_case$hit_top1, na.rm = TRUE),
             sum(per_case$hit_any,  na.rm = TRUE),
             nrow(per_case))
)
readr::write_csv(hit_breakdown, file = here::here(RESULTS_DIR, "hit_breakdown.csv"))

# ---- 8) Plot base (salvati come PNG) ----

# Accuracy@k
p_acc <- ggplot(eval_res$accuracy, aes(x = factor(k), y = accuracy)) +
  geom_col(fill = "steelblue", width = 0.65) +
  geom_text(aes(label = scales::percent(accuracy, accuracy = 0.1)), 
            vjust = -0.3, size = 3.5) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), 
                     limits = c(0, max(eval_res$accuracy$accuracy) * 1.15)) +
  labs(x = "k", y = "Accuracy", 
       title = "Accuracy@k",
       subtitle = paste0("Evaluated on ", nrow(per_case), " test cases")) +
  theme_minimal()
ggsave(filename = here::here(RESULTS_DIR, "plot_accuracy_at_k.png"), 
       plot = p_acc, width = 6, height = 4, dpi = 150)

# Distribuzione rank della prima hit
if ("rank_hit" %in% names(per_case)) {
  rank_tbl <- per_case %>%
    filter(!is.na(rank_hit)) %>%
    count(rank_hit) %>%
    mutate(p = n / sum(n))
  
  p_rank <- ggplot(rank_tbl, aes(x = factor(rank_hit), y = p)) +
    geom_col(fill = "coral", width = 0.65) +
    geom_text(aes(label = scales::percent(p, accuracy = 0.1)), 
              vjust = -0.3, size = 3.5) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1), 
                       limits = c(0, max(rank_tbl$p) * 1.15)) +
    labs(x = "Rank della hit", y = "Percentuale su hit", 
         title = "Distribuzione del rank della prima hit") +
    theme_minimal()
  ggsave(filename = here::here(RESULTS_DIR, "plot_rank_hit_distribution.png"), 
         plot = p_rank, width = 6, height = 4, dpi = 150)
}

# Latency summary
if (!is.null(eval_res$timing)) {
  tlong <- eval_res$timing %>%
    tidyr::pivot_longer(cols = c(mean_ms, p50_ms, p95_ms), 
                        names_to = "stat", values_to = "ms") %>%
    mutate(stat = factor(stat, levels = c("mean_ms", "p50_ms", "p95_ms"),
                         labels = c("Mean", "P50 (Median)", "P95")))
  
  p_lat <- ggplot(tlong, aes(x = stat, y = ms)) +
    geom_col(fill = "darkgreen", width = 0.6) +
    geom_text(aes(label = paste0(round(ms, 1), " ms")), 
              vjust = -0.3, size = 3.5) +
    labs(x = NULL, y = "Milliseconds", 
         title = "Prediction Latency Distribution",
         subtitle = paste0("Based on ", eval_res$timing$n_calls, " predictions")) +
    theme_minimal()
  ggsave(filename = here::here(RESULTS_DIR, "plot_latency_summary.png"), 
         plot = p_lat, width = 6, height = 4, dpi = 150)
}

# ---- 9) Summary Report ----
cat("\n")
cat("=" , rep("=", 70), "\n", sep = "")
cat("  MODEL EVALUATION SUMMARY\n")
cat("=" , rep("=", 70), "\n", sep = "")
cat("\n")
cat("Training Configuration:\n")
cat("  - Sample proportion: ", SAMPLE_PROP_TRAIN * 100, "%\n", sep = "")
cat("  - Pruning: min_count_bi=", MIN_COUNT_BI, ", min_count_tri=", MIN_COUNT_TRI, "\n", sep = "")
cat("  - TopN: bi=", TOPN_BI, ", tri=", TOPN_TRI, "\n", sep = "")
cat("\n")
cat("Evaluation Results:\n")
cat("  - Test cases evaluated: ", nrow(per_case), "\n", sep = "")
for (i in seq_len(nrow(acc_tbl))) {
  cat("  - Accuracy@", acc_tbl$k[i], ": ", acc_tbl$accuracy_pct[i], "\n", sep = "")
}
if (!is.null(eval_res$timing)) {
  cat("\n")
  cat("Performance:\n")
  cat("  - Mean latency: ", round(eval_res$timing$mean_ms, 1), " ms\n", sep = "")
  cat("  - P50 latency:  ", round(eval_res$timing$p50_ms, 1), " ms\n", sep = "")
  cat("  - P95 latency:  ", round(eval_res$timing$p95_ms, 1), " ms\n", sep = "")
}
cat("\n")
cat("Output Location: ", here::here(RESULTS_DIR), "\n", sep = "")
cat("=" , rep("=", 70), "\n", sep = "")

message("\n>> Done! Results saved in: ", here::here(RESULTS_DIR))

