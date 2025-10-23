library(dplyr)
library(stringr)
library(tidytext)


#' Load the SwiftKey text corpus for a given language
#'
#' This function loads the 3 main text files (blogs, news, twitter)
#' for the selected language (default: en_US). It checks for file existence,
#' reads the content safely, normalizes encoding to UTF-8, and returns
#' a tidy tibble with one row per text line.
#'
#' @param lang Character. Language code prefix (e.g. "en_US", "de_DE").
#' @param base_dir Directory where raw data are stored (default: "data/raw").
#' @return A tibble with columns: source (blogs/news/twitter) and text.
#' @examples
#' corpus <- load_corpus("en_US")
#' glimpse(corpus)
#'
load_corpus <- function(lang = "en_US", base_dir = "data/raw") {
  
  # Build file paths (standard SwiftKey filenames)
  f_blogs   <- here::here(base_dir, sprintf("%s.blogs.txt",   lang))
  f_news    <- here::here(base_dir, sprintf("%s.news.txt",    lang))
  f_twitter <- here::here(base_dir, sprintf("%s.twitter.txt", lang))
  
  # Collect paths in a named vector
  paths <- c(blogs = f_blogs, news = f_news, twitter = f_twitter)
  
  # --- Safety check: all files must exist ---
  missing <- paths[!file.exists(paths)]
  if (length(missing)) {
    stop(sprintf(
      "Missing files:\n- %s\nCheck 'base_dir' and file names (e.g., en_US.blogs.txt).",
      paste(missing, collapse = "\n- ")
    ))
  }
  
  # --- Informative messages for console log ---
  message(sprintf("• Loading corpus language: %s", lang))
  message(sprintf("  - blogs:   %s", f_blogs))
  message(sprintf("  - news:    %s", f_news))
  message(sprintf("  - twitter: %s", f_twitter))
  
  # --- Read files (readr handles encoding & progress bar) ---
  blogs   <- readr::read_lines(f_blogs,   progress = TRUE)
  news    <- readr::read_lines(f_news,    progress = TRUE)
  twitter <- readr::read_lines(f_twitter, progress = TRUE)
  
  # --- Normalize encoding to UTF-8 (remove illegal bytes) ---
  blogs   <- iconv(blogs,   from = "", to = "UTF-8", sub = "byte")
  news    <- iconv(news,    from = "", to = "UTF-8", sub = "byte")
  twitter <- iconv(twitter, from = "", to = "UTF-8", sub = "byte")
  
  # --- Combine all sources into a single tibble ---
  corpus <- tibble::tibble(
    source = c(rep("blogs",   length(blogs)),
               rep("news",    length(news)),
               rep("twitter", length(twitter))),
    text = c(blogs, news, twitter)
  )
  
  # Return tidy corpus
  return(corpus)
}
# 
# set.seed(123)
# sample_frac <- 0.10
# 
# blogs_s   <- sample(blogs,   size = floor(length(blogs) * sample_frac))
# news_s    <- sample(news,    size = floor(length(news) * sample_frac))
# twitter_s <- sample(twitter, size = floor(length(twitter) * sample_frac))
# 
# corpus_raw <- tibble(
#   text   = c(blogs_s, news_s, twitter_s),
#   source = c(rep("blogs", length(blogs_s)),
#              rep("news", length(news_s)),
#              rep("twitter", length(twitter_s)))
# )
# #remove corpus 

clean_text <- function(x, keep_hashtag_word = TRUE) {
  x %>%
    str_to_lower() |>
    # url
    str_replace_all("https?://\\S+|www\\.\\S+", " ") |>
    # @mentions
    str_replace_all("@\\w+", " ") |>
    # hashtag: o rimuovi del tutto, o togli il # ma tieni la parola
    { if (keep_hashtag_word) str_replace_all(., "#(\\w+)", "\\1") else str_replace_all(., "#\\w+", " ") } |>
    # rimuovi caratteri non ASCII (emoji ecc.)
    str_replace_all("[^\\x01-\\x7F]", " ") |>
    # tieni lettere, apostrofi e spazi; togli il resto (numeri, altra punteggiatura)
    str_replace_all("[^a-z' ]", " ") |>
    # collassa spazi
    str_replace_all("\\s+", " ") |>
    str_trim()
}

corpus <- corpus_raw %>%
  mutate(text_clean = clean_text(text))

#' Tokenize corpus into individual words (unigrams)
#'
#' @param corpus Tibble containing at least a text column.
#' @param text_col Column name (unquoted) containing text.
#' @return Tibble with one row per word (token) and any other preserved columns (e.g. source).
#' @examples
#' unigrams <- tokenize_unigrams(corpus)
#' head(unigrams)
tokenize_unigrams <- function(corpus, text_col = "text") {
  corpus |>
    tidytext::unnest_tokens(output = "word", input = {{text_col}}, drop = TRUE) |>
    dplyr::filter(!is.na(word), word != "")
}


#' Compute frequency table for unigrams
#'
#' @param unigrams Tibble with a column named `word` (output of tokenize_unigram()).
#' @return Tibble with columns: word, n (count), and p (relative frequency).
#' @export
freq_unigrams <- function(unigrams) {
  unigrams |>
    dplyr::count(word, sort = TRUE, name = "n") |>
    dplyr::mutate(p = n / sum(n))
}


