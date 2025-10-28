# run-interpolation-eval.R
# Evaluation pipeline per algoritmo di Linear Interpolation
# Riutilizza il modello già costruito e valuta le performance dell'algoritmo interpolated

# ---- Librerie ----
library(Rcaptext)
library(dplyr)
library(here)
library(ggplot2)
library(readr)
library(tidyr)

# ---- Parametri generali ----
LANG             <- "en_US"
RAW_DIR          <- "data/raw"          
OUT_DIR          <- "data/processed"    # dove sono gli RDS del modello
RESULTS_DIR      <- "results"           # dove salvare i risultati interpolation

SEED             <- 123
PROP_TEST        <- 0.05   
TEST_PROP_ROWS   <- 0.5    
MIN_WORDS_TEST   <- 3      

# Parametri specifici per Linear Interpolation
LAMBDA           <- c(0.7, 0.25, 0.05)  # Pesi interpolation: [trigram, bigram, unigram]
BETA             <- 0.7                 # IDF reranking weight
KS               <- c(1, 2, 3)         # Valutazione accuracy@k
TIMEIT           <- TRUE
TIMING_N         <- 300
MAX_EVAL_CASES   <- 10000              # Numero massimo casi di test

# UI Settings
USE_PROGRESS     <- TRUE

# Output suffix per distinguere dai risultati backoff
SUFFIX           <- "_interpolation"

# ---- Setup cartelle output ----
if (!dir.exists(RESULTS_DIR)) dir.create(RESULTS_DIR, recursive = TRUE, showWarnings = FALSE)

# ---- 1) Verifica che esistano i modelli RDS ----
message(">> Checking for existing model files...")
uni_path <- here::here(OUT_DIR, "uni_lookup.rds")
bi_path  <- here::here(OUT_DIR, "bi_pruned.rds")
tri_path <- here::here(OUT_DIR, "tri_pruned.rds")

if (!file.exists(uni_path) || !file.exists(bi_path) || !file.exists(tri_path)) {
  stop("Model files not found! Please run run-model&eval.R first to build the model.")
}

# ---- 2) Carica corpus per il test set ----
message(">> Loading corpus for test set generation...")
corpus_raw <- load_corpus(LANG, base_dir = RAW_DIR)
corpus <- corpus_raw %>%
  mutate(text_clean = clean_text(text))
rm(corpus_raw); gc()

# ---- 3) Split train/test (stesso seed per consistenza) ----
message(">> Splitting train/test (consistent with backoff evaluation)...")
split <- split_corpus(corpus, prop_test = PROP_TEST, by_source = TRUE, seed = SEED)
train <- split$train
test  <- split$test
rm(corpus); rm(split); rm(train); gc()  # Teniamo solo test

# ---- 4) Prepara il TEST set di finestre ----
message(">> Building test windows from TEST...")
if (USE_PROGRESS) {
  progressr::handlers(global = TRUE)
  progressr::handlers("cli")
}

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
rm(test); gc()

# ---- 5) Carica i modelli RDS ----
message(">> Loading pre-trained models...")
uni_lookup <- readRDS(uni_path)
bi_pruned  <- readRDS(bi_path)
tri_pruned <- readRDS(tri_path)

