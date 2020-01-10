library(keras)
library(tensorflow)
library(tfdatasets)
library(tidyverse)
ggplot2::theme_set(ggplot2::theme_bw())

# Prepare training and test sets ------------------------------------------

batch_size <- 32
total_obs <- batch_size*100
train_obs <- batch_size*70

set.seed(123)
generated <- mlbench::mlbench.simplex(n = total_obs, d = 2, sd = 0.4)
X <- generated$x
y <- generated$classes

ggplot(data.frame(X, y), aes(X1, X2, color = y)) +
  geom_point(size = 2)

X <- generated$x
y <- to_categorical(generated$classes)[, 2:4]

# random sample
set.seed(123)
train_index <- sample(nrow(y), train_obs, replace = FALSE)
x_train <- X[train_index, ]
y_train <- y[train_index, ]
x_test <- X[-train_index, ]
y_test <- y[-train_index, ]


# Create model training function ------------------------------------------

train_model <- function(learning_rate, momentum = 0){
  model <- keras_model_sequential() %>%
    layer_dense(units = 8, input_shape = ncol(x_train), activation = "relu", 
                kernel_initializer = "he_uniform") %>%
    layer_dense(units = 3, activation = "softmax")
  
  model %>% compile(
    optimizer = optimizer_sgd(lr = learning_rate, momentum = momentum),
    loss = "categorical_crossentropy",
    metrics = "accuracy"
  )
  
  history <- model %>% 
    fit(x_train, y_train, 
        batch_size = batch_size, epochs = 50, 
        validation_data = list(x_test, y_test),
        verbose = 0)
  
  as.data.frame(history) %>% mutate(lr = learning_rate, m = momentum)
}

# Model different learning rates  --------------------------------
results <- data.frame()
learning_rates <- c(1e-0, 1e-1, 1e-2, 1e-3, 1e-4, 1e-5)
for (rate in learning_rates) {
  cat("Model with learning rate =", rate, ": ")
  model_results <- train_model(rate)
  results <- rbind(results, model_results)
  
  # report results
  min_loss <- model_results %>%
    filter(metric == "loss", data == "validation") %>% 
    summarize(best_loss = min(value, na.rm = TRUE) %>% round(3)) %>% 
    pull()
  cat(min_loss, "\n", append = TRUE)
}

results %>%
  filter(metric == "accuracy") %>%
  mutate(lr = fct_rev(as.factor(lr))) %>%
  ggplot(aes(epoch, value, color = data)) +
  geom_line() +
  facet_wrap(~ lr, ncol = 2) +
  ylab("accuracy")

# Model different momentums  --------------------------------
results <- data.frame()
momentums <- c(0, 0.25, 0.5, 0.75, 0.9, 0.99)
for (momentum in momentums) {
  cat("Model with momentum =", momentum, ": ")
  model_results <- train_model(0.001, momentum)
  results <- rbind(results, model_results)
  
  # report results
  min_loss <- model_results %>%
    filter(metric == "loss", data == "validation") %>% 
    summarize(best_loss = min(value, na.rm = TRUE) %>% round(3)) %>% 
    pull()
  cat(min_loss, "\n", append = TRUE)
}

results %>%
  filter(metric == "accuracy") %>%
  mutate(m = as.factor(m)) %>%
  ggplot(aes(epoch, value, color = data)) +
  geom_line() +
  facet_wrap(~ m, ncol = 2) +
  ylab("accuracy")


# Create datasets for training and testing --------------------------------

model_structure <- function(momentum) {
  model <- keras_model_sequential() %>%
    layer_dense(units = 8, input_shape = ncol(x_train), activation = "relu", 
                kernel_initializer = "he_uniform") %>%
    layer_dense(units = 3, activation = "softmax")
  
  model %>% compile(
    optimizer = optimizer_sgd(lr = 0.001, momentum = momentum),
    loss = "categorical_crossentropy",
    metrics = "accuracy"
  )
}

all_wts <- data.frame()
my_grid <- expand.grid(
  epoch = 1:50,
  momentum = c(0.9)
  )

for (i in seq_len(nrow(my_grid))) {

  model <- model_structure(momentum = my_grid[i, "momentum"])
  history <- model %>% 
    fit(x_train, y_train, 
        batch_size = batch_size, epochs = my_grid[i, "epoch"], 
        validation_data = list(x_test, y_test),
        verbose = 0)
  
  model_wts <- get_weights(model)[[1]] %>% 
    t() %>% 
    as.data.frame() %>% 
    gather(node, weight) %>%
    mutate(
      node = row_number(),
      epochs = my_grid[i, "epoch"],
      momentum = my_grid[i, "momentum"] %>% as.character()
      )
  
  all_wts <- rbind(all_wts, model_wts)
}

