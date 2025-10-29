# server.R - Logica server semplice e veloce

library(shiny)
library(dplyr)
library(DT)

# Carica le utilità
source("utils.R")

server <- function(input, output, session) {
  
  # Carica i dati una volta all'avvio
  cat("🚀 Starting Simple Word Predictor...\n")
  data <- load_data()
  cat("✅ Ready to predict!\n\n")
  
  # Valori reattivi per i risultati
  values <- reactiveValues(
    predictions = NULL,
    timing = 0,
    method_used = "",
    input_cleaned = "",
    status = "Ready to predict"
  )
  
  # Calcolo lambda unigram per display
  output$lambda_uni_display <- renderText({
    if (input$method == "interpolated") {
      lambda_uni <- max(0, 1 - input$lambda_tri - input$lambda_bi)
      paste0("Unigram weight: ", round(lambda_uni, 3))
    }
  })
  
  # PREDIZIONE - Solo quando si clicca il pulsante
  observeEvent(input$predict_btn, {
    
    # Pulizia input
    cleaned_text <- clean_input(input$input_text)
    
    if (cleaned_text == "") {
      values$status <- "❌ Please enter some text"
      return()
    }
    
    values$status <- "🔄 Predicting..."
    values$input_cleaned <- cleaned_text
    
    cat("🎯 PREDICTION for:", cleaned_text, "\n")
    
    # Predizione basata sull'algoritmo scelto
    if (input$method == "backoff") {
      result <- predict_backoff(
        input_text = cleaned_text,
        data = data,
        alpha = input$alpha,
        top_k = input$top_k
      )
    } else {
      result <- predict_interpolated_simple(
        input_text = cleaned_text,
        data = data,
        lambda_tri = input$lambda_tri,
        lambda_bi = input$lambda_bi,
        beta = input$beta,
        top_k = input$top_k
      )
    }
    
    # Aggiorna i risultati
    values$predictions <- result$predictions
    values$timing <- result$elapsed_ms
    values$method_used <- result$method
    values$status <- "✅ Prediction completed"
    
    cat("✅ COMPLETED in", round(result$elapsed_ms, 1), "ms\n")
  })
  
  # Output di stato con styling
  output$status_text <- renderText({
    values$status
  })
  
  output$timing_text <- renderText({
    if (values$timing > 0) {
      timing_rounded <- round(values$timing, 1)
      if (values$timing < 50) {
        paste0("🚀 ", timing_rounded, "ms - Lightning Fast!")
      } else if (values$timing < 200) {
        paste0("✅ ", timing_rounded, "ms - Good Performance")
      } else {
        paste0("⏱️ ", timing_rounded, "ms - Processing...")
      }
    } else {
      "⚡ Ready for prediction"
    }
  })
  
  # Tabella delle predizioni
  output$predictions_table <- DT::renderDataTable({
    req(values$predictions)
    
    DT::datatable(
      values$predictions,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'frtip',
        searching = FALSE,
        ordering = TRUE
      ),
      rownames = FALSE
    ) %>% 
      DT::formatRound(columns = c("score"), digits = 4)
  })
  
  # Info algoritmo
  output$algorithm_info <- renderText({
    if (values$method_used != "") {
      info <- paste0(
        "Method: ", values$method_used, "\n",
        "Timing: ", round(values$timing, 1), "ms\n"
      )
      
      if (input$method == "backoff") {
        info <- paste0(info, "Alpha: ", input$alpha, "\n")
      } else {
        lambda_uni <- max(0, 1 - input$lambda_tri - input$lambda_bi)
        info <- paste0(info, 
                      "λ₃: ", input$lambda_tri, "\n",
                      "λ₂: ", input$lambda_bi, "\n", 
                      "λ₁: ", round(lambda_uni, 3), "\n",
                      "β: ", input$beta)
      }
      
      info
    }
  })
  
  # Analisi input
  output$input_analysis <- renderText({
    if (values$input_cleaned != "") {
      words <- strsplit(values$input_cleaned, "\\s+")[[1]]
      n_words <- length(words)
      
      context_info <- if (n_words >= 2) {
        paste0("Context: '", paste(tail(words, 2), collapse = " "), "'")
      } else if (n_words == 1) {
        paste0("Context: '", words[1], "'")
      } else {
        "No context"
      }
      
      paste0(
        "Input: '", values$input_cleaned, "'\n",
        "Words: ", n_words, "\n",
        context_info, "\n",
        "Predictions: ", input$top_k
      )
    }
  })
}