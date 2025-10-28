#!/usr/bin/env Rscript

# run_app.R - Script per avviare l'applicazione Word Predictor
# Usage: Rscript run_app.R [port]

# Carica le librerie necessarie
suppressMessages({
  library(shiny)
  library(dplyr)
  library(DT)
  library(Rcaptext)
})

# Ottieni porta dalla riga di comando (default: 8080)
args <- commandArgs(trailingOnly = TRUE)
port <- if(length(args) > 0) as.numeric(args[1]) else 8080

# Verifica che i file dati esistano
data_files <- c(
  "../data/processed/uni_lookup.rds",
  "../data/processed/bi_pruned.rds", 
  "../data/processed/tri_pruned.rds"
)

missing_files <- data_files[!file.exists(data_files)]
if(length(missing_files) > 0) {
  cat("❌ ERROR: Missing data files:\n")
  cat(paste("  -", missing_files, collapse="\n"))
  cat("\n\nPlease ensure the data directory exists with processed models.\n")
  quit(status = 1)
}

# Banner di avvio
cat("\n")
cat("🚀 ================================== 🚀\n")
cat("    WORD PREDICTOR SHINY APP\n") 
cat("🚀 ================================== 🚀\n")
cat("\n")
cat("📊 Data files: ✅ OK\n")
cat("📦 Packages: ✅ OK\n")
cat("🌐 Starting server on port", port, "...\n")
cat("\n")

# Avvia l'applicazione
shiny::runApp(
  host = "0.0.0.0",
  port = port,
  launch.browser = FALSE
)