#--------------------------------

model_no_momentum <- keras_model_sequential() %>%
  layer_dense(units = 8, input_shape = ncol(x_train), activation = "relu", 
              kernel_initializer = "he_uniform") %>%
  layer_dense(units = 3, activation = "softmax") %>%
  compile(
    optimizer = optimizer_sgd(lr = 0.001, momentum = 0),
    loss = "categorical_crossentropy",
    metrics = "accuracy"
)

model_w_momentum <- keras_model_sequential() %>%
  layer_dense(units = 8, input_shape = ncol(x_train), activation = "relu", 
              kernel_initializer = "he_uniform") %>%
  layer_dense(units = 3, activation = "softmax") %>%
  compile(
    optimizer = optimizer_sgd(lr = 0.001, momentum = 0.9),
    loss = "categorical_crossentropy",
    metrics = "accuracy"
  )

get_wts <- function(model, momentum) {
  get_weights(model)[[1]] %>% 
    t() %>% 
    as.data.frame() %>% 
    mutate(
      node = row_number(),
      epochs = counter,
      momentum = momentum
    )
}

all_wts <- data.frame()
counter <- 1
for (i in rep(1, 50)) {
    
  history_no_momentum  <- model_no_momentum %>% 
    fit(x_train, y_train, 
        batch_size = batch_size, epochs = i, 
        validation_data = list(x_test, y_test),
        verbose = 0)
  
  history_w_momentum  <- model_w_momentum  %>% 
    fit(x_train, y_train, 
        batch_size = batch_size, epochs = i, 
        validation_data = list(x_test, y_test),
        verbose = 0)
  
  wts_no_momentum <- get_wts(model_no_momentum, momentum = FALSE)
  wts_w_momentum <- get_wts(model_w_momentum, momentum = TRUE)
  
  all_wts <- rbind(all_wts, rbind(wts_no_momentum, wts_w_momentum))
  counter <- counter + 1
}

# Plot progression of weights ---------------------------------------------

all_wts %>%
  ggplot(aes(epochs, V1, color = momentum)) +
  geom_line() +
  facet_wrap(~ node, scales = "free", ncol = 2)

# Model difference optimizers ---------------------------------------------

# first we need to create some initial weights
model <- keras_model_sequential() %>%
  layer_dense(units = 8, input_shape = ncol(x_train), activation = "relu", 
              kernel_initializer = "he_uniform") %>%
  layer_dense(units = 3, activation = "softmax") %>%
  compile(
    optimizer = optimizer,
    loss = "categorical_crossentropy",
    metrics = "accuracy"
  )

history  <- model  %>% 
  fit(x_train, y_train, 
      batch_size = batch_size, epochs = 1, 
      validation_data = list(x_test, y_test),
      verbose = 0)

initial_wts <- get_weights(model)[1:2]


all_wts <- data.frame()
optimizers <- c("sgd", "rmsprop", "adadelta", "adagrad", "adam", "adamax", "nadam")

for (optimizer in optimizers) {
  model <- keras_model_sequential() %>%
    layer_dense(units = 8, input_shape = ncol(x_train), activation = "relu", 
                kernel_initializer = "he_uniform") %>%
    layer_dense(units = 3, activation = "softmax") %>%
    compile(
      optimizer = optimizer,
      loss = "categorical_crossentropy",
      metrics = "accuracy"
    )
  
  # same initial weights
  get_layer(model, index = 1) %>%
    set_weights(initial_wts)

  counter <- 1
  for (i in rep(1, 50)) {
    
    history  <- model  %>% 
      fit(x_train, y_train, 
          batch_size = batch_size, epochs = i, 
          validation_data = list(x_test, y_test),
          verbose = 0)
    
    model_wts <- get_weights(model)[[1]] %>% 
      t() %>% 
      as.data.frame() %>% 
      mutate(
        node = row_number(),
        epochs = counter,
        optimizer = optimizer
      )
    
    all_wts <- rbind(all_wts, model_wts)
    counter <- counter + 1
  }
}

all_wts %>%
  ggplot(aes(epochs, V1, color = optimizer)) +
  geom_line() +
  facet_wrap(~ node, scales = "free", ncol = 2)
