# mock-data.R - Dati simulati per la presentazione

# Simulated performance data for the presentation
create_mock_performance_data <- function() {
  
  # Accuracy data
  accuracy_data <- data.frame(
    algorithm = rep(c("Stupid Backoff", "Interpolated+IDF"), each = 3),
    k = rep(c("Top-1", "Top-3", "Top-5"), 2),
    accuracy = c(16.2, 28.4, 35.1, 18.7, 31.9, 39.2)
  )
  
  # Latency data
  latency_data <- data.frame(
    metric = c("Mean", "P50", "P95"),
    ms = c(42, 38, 67),
    target = c(50, 50, 100)
  )
  
  # Model size data
  model_stats <- list(
    unigrams = 52718,
    bigrams = 183284,
    trigrams = 508003,
    total_ngrams = 744005,
    model_size_mb = 12
  )
  
  return(list(
    accuracy = accuracy_data,
    latency = latency_data,
    model = model_stats
  ))
}

# Create sample prediction examples
create_sample_predictions <- function() {
  data.frame(
    input = c("I would", "The best", "How are", "Thank you", "I am"),
    top_predictions = c("like, be, have", "way, thing, part", "you, we, they", "very, so, for", "not, a, going"),
    algorithm = c("Interpolated", "Backoff", "Interpolated", "Backoff", "Interpolated"),
    confidence = c(0.187, 0.162, 0.201, 0.143, 0.176),
    timing_ms = c(38, 42, 35, 48, 41)
  )
}