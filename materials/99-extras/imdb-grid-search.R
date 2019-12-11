library(keras)

# Data Preparation ---------------------------------------------------

# Import our IMDB movie data and prepare the training feature set using
# one hot encoding as in https://rstudio-conf-2020.github.io/dl-keras-tf/notebooks/02-imdb.nb.html
imdb <- dataset_imdb(num_words = 10001)
c(c(reviews_train, y_train), c(reviews_test, y_test)) %<-% imdb

# number of unique words will be the number of features
n_features <- c(reviews_train, reviews_test) %>%  
  unlist() %>% 
  max()

# function to create 2D tensor (aka matrix)
vectorize_sequences <- function(sequences, dimension = n_features) {
  # Create a matrix of 0s
  results <- matrix(0, nrow = length(sequences), ncol = dimension)
  
  # Populate the matrix with 1s
  for (i in seq_along(sequences))
    results[i, sequences[[i]]] <- 1
  results
}

# apply to training and test data
x_train <- vectorize_sequences(reviews_train)
x_test <- vectorize_sequences(reviews_test)


# Hyperparameter flags ---------------------------------------------------

# set flags for hyperparameters of interest (we include default values)
FLAGS <- flags(
  flag_integer("batch_size", 512),
  flag_integer("layers", 2),
  flag_integer("units", 16),
  flag_numeric("learning_rate", 0.01),
  flag_numeric("dropout", 0.5),
  flag_numeric("weight_decay", 0.01)
)

# Define Model --------------------------------------------------------------

# Create a model with a single hidden input layer
network <- keras_model_sequential() %>%
  layer_dense(units = FLAGS$units, activation = "relu", input_shape = n_features,
              kernel_regularizer = regularizer_l2(l = FLAGS$weight_decay)) %>%
  layer_dropout(rate = FLAGS$dropout)

# regularizing parameter --> Add additional hidden layers based on input
if (FLAGS$layers > 1) {
  for (i in seq_len(FLAGS$layers - 1)) {
    network %>% 
      layer_dense(units = FLAGS$units, activation = "relu",
                  kernel_regularizer = regularizer_l2(l = FLAGS$weight_decay)) %>%
      layer_dropout(rate = FLAGS$dropout)
  }
}

# Add final output layer
network %>% layer_dense(units = 1, activation = "sigmoid")

# Add compile step
network %>% compile(
  optimizer = optimizer_rmsprop(FLAGS$learning_rate),
  loss = "binary_crossentropy",
  metrics = c("accuracy")
)

# Train model
history <- network %>% 
  fit(
    x_train,
    y_train, 
    epochs = 100,
    batch_size = FLAGS$batch_size,
    validation_split = 0.2,
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
best_acc <- history$metrics$val_accuracy[best_epoch] %>% round(3)

extra_metrics <- list(
  best_epoch = best_epoch,
  best_loss = best_loss,
  best_acc = best_acc
)

tfruns::write_run_metadata("evaluation", extra_metrics)