# =========================
# N-GRAM TOKENIZATION
# =========================

#' Tokenize corpus into n-grams (e.g., bigrams/trigrams)
#' @param corpus Tibble con almeno una colonna testo (default "text")
#' @param n Lunghezza dell'n-gram (2 = bigram, 3 = trigram)
#' @param text_col Nome colonna testo (non quotato), default "text"
#' @return Tibble con colonne: ng (stringa n-gram) + eventuali colonne originali (es. source)
#' @examples
#' bigrams <- tokenize_ngrams(corpus, n = 2)
#' trigrams <- tokenize_ngrams(corpus, n = 3)
tokenize_ngrams <- function(corpus, n = 2, text_col = "text") {
  stopifnot(n >= 2)
  corpus |>
    tidytext::unnest_tokens(
      output = "ng",
      input  = {{ text_col }},
      token  = "ngrams",
      n      = n,
      drop   = TRUE
    ) |>
    dplyr::filter(!is.na(ng), ng != "")
}

# Scorciatoie
tokenize_bigrams <- function(corpus, text_col = "text") {
  tokenize_ngrams(corpus, n = 2, text_col = {{ text_col }})
}

tokenize_trigrams <- function(corpus, text_col = "text") {
  tokenize_ngrams(corpus, n = 3, text_col = {{ text_col }})
}


# =========================
# N-GRAM FREQUENCIES
# =========================

#' Compute frequency table for n-grams and (optionally) conditional MLE
#' @param ngrams_tbl Tibble da tokenize_ngrams() con colonna 'ng'
#' @param n Lunghezza dell'n-gram (2 o 3 tipicamente)
#' @param add_mle Se TRUE, aggiunge p_mle condizionata sullo storico (n-1 parole)
#' @return
#'  - Per n = 2: w1, w2, n, p, (p_mle = n / sum(n) within w1)
#'  - Per n = 3: w1, w2, w3, n, p, (p_mle = n / sum(n) within w1,w2)
#' @examples
#' freq_bi  <- freq_ngrams(tokenize_bigrams(corpus), n = 2, add_mle = TRUE)
#' freq_tri <- freq_ngrams(tokenize_trigrams(corpus), n = 3, add_mle = TRUE)
freq_ngrams <- function(ngrams_tbl, n = 2) {
  stopifnot("ng" %in% names(ngrams_tbl))
  stopifnot(n >= 2)
  
  # separa l'n-gram in colonne w1..wn
  cols <- paste0("w", seq_len(n))
  out <- ngrams_tbl |>
    tidyr::separate(ng, into = cols, sep = " ", remove = TRUE, fill = "right") |>
    dplyr::filter(dplyr::if_all(dplyr::all_of(cols), ~ !is.na(.x) & .x != ""))
  
  # conteggi e frequenze assolute/relative
  out <- out |>
    dplyr::count(dplyr::across(dplyr::all_of(cols)), sort = TRUE, name = "n") |>
    dplyr::mutate(p = n / sum(n))

  out
}

# Shortcut
freq_bigrams <- function(bigrams_tbl) {
  freq_ngrams(bigrams_tbl, n = 2)
}

freq_trigrams <- function(trigrams_tbl) {
  freq_ngrams(trigrams_tbl, n = 3)
}


#' Build cumulative coverage and compute thresholds (e.g., 50% / 90%)
#' @param freq_tbl Tibble con almeno: p (frequenza relativa). Per unigrams: colonna "word".
#'                 Per n-grams: colonne w1..wn oppure una colonna "term".
#' @param p_col Nome colonna della frequenza relativa (default "p")
#' @param thresholds Vettore di soglie cumulative (es. c(0.5, 0.9))
#' @param name_col Nome colonna testo/termine (default: "word"; se assente e ci sono w1..wn, viene creata "term")
#' @return list(cum_tbl = tibble(...), summary = tibble(threshold, n_unique, top_example))
coverage_from_freq <- function(freq_tbl, p_col = "p", thresholds = c(0.5, 0.9), name_col = "word") {
  # controlli di base
  stopifnot(p_col %in% names(freq_tbl))
  
  # crea una colonna "term" se name_col non esiste
  tbl <- freq_tbl
  if (!name_col %in% names(tbl)) {
    # cerca colonne w1..wn e uniscile in "term"
    w_cols <- grep("^w\\d+$", names(tbl), value = TRUE)
    if (length(w_cols) == 0) {
      stop("No name column found and no w1..wn columns available to build a term column.")
    }
    tbl <- tbl |>
      tidyr::unite(col = "term", dplyr::all_of(w_cols), sep = " ", remove = FALSE)
    name_col <- "term"
  }
  
  # ordina per frequenza decrescente, crea rank e cumulativa
  tbl <- tbl |>
    dplyr::arrange(dplyr::desc(.data[[p_col]])) |>
    dplyr::mutate(
      rank = dplyr::row_number(),
      cum_p = cumsum(.data[[p_col]])
    )
  
  # per ogni soglia, quante voci servono?
  sum_tbl <- purrr::map_dfr(thresholds, function(th) {
    idx <- which(tbl$cum_p >= th)[1]
    dplyr::tibble(
      threshold = th,
      n_unique  = idx,
      top_example = tbl[[name_col]][idx]
    )
  })
  
  list(
    cum_tbl = tbl,
    summary = sum_tbl
  )
}
