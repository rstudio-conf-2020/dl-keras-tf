library(keras)
library(tidyverse)

# Hyperparameter flags ---------------------------------------------------

# set flags for hyperparameters of interest (we include default values)
FLAGS <- flags(
  flag_integer("top_n_words", 10000),
  flag_integer("max_len", 150),
  flag_integer("output_dim", 32),
  flag_numeric("learning_rate", 0.001),
  flag_integer("batch_size", 128),
  flag_integer("layers", 1),
  flag_integer("units", 16),
  flag_numeric("dropout", 0.5),
  flag_numeric("weight_decay", 0.01)
)

# Data Preparation ---------------------------------------------------

# Import our Amazon food review data and prepare the training feature set as in
# https://rstudio-conf-2020.github.io/dl-keras-tf/notebooks/01-word-embeddings.nb.html
amazon_reviews <- here::here("materials", "data", "amazon-food", "finefoods.txt")
reviews <- read_lines(amazon_reviews)

review_text <- reviews[str_detect(reviews, "review/text:")]
helpfulness_info <- reviews[str_detect(reviews, "review/helpfulness:")] %>%
  str_extract("\\d.*")

text <- review_text %>%
  str_replace("review/text:", "") %>%
  iconv(to = "UTF-8") %>%
  str_trim()

num_reviews <- str_replace(helpfulness_info, "^.*\\/", "") %>% as.integer()
helpfulness <- str_replace(helpfulness_info, "\\/.*$", "") %>% as.integer()
num_index <- num_reviews >= 10
num_reviews <- num_reviews[num_index]
helpfulness <- helpfulness[num_index]
text <- text[num_index]

labels <- helpfulness / num_reviews

# Prepare tokenized data based on flags
tokenizer <- text_tokenizer(num_words = FLAGS$top_n_words) %>% 
  fit_text_tokenizer(text)

sequences <- texts_to_sequences(tokenizer, text)
features <- pad_sequences(sequences, maxlen = FLAGS$max_len)

# Randomize and prepare train/validation
set.seed(123)
index <- sample(1:nrow(features))
split_point <- floor(length(index) * .3)
train_index <- index[1:split_point]
valid_index <- index[(split_point + 1):length(index)]

x_train <- features[train_index, ]
y_train <- labels[train_index]

x_valid <- features[valid_index, ]
y_valid <- labels[valid_index]

# Define Model --------------------------------------------------------------

# Create embedding layer
network <- keras_model_sequential() %>%
  layer_embedding(input_dim = FLAGS$top_n_words, 
                  output_dim = FLAGS$output_dim,
                  input_length = FLAGS$max_len) %>%  # 100 length of each review.
  layer_flatten()

# Create classifier with n layers
for (i in seq_len(FLAGS$layers)) {
  network %>% 
    layer_dense(units = FLAGS$units, activation = "relu",
                kernel_regularizer = regularizer_l2(l = FLAGS$weight_decay)) %>%
    layer_dropout(rate = FLAGS$dropout)
}

# Add final output layer
network %>% layer_dense(units = 1, activation = "sigmoid")

# create metric using backend tensor functions
metric_clipped_mse <- custom_metric("metric_capped_msle", function(y_true, y_pred) {
  y_pred <- k_clip(y_pred, 0, 1)
  k_mean(k_square(y_pred - y_true))
})

# Add compile step
network %>% compile(
  optimizer = optimizer_rmsprop(lr = FLAGS$learning_rate),
  loss = metric_clipped_mse,
  metrics = c("mse", "mae")
)

# Train model
history <- network %>% 
  fit(
    x_train,
    y_train, 
    epochs = 100,
    batch_size = FLAGS$batch_size,
    validation_data = list(x_valid, y_valid),
    verbose = FALSE,
    callbacks = list(
      callback_reduce_lr_on_plateau(patience = 3),
      callback_early_stopping(patience = 10)
    )
  )

# Report minimum loss ----------------------------------------------------

# Since our model reports the loss and accuracy for the last epoch, I like to
# create additional metrics that report the best loss score during the training
# run. Rarely is the last epoch the optimal epoch.
best_epoch <- which.min(history$metrics$val_loss)
best_loss <- history$metrics$val_loss[best_epoch] %>% round(3)
best_mse <- history$metrics$val_mse[best_epoch] %>% round(3)
best_mae <- history$metrics$val_mae[best_epoch] %>% round(3)

extra_metrics <- list(
  best_epoch = best_epoch,
  best_loss = best_loss,
  best_mse = best_mse,
  best_mae = best_mae
)

tfruns::write_run_metadata("evaluation", extra_metrics)