# ---- 6) Funzione evaluate_accuracy_at_k modificata per interpolation ----
evaluate_accuracy_at_k_interpolated <- function(
  test_windows,
  tri_pruned, bi_pruned, uni_lookup,
  lambda = c(0.7, 0.25, 0.05),
  beta = 0.7,
  ks = c(1, 2, 3),
  timeit = TRUE,
  timing_n = 200,
  seed = 123,
  max_eval_cases = NULL,
  use_progress = TRUE
) {
  stopifnot(all(c("input_text", "target") %in% names(test_windows)))
  Kmax <- max(ks)

  # Wrapper for progress
  run_evaluation <- function() {
    # Optional sampling
    if (!is.null(max_eval_cases) && nrow(test_windows) > max_eval_cases) {
      if (use_progress) {
        cli::cli_h2("Evaluating Linear Interpolation model")
        cli::cli_alert_info("Sampling {max_eval_cases} of {nrow(test_windows)} test cases for faster evaluation")
      } else {
        message(">> Sampling ", max_eval_cases, " of ", nrow(test_windows), " test cases")
      }
      set.seed(seed)
      test_windows <- test_windows %>% dplyr::slice_sample(n = max_eval_cases)
    } else {
      if (use_progress) {
        cli::cli_h2("Evaluating Linear Interpolation model ({nrow(test_windows)} test cases)")
      }
    }
    
    # Progress setup
    if (use_progress) {
      pb <- progressr::progressor(nrow(test_windows))
    }
    
    # Predizioni per ogni caso di test
    pred_cols <- paste0("pred", seq_len(Kmax))
    results_df <- tibble::tibble(
      input_text = character(nrow(test_windows)),
      target = character(nrow(test_windows)),
      !!!setNames(rep(list(character(nrow(test_windows))), Kmax), pred_cols)
    )
    
    for (i in seq_len(nrow(test_windows))) {
      input_text <- test_windows$input_text[i]
      target <- test_windows$target[i]
      
      # Usa predict_interpolated invece di predict_next
      preds <- predict_interpolated(
        input = input_text,
        tri_pruned = tri_pruned,
        bi_pruned = bi_pruned,
        uni_lookup = uni_lookup,
        lambda = lambda,
        beta = beta,
        top_k = Kmax
      )
      
      # Riempi risultati
      results_df$input_text[i] <- input_text
      results_df$target[i] <- target
      
      # Estrai solo le parole predette (non i punteggi)
      pred_words <- if (nrow(preds) > 0) preds$word else character(0)
      
      for (j in seq_len(Kmax)) {
        if (j <= length(pred_words)) {
          results_df[[pred_cols[j]]][i] <- pred_words[j]
        } else {
          results_df[[pred_cols[j]]][i] <- NA_character_
        }
      }
      
      if (use_progress && i %% 100 == 0) {
        pb(amount = 100)
      }
    }
    
    if (use_progress) pb(amount = nrow(test_windows) %% 100)
    
    # Calcola accuracy@k
    accuracy_results <- tibble::tibble(k = integer(), accuracy = numeric())
    
    for (k in ks) {
      hits <- 0
      total <- nrow(results_df)
      
      for (i in seq_len(total)) {
        target_word <- results_df$target[i]
        pred_k <- results_df[i, pred_cols[1:k], drop = TRUE]
        pred_k <- unlist(pred_k)
        pred_k <- pred_k[!is.na(pred_k)]
        
        if (target_word %in% pred_k) {
          hits <- hits + 1
        }
      }
      
      accuracy_results <- accuracy_results %>%
        bind_rows(tibble::tibble(k = k, accuracy = hits / total))
    }
    
    # Add rank_hit column per compatibility
    results_df$rank_hit <- NA_integer_
    for (i in seq_len(nrow(results_df))) {
      target <- results_df$target[i]
      preds <- unlist(results_df[i, pred_cols])
      preds <- preds[!is.na(preds)]
      
      hit_idx <- which(preds == target)[1]
      if (!is.na(hit_idx)) {
        results_df$rank_hit[i] <- hit_idx
      }
    }
    
    result <- list(
      accuracy = accuracy_results,
      per_case = results_df,
      timing = NULL
    )
    
    # Timing evaluation se richiesto
    if (timeit && timing_n > 0) {
      if (use_progress) {
        cli::cli_alert_info("Running timing evaluation ({timing_n} iterations)...")
      }
      
      # Seleziona casi random per timing
      set.seed(seed)
      timing_cases <- test_windows %>% 
        dplyr::slice_sample(n = min(timing_n, nrow(test_windows)))
      
      timing_ms <- numeric(nrow(timing_cases))
      
      for (i in seq_len(nrow(timing_cases))) {
        start_time <- Sys.time()
        
        predict_interpolated(
          input = timing_cases$input_text[i],
          tri_pruned = tri_pruned,
          bi_pruned = bi_pruned,
          uni_lookup = uni_lookup,
          lambda = lambda,
          beta = beta,
          top_k = Kmax
        )
        
        end_time <- Sys.time()
        timing_ms[i] <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
      }
      
      timing_summary <- tibble::tibble(
        n_calls = length(timing_ms),
        mean_ms = mean(timing_ms),
        p50_ms = median(timing_ms),
        p95_ms = quantile(timing_ms, 0.95),
        min_ms = min(timing_ms),
        max_ms = max(timing_ms)
      )
      
      result$timing <- timing_summary
    }
    
    return(result)
  }
  
  if (use_progress) {
    progressr::with_progress(run_evaluation())
  } else {
    run_evaluation()
  }
}

# ---- 7) Valuta accuracy@k e timing per INTERPOLATION ----
message(">> Evaluating Linear Interpolation algorithm...")
message("   Lambda weights: [", paste(LAMBDA, collapse = ", "), "]")
message("   Beta (IDF weight): ", BETA)

