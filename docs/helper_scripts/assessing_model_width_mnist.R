library(keras)    
library(tidyverse)     

mnist <- dataset_mnist()
c(c(train_images, train_labels), c(test_images, test_labels)) %<-% mnist

train_images <- array_reshape(train_images, c(60000, 28 * 28))
test_images <- array_reshape(test_images, c(10000, 28 * 28))

train_images <- train_images / 255
test_images <- test_images / 255

train_labels <- to_categorical(train_labels)
test_labels <- to_categorical(test_labels)

n_features <- ncol(train_images)


# Assess model width ------------------------------------------------------

dl_model <- function(powerto = 6) {
  
  network <- keras_model_sequential() %>%
    layer_dense(units = 2^powerto, activation = "relu", input_shape = n_features) %>% 
    layer_dense(units = 10, activation = "softmax") %>%
    compile(
      loss = "categorical_crossentropy",
      optimizer = "rmsprop",
      metrics = c("accuracy")
    )
  
  history <- network %>% 
    fit(
      train_images,
      train_labels, 
      epochs = 50,
      batch_size = 128,
      validation_split = 0.2,
      verbose = FALSE
    )
  
  output <- as.data.frame(history) %>%
    mutate(neurons = 2^powerto)
  
  return(output)
}

get_min_loss <- function(output) {
  output %>%
    filter(data == "validation", metric == "loss") %>%
    summarize(min_loss = min(value)) %>%
    pull(min_loss) %>%
    round(3)
}

# so that we can store results
results <- data.frame()
powerto_range <- 2:10

for (i in powerto_range) {
  cat("Running model with", 2^i, "neurons per hidden layer: ")
  mod_time <- system.time(
    m <- dl_model(i)
  )
  m$time <- mod_time[[3]]
  results <- rbind(results, m)
  loss <- get_min_loss(m)
  cat(loss, "\n", append = TRUE)
}

ggplot(results, aes(epoch, value, color = factor(neurons))) +
  geom_line() +
  geom_point(data = filter(results, neurons == 64), show.legend = FALSE) +
  facet_grid(metric ~ data, scales = 'free_y') + 
  scale_y_log10("Loss")


# Assess model depth ------------------------------------------------------

dl_model <- function(nlayers = 2, powerto = 6) {
  
  # Create a model with a single hidden input layer
  network <- keras_model_sequential() %>%
    layer_dense(units = 2^powerto, activation = "relu", input_shape = n_features)
  
  # Add additional hidden layers based on input
  if (nlayers > 1) {
    for (i in seq_along(nlayers - 1)) {
      network %>% layer_dense(units = 2^powerto, activation = "relu")
    }
  }
  
  # Add final output layer
  network %>% layer_dense(units = 10, activation = "softmax")
  
  
  # Add compile step
  network %>% compile(
    optimizer = "rmsprop",
    loss = "categorical_crossentropy",
    metrics = c("accuracy")
  )
  
  # Train model
  history <- network %>% 
    fit(
      train_images,
      train_labels, 
      epochs = 50,
      batch_size = 128,
      validation_split = 0.2,
      verbose = FALSE
    )
  
  # Create formated output for downstream plotting & analysis
  output <- as.data.frame(history) %>%
    mutate(nlayers = nlayers, neurons = 2^powerto)
  
  return(output)
}

# so that we can store results
results <- data.frame()
nlayers <- 1:8

for (i in nlayers) {
  cat("Running model with", i, "hidden layer and 64 neurons per layer: ")
  mod_time <- system.time(
    m <- dl_model(nlayers = i, powerto = 7)
  )
  m$time <- mod_time[[3]]
  results <- rbind(results, m)
  loss <- get_min_loss(m)
  cat(loss, "\n", append = TRUE)
}
