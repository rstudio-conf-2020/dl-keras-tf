library(fs)
library(tidyverse)

imdb_dir <- here::here("materials", "data", "imdb")
  

# Import reviews and labels -----------------------------------------------
cat("Importing reviews and labels...")

training_files <- file.path(imdb_dir, "train") %>%
  dir_ls() %>%
  map(dir_ls) %>%
  set_names(basename) %>%
  plyr::ldply(data_frame) %>%
  set_names(c("label", "path"))

obs <- nrow(training_files)
labels <- vector(mode = "integer", length = obs)
texts <- vector(mode = "character", length = obs)

for (file in seq_len(obs)) {
  label <- training_files[[file, "label"]]
  path <- training_files[[file, "path"]]
  
  labels[file] <- ifelse(label == "neg", 0, 1)
  texts[file] <- readChar(path, nchars = file.size(path)) 
  
}

cat(cli::symbol$tick, "\n", append = TRUE)

# Prepare tokenizer ------------------------ -----------------------------
cat("Processing text with tokenizer...")

top_n_words <- 10000

tokenizer <- text_tokenizer(num_words = top_n_words) %>% 
  fit_text_tokenizer(texts)

total_word_index <- tokenizer$word_index
num_words_used <- tokenizer$num_words

cat(cli::symbol$tick, "\n", append = TRUE)

# Preparing feature and label tensors -------------------------------------
cat("Creating feature and label tensors...")

labels <- as.array(labels)
sequences <- texts_to_sequences(tokenizer, texts)

max_len <- 150
features <- pad_sequences(sequences, maxlen = max_len)

# randomizing
set.seed(123)
index <- sample(1:nrow(features))
features <- features[index, ]
labels <- labels[index]

cat(cli::symbol$tick, "\n", append = TRUE)

# Clean up ----------------------------------------------------------------
cat("Cleaning up global environment...")

rm(imdb_dir, training_files, obs, path, label, file, index)

cat(cli::symbol$tick, "\n", append = TRUE)
