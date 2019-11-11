# See http://text2vec.org/glove.html for more details about text2vec
get_embeddings <- function(text) {
  
  # Create iterator over tokens
  tokens <- text2vec::space_tokenizer(text)
  
  # Create vocabulary. Terms will be unigrams (simple words).
  message("Creating vocabulary...")
  it <- text2vec::itoken(tokens, progressbar = FALSE)
  vocab <- text2vec::create_vocabulary(it)
  vocab <- text2vec::prune_vocabulary(vocab, term_count_min = 5L)
  
  # Use our filtered vocabulary
  vectorizer <- vocab_vectorizer(vocab)
  
  # Use window of 5 for context words
  message("Creating term-co-occurence matrix...")
  tcm <- text2vec::create_tcm(it, vectorizer, skip_grams_window = 5L)
  
  # Fit the model
  message("Computing embeddings based on GloVe algorithm...")
  glove <- text2vec::GlobalVectors$new(
    word_vectors_size = 50, 
    vocabulary = vocab, 
    x_max = 10
    )
  wv_main <- glove$fit_transform(tcm, n_iter = 20, convergence_tol = 0.01)
  wv_context = glove$components
  wv_main + t(wv_context)
}

get_similar_words <- function(reference_word, word_embeddings) {
  
  # Find closest aligned word embeddings based on cosine similarity
  tryCatch({
    word <- word_embeddings[reference_word, , drop = FALSE]
  },
    error = function(e) {
      stop("The supplied word (", word, ") is not part of the created vocabulary.")
    }
  )
  
  cos_sim <- text2vec::sim2(
    x = word_embeddings, 
    y = word, 
    method = "cosine", 
    norm = "l2"
    )
  
  head(sort(cos_sim[,1], decreasing = TRUE), 5)
  
}

