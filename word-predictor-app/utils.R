# utils.R - Funzioni di utilità semplici
# Niente cache, niente complessità - solo wrapper diretti

library(Rcaptext)

# Carica i dati una volta sola
load_data <- function() {
  cat("📥 Loading prediction models...\n")
  start_time <- Sys.time()
  
  # Path relativi che funzionano sia in locale che su shinyapps.io
  if (file.exists("../data/processed/uni_lookup.rds")) {
    # Locale - path relativi
    UNI_PATH <- "../data/processed/uni_lookup.rds"
    BI_PATH  <- "../data/processed/bi_pruned.rds"
    TRI_PATH <- "../data/processed/tri_pruned.rds"
    cat("🏠 Running locally - using relative paths\n")
  } else {
    # Shinyapps.io - file nella cartella dell'app
    UNI_PATH <- "uni_lookup.rds"
    BI_PATH  <- "bi_pruned.rds"
    TRI_PATH <- "tri_pruned.rds"
    cat("☁️ Running on server - using local files\n")
  }
  
  data <- list(
    uni_lookup = readRDS(UNI_PATH),
    bi_pruned  = readRDS(BI_PATH),
    tri_pruned = readRDS(TRI_PATH)
  )
  
  # IDF solo se necessario
  data$idf_lookup <- build_idf_lookup(data$uni_lookup)
  
  load_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  cat("✅ Loaded in", round(load_time, 2), "seconds\n")
  cat("📊", format(nrow(data$uni_lookup), big.mark=","), "unigrams |", 
      format(nrow(data$bi_pruned), big.mark=","), "bigrams |", 
      format(nrow(data$tri_pruned), big.mark=","), "trigrams\n\n")
  
  return(data)
}

# Wrapper semplice per Stupid Backoff
predict_backoff <- function(input_text, data, alpha = 0.4, top_k = 5) {
  start_time <- Sys.time()
  
  predictions <- predict_next(
    input = input_text,
    tri_pruned = data$tri_pruned,
    bi_pruned = data$bi_pruned,
    uni_lookup = data$uni_lookup,
    alpha = alpha,
    top_k = top_k
  )
  
  elapsed_ms <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
  
  return(list(
    predictions = predictions,
    elapsed_ms = elapsed_ms,
    method = "Stupid Backoff"
  ))
}

# Wrapper semplice per Interpolated + IDF
predict_interpolated_simple <- function(input_text, data, lambda_tri = 0.7, lambda_bi = 0.2, beta = 0.3, top_k = 5) {
  start_time <- Sys.time()
  
  lambda_uni <- max(0, 1 - lambda_tri - lambda_bi)
  
  predictions <- predict_interpolated(
    input = input_text,
    tri_pruned = data$tri_pruned,
    bi_pruned = data$bi_pruned,
    uni_lookup = data$uni_lookup,
    lambda = c(lambda_tri, lambda_bi, lambda_uni),
    beta = beta,
    top_k = top_k,
    idf_lookup = data$idf_lookup
  )
  
  elapsed_ms <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
  
  return(list(
    predictions = predictions,
    elapsed_ms = elapsed_ms,
    method = "Interpolated + IDF"
  ))
}

# Funzione per pulire l'input
clean_input <- function(text) {
  if (is.null(text) || text == "") return("")
  
  # Rimuovi spazi extra e converti in minuscolo
  cleaned <- trimws(tolower(text))
  
  return(cleaned)
}