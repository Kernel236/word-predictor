load_corpus <- function(lang = "en_US", base_dir = "data/raw") {
  f_blog <- here::here(base_dir, sprintf("%s.blogs.txt", lang))
  f_news <- here::here(base_dir, sprintf("%s.news.txt", lang))
  f_twit <- here::here(base_dir, sprintf("%s.twitter.txt", lang))
  
  paths <- c(blogs = f_blogs, news = f_news, twitter = f_twit)
  
  # Check existing files
  missing <- paths[!file.exists(paths)]
  if (length(missing)) {
    stop(sprintf(
      "Missing files:\n- %s\nCheck'base_dir' and file names (es. en_US.blogs.txt).",
      paste(missing, collapse = "\n- ")
    ))
  }
  
  message(sprintf("• Uploading corpus language: %s", lang))
  message(sprintf("  - blogs:   %s", f_blogs))
  message(sprintf("  - news:    %s", f_news))
  message(sprintf("  - twitter: %s", f_twit))
  blogs <- readr::read_lines(f_blogs, progress = TRUE)
  news <- readr::read_lines(f_news, progress = TRUE)
  twits <- readr::read_lines(f_twit, progress = TRUE)
  
  #Notmalization of encoding
  blogs <- iconv(blogs, from = "", to = "UTF-8", sub = "byte")
  news <- iconv(news, from = "", to = "UTF-8", sub = "byte")
  twits <- iconv(twits, from = "", to = "UTF-8", sub = "byte")
  
  #create table
  tibble::tibble(
    source = c(rep("blogs", length(blogs)),
               rep("news", length(news)),
               rep("twitter", length(twits))),
    text = c(blogs, news, twits)
  )
  
}