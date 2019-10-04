library(keras)     # for deep learning
library(tidyverse) # for dplyr, ggplot2, etc.
library(rsample)   # for data splitting
library(recipes)   # for feature engineering


# Prep data ---------------------------------------------------------------

ames <- AmesHousing::make_ames()

set.seed(123)
ames_split <- initial_split(ames, prop = 0.8)
ames_train <- analysis(ames_split)
ames_test <- assessment(ames_split)

blueprint <- recipe(Sale_Price ~ ., data = ames_train) %>%
  step_nzv(all_nominal()) %>%
  step_other(all_nominal(), threshold = .01, other = "other") %>%
  step_integer(matches("(Qual|Cond|QC|Qu)$")) %>%
  step_YeoJohnson(all_numeric(), -all_outcomes()) %>%
  step_center(all_numeric(), -all_outcomes()) %>%
  step_scale(all_numeric(), -all_outcomes()) %>%
  step_dummy(all_nominal(), -all_outcomes(), one_hot = TRUE)

prepare <- prep(blueprint, training = ames_train)
baked_train <- bake(prepare, new_data = ames_train)

x_train <- select(baked_train, -Sale_Price) %>% as.matrix()
y_train <- baked_train %>% pull(Sale_Price)

n_features <- ncol(x_train)

# Assess model width ------------------------------------------------------

dl_model <- function(powerto = 6) {
  
  network <- keras_model_sequential() %>%
    layer_dense(units = 2^powerto, activation = "relu", input_shape = n_features) %>% 
    layer_dense(units = 1) %>%
    compile(
      loss = "msle",
      optimizer = "rmsprop",
      metrics = c("mae")
    )
  
  history <- network %>% 
    fit(
      x_train,
      y_train, 
      epochs = 50,
      batch_size = 32,
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

results %>%
  filter(data == "validation", metric == "loss") %>%
  ggplot(aes(epoch, value, color = factor(neurons))) +
  geom_line() +
  scale_y_log10("Loss")

results %>%
  group_by(neurons) %>%
  summarize(train_time = min(time)) %>%
  ggplot(aes(factor(neurons), train_time)) +
  geom_col()

results %>% 
  filter(data == "validation", metric == "loss") %>% 
  group_by(neurons) %>% 
  summarise(loss = min(value), time = min(time)) %>% 
  rename(min_loss = "loss", train_time = "time")

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
  network %>% layer_dense(units = 1)
  
  
  # Add compile step
  network %>% compile(
    optimizer = "rmsprop",
    loss = "msle",
    metrics = c("mae")
  )
  
  # Train model
  history <- network %>% 
    fit(
      x_train,
      y_train, 
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
nlayers <- 1:9

for (i in nlayers) {
  cat("Running model with", i, "hidden layer(s) and 64 neurons per layer: ")
  mod_time <- system.time(
    m <- dl_model(nlayers = i, powerto = 7)
  )
  m$time <- mod_time[[3]]
  results <- rbind(results, m)
  loss <- get_min_loss(m)
  cat(loss, "\n", append = TRUE)
}

results %>% 
  filter(data == "validation", metric == "loss") %>% 
  group_by(nlayers) %>% 
  summarise(loss = min(value), time = min(time)) %>% 
  rename(min_loss = "loss", train_time = "time")