eval_res_interpolation <- evaluate_accuracy_at_k_interpolated(
  test_windows    = test_windows,
  tri_pruned      = tri_pruned,
  bi_pruned       = bi_pruned,
  uni_lookup      = uni_lookup,
  lambda          = LAMBDA,
  beta            = BETA,
  ks              = KS,
  timeit          = TIMEIT,
  timing_n        = TIMING_N,
  seed            = SEED,
  max_eval_cases  = MAX_EVAL_CASES,  
  use_progress    = USE_PROGRESS     
)

# ---- 9) Salva tabelle e genera plot ----
message(">> Generating results tables and plots for Linear Interpolation...")

# Accuracy table
acc_tbl <- eval_res_interpolation$accuracy %>%
  mutate(accuracy_pct = paste0(round(accuracy*100, 1), "%"))
readr::write_csv(acc_tbl, file = here::here(RESULTS_DIR, paste0("accuracy_at_k", SUFFIX, ".csv")))

# Timing summary
if (!is.null(eval_res_interpolation$timing)) {
  timing_tbl <- eval_res_interpolation$timing %>%
    mutate(across(everything(), ~round(., 2)))
  readr::write_csv(timing_tbl, file = here::here(RESULTS_DIR, paste0("timing_summary", SUFFIX, ".csv")))
}

# Hit breakdown
Kmax <- max(eval_res_interpolation$accuracy$k)
pred_cols <- paste0("pred", seq_len(Kmax))
per_case <- eval_res_interpolation$per_case

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
readr::write_csv(hit_breakdown, file = here::here(RESULTS_DIR, paste0("hit_breakdown", SUFFIX, ".csv")))

# ---- 10) Plot specifici per Linear Interpolation ----

# Accuracy@k
p_acc <- ggplot(eval_res_interpolation$accuracy, aes(x = factor(k), y = accuracy)) +
  geom_col(fill = "darkblue", width = 0.65) +
  geom_text(aes(label = scales::percent(accuracy, accuracy = 0.1)), 
            vjust = -0.3, size = 3.5, color = "white", fontface = "bold") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), 
                     limits = c(0, max(eval_res_interpolation$accuracy$accuracy) * 1.15)) +
  labs(x = "k", y = "Accuracy", 
       title = "Linear Interpolation - Accuracy@k",
       subtitle = paste0("λ = [", paste(LAMBDA, collapse = ", "), "] | β = ", BETA, " | ", nrow(per_case), " test cases")) +
  theme_minimal() +
  theme(
    plot.title = element_text(color = "darkblue", size = 14, face = "bold"),
    plot.subtitle = element_text(color = "gray50", size = 10)
  )
ggsave(filename = here::here(RESULTS_DIR, paste0("plot_accuracy_at_k", SUFFIX, ".png")), 
       plot = p_acc, width = 8, height = 5, dpi = 150)

# Distribuzione rank della prima hit
if ("rank_hit" %in% names(per_case)) {
  rank_tbl <- per_case %>%
    filter(!is.na(rank_hit)) %>%
    count(rank_hit) %>%
    mutate(p = n / sum(n))
  
  p_rank <- ggplot(rank_tbl, aes(x = factor(rank_hit), y = p)) +
    geom_col(fill = "purple", width = 0.65) +
    geom_text(aes(label = scales::percent(p, accuracy = 0.1)), 
              vjust = -0.3, size = 3.5, color = "white", fontface = "bold") +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1), 
                       limits = c(0, max(rank_tbl$p) * 1.15)) +
    labs(x = "Rank della hit", y = "Percentuale su hit", 
         title = "Linear Interpolation - Distribuzione Rank Hit",
         subtitle = "Posizione della prima predizione corretta") +
    theme_minimal() +
    theme(
      plot.title = element_text(color = "purple", size = 14, face = "bold"),
      plot.subtitle = element_text(color = "gray50", size = 10)
    )
  ggsave(filename = here::here(RESULTS_DIR, paste0("plot_rank_hit_distribution", SUFFIX, ".png")), 
         plot = p_rank, width = 8, height = 5, dpi = 150)
}

