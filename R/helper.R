library(here)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(tidytext)
library(ggplot2)
library(scales)


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

#' Sample the corpus by source (blogs/news/twitter)
#'
#' @param corpus Tibble with columns `source` and `text`
#' @param prop Proportion to sample within each source (e.g., 0.05). Use either `prop` OR `n_per_source`.
#' @param n_per_source Integer number of lines to sample within each source (e.g., 50_000).
#' @param seed RNG seed for reproducibility.
#' @param min_chars Drop lines with fewer than this many characters before sampling.
#' @return Tibble sampled, same columns as input.
#' @examples
#' small <- sample_corpus(corpus, prop = 0.05, seed = 123)
#' tiny  <- sample_corpus(corpus, n_per_source = 20000, seed = 42)
sample_corpus <- function(corpus, prop = NULL, n_per_source = NULL, seed = 123, min_chars = 1) {
  stopifnot("source" %in% names(corpus), "text" %in% names(corpus))
  if (is.null(prop) == is.null(n_per_source)) {
    stop("Provide exactly one of `prop` or `n_per_source`.")
  }
  set.seed(seed)
  
  out <- corpus |>
    dplyr::filter(!is.na(text), nchar(text) >= min_chars) |>
    dplyr::group_by(source)
  
  out <- if (!is.null(prop)) {
    dplyr::slice_sample(out, prop = prop)
  } else {
    dplyr::slice_sample(out, n = n_per_source)
  }
  
  dplyr::ungroup(out)
}



clean_text <- function(x, keep_hashtag_word = TRUE) {
  x |>
    str_to_lower() |>
    # url
    str_replace_all("https?://\\S+|www\\.\\S+", " ") |>
    # @mentions
    str_replace_all("@\\w+", " ") |>
    # hashtag: o rimuovi del tutto, o togli il # ma tieni la parola
    str_replace_all("#\\w+", " ")  |>
    # rimuovi caratteri non ASCII (emoji ecc.)
    str_replace_all("[^\\x01-\\x7F]", " ") |>
    # tieni lettere, apostrofi e spazi; togli il resto (numeri, altra punteggiatura)
    str_replace_all("[^a-z' ]", " ") |>
    # collassa spazi
    str_replace_all("\\s+", " ") |>
    str_trim()
}

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

#' Plot cumulative coverage curve
#' @param freq_tbl Tabella di frequenze con colonna p e (word|term / w1..wn)
#' @param p_col Nome colonna con la frequenza relativa
#' @param name_col Colonna del termine; se assente e ci sono w1..wn, verrà creata "term"
plot_cumulative_coverage <- function(freq_tbl, p_col = "p", name_col = "word") {
  cov <- coverage_from_freq(freq_tbl, p_col = p_col, thresholds = numeric(), name_col = name_col)
  ggplot2::ggplot(cov$cum_tbl, ggplot2::aes(x = rank, y = cum_p)) +
    ggplot2::geom_line() +
    ggplot2::labs(
      x = "Unique terms included (rank)",
      y = "Cumulative coverage",
      title = "Cumulative coverage curve"
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent) +
    ggplot2::theme_minimal()
}

#' Plot top-k terms by frequency
#' @param freq_tbl Tabella con (word|term) e n
#' @param top Numero di termini da mostrare
plot_top_terms <- function(freq_tbl, top = 20, name_col = "word") {
  tbl <- freq_tbl
  if (!name_col %in% names(tbl)) {
    w_cols <- grep("^w\\d+$", names(tbl), value = TRUE)
    if (length(w_cols) == 0) stop("No term column found (word/term or w1..wn).")
    tbl <- tbl |>
      tidyr::unite(col = "term", dplyr::all_of(w_cols), sep = " ", remove = FALSE)
    name_col <- "term"
  }
  tbl |>
    dplyr::slice_head(n = top) |>
    ggplot2::ggplot(ggplot2::aes(x = reorder(.data[[name_col]], n), y = n)) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::labs(x = NULL, y = "Count", title = paste("Top", top, "terms")) +
    ggplot2::theme_minimal()
}

#' Plot rank-frequency (Zipf-like) for top N terms
#' @param freq_tbl Tabella di frequenze con p
#' @param top Quanti termini considerare in testa
plot_rank_frequency <- function(freq_tbl, top = 5000, name_col = "word", p_col = "p") {
  tbl <- freq_tbl
  if (!name_col %in% names(tbl)) {
    w_cols <- grep("^w\\d+$", names(tbl), value = TRUE)
    if (length(w_cols) == 0) stop("No term column found (word/term or w1..wn).")
    tbl <- tbl |>
      tidyr::unite(col = "term", dplyr::all_of(w_cols), sep = " ", remove = FALSE)
    name_col <- "term"
  }
  tbl <- tbl |>
    dplyr::arrange(dplyr::desc(.data[[p_col]])) |>
    dplyr::mutate(rank = dplyr::row_number()) |>
    dplyr::slice_head(n = top)
  
  ggplot2::ggplot(tbl, ggplot2::aes(x = rank, y = .data[[p_col]])) +
    ggplot2::geom_line() +
    ggplot2::scale_y_log10() +
    ggplot2::scale_x_log10() +
    ggplot2::labs(
      x = "Rank (log scale)",
      y = "Frequency (log scale)",
      title = paste("Rank–frequency (top", top, ")")
    ) +
    ggplot2::theme_minimal()
}



corpus_raw <- load_corpus("en_US", base_dir = "data/raw")

corpus <- corpus_raw %>%
  mutate(text_clean = clean_text(text))

# sanity check
corpus %>% count(source)

set.seed(123)
small <- sample_corpus(corpus, prop = 0.10, min_chars = 5)
small %>% count(source)
rm(corpus_raw); gc()



# tokenizza sul TESTO PULITO
uni <- tokenize_unigrams(small, text_col = "text_clean")

freq_uni <- freq_unigrams(uni)              # word, n, p

# coverage 50% / 90%
cov_uni <- coverage_from_freq(freq_uni, thresholds = c(0.5, 0.9), name_col = "word")
cov_uni$summary     # ← tabella con n_unique per 50% e 90%

# grafici
plot_cumulative_coverage(freq_uni, name_col = "word")
plot_top_terms(freq_uni, top = 25, name_col = "word")
plot_rank_frequency(freq_uni, top = 10000, name_col = "word")

rm(uni); gc()


bi <- tokenize_bigrams(small, text_col = "text_clean")

freq_bi <- freq_bigrams(bi)                 # w1, w2, n, p

cov_bi <- coverage_from_freq(freq_bi, thresholds = c(0.5, 0.9))
cov_bi$summary

plot_cumulative_coverage(freq_bi)           # costruisce "term" da w1 w2
plot_top_terms(freq_bi, top = 25)           # idem

rm(bi); gc()


tri <- tokenize_trigrams(small, text_col = "text_clean")

freq_tri <- freq_trigrams(tri)              # w1, w2, w3, n, p

cov_tri <- coverage_from_freq(freq_tri, thresholds = c(0.5, 0.9))
cov_tri$summary

plot_cumulative_coverage(freq_tri)
plot_top_terms(freq_tri, top = 25)

# pruning + save (i trigrammi esplodono: sii aggressivo)
freq_tri_top <- prune_top_k(freq_tri, top_k = 150000)
saveRDS(freq_tri_top, here("data/processed/freq_tri_top150k.rds"))

rm(tri); gc()