# Latency summary
if (!is.null(eval_res_interpolation$timing)) {
  tlong <- eval_res_interpolation$timing %>%
    tidyr::pivot_longer(cols = c(mean_ms, p50_ms, p95_ms), 
                        names_to = "stat", values_to = "ms") %>%
    mutate(stat = factor(stat, levels = c("mean_ms", "p50_ms", "p95_ms"),
                         labels = c("Mean", "P50 (Median)", "P95")))
  
  p_lat <- ggplot(tlong, aes(x = stat, y = ms)) +
    geom_col(fill = "darkorange", width = 0.6) +
    geom_text(aes(label = paste0(round(ms, 1), " ms")), 
              vjust = -0.3, size = 3.5, color = "white", fontface = "bold") +
    labs(x = NULL, y = "Milliseconds", 
         title = "Linear Interpolation - Prediction Latency",
         subtitle = paste0("Based on ", eval_res_interpolation$timing$n_calls, " predictions")) +
    theme_minimal() +
    theme(
      plot.title = element_text(color = "darkorange", size = 14, face = "bold"),
      plot.subtitle = element_text(color = "gray50", size = 10)
    )
  ggsave(filename = here::here(RESULTS_DIR, paste0("plot_latency_summary", SUFFIX, ".png")), 
       plot = p_lat, width = 8, height = 5, dpi = 150)
}

# ---- 11) Comparison plot (se esistono i risultati backoff) ----
backoff_acc_file <- here::here(RESULTS_DIR, "accuracy_at_k_long_long.csv")
if (file.exists(backoff_acc_file)) {
  message(">> Creating comparison plot with Backoff algorithm...")
  
  backoff_acc <- readr::read_csv(backoff_acc_file, show_col_types = FALSE) %>%
    mutate(algorithm = "Katz Backoff")
  
  interpolation_acc <- eval_res_interpolation$accuracy %>%
    mutate(algorithm = "Linear Interpolation")
  
  combined_acc <- bind_rows(backoff_acc %>% select(k, accuracy, algorithm), 
                           interpolation_acc)
  
  p_comparison <- ggplot(combined_acc, aes(x = factor(k), y = accuracy, fill = algorithm)) +
    geom_col(position = "dodge", width = 0.7) +
    geom_text(aes(label = scales::percent(accuracy, accuracy = 0.1)), 
              position = position_dodge(width = 0.7), vjust = -0.3, size = 3.2) +
    scale_fill_manual(values = c("Katz Backoff" = "steelblue", "Linear Interpolation" = "darkblue")) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1), 
                       limits = c(0, max(combined_acc$accuracy) * 1.15)) +
    labs(x = "k", y = "Accuracy", fill = "Algorithm",
         title = "Algorithm Comparison - Accuracy@k",
         subtitle = paste0("Test cases: ", nrow(per_case), " | Same models, different prediction methods")) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(color = "gray50", size = 11)
    )
  ggsave(filename = here::here(RESULTS_DIR, "plot_algorithm_comparison.png"), 
         plot = p_comparison, width = 10, height = 6, dpi = 150)
}

# ---- 12) Summary Report ----
cat("\n")
cat("=" , rep("=", 80), "\n", sep = "")
cat("  LINEAR INTERPOLATION EVALUATION SUMMARY\n")
cat("=" , rep("=", 80), "\n", sep = "")
cat("\n")
cat("Algorithm Configuration:\n")
cat("  - Method: Linear Interpolation with IDF Re-ranking\n")
cat("  - Lambda weights: [", paste(LAMBDA, collapse = ", "), "] (trigram, bigram, unigram)\n", sep = "")
cat("  - Beta (IDF weight): ", BETA, "\n", sep = "")
cat("\n")
cat("Evaluation Results:\n")
cat("  - Test cases evaluated: ", nrow(per_case), "\n", sep = "")
for (i in seq_len(nrow(acc_tbl))) {
  cat("  - Accuracy@", acc_tbl$k[i], ": ", acc_tbl$accuracy_pct[i], "\n", sep = "")
}
if (!is.null(eval_res_interpolation$timing)) {
  cat("\n")
  cat("Performance:\n")
  cat("  - Mean latency: ", round(eval_res_interpolation$timing$mean_ms, 1), " ms\n", sep = "")
  cat("  - P50 latency:  ", round(eval_res_interpolation$timing$p50_ms, 1), " ms\n", sep = "")
  cat("  - P95 latency:  ", round(eval_res_interpolation$timing$p95_ms, 1), " ms\n", sep = "")
}
cat("\n")
cat("Output Files:\n")
cat("  - Accuracy: accuracy_at_k_interpolation.csv\n")
cat("  - Timing: timing_summary_interpolation.csv\n")
cat("  - Plots: plot_*_interpolation.png\n")
if (file.exists(backoff_acc_file)) {
  cat("  - Comparison: plot_algorithm_comparison.png\n")
}
cat("\n")
cat("Output Location: ", here::here(RESULTS_DIR), "\n", sep = "")
cat("=" , rep("=", 80), "\n", sep = "")

message("\n>> Done! Linear Interpolation results saved in: ", here::here(RESULTS_DIR))
message(">> Plot files are ready to be loaded in your Shiny app!")