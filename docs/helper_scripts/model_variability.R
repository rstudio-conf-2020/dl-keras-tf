library(keras)     # for deep learning
library(tidyverse) # for dplyr, ggplot2, etc.
library(rsample)   # for data splitting
library(recipes)   # for feature engineering

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
baked_test <- bake(prepare, new_data = ames_test)

x_train <- select(baked_train, -Sale_Price) %>% as.matrix()
y_train <- baked_train %>% pull(Sale_Price)

x_test <- select(baked_test, -Sale_Price) %>% as.matrix()
y_test <- baked_test %>% pull(Sale_Price)


# Model variance due to initial weight randomization ----------------------

set.seed(123)
index <- sample(1:nrow(x_train), size = floor(nrow(x_train) * 0.8))

x_train_sub <- x_train[index,]
y_train_sub <- y_train[index]

x_val <- x_train[-index,]
y_val <- y_train[-index]

length(y_train_sub)
length(y_val)

results <- data.frame()

for (i in seq_len(100)) {
  
  cat("Starting model", i, "\n")
  
  network <- keras_model_sequential() %>% 
    layer_dense(units = 128, activation = "relu", input_shape = ncol(x_train)) %>% 
    layer_dense(units = 128, activation = "relu") %>%
    layer_dense(units = 1)
  
  network %>% compile(
    optimizer = "rmsprop",
    loss = "msle",
    metrics = c("mae")
  )
  
  history <- network %>% fit(
    x_train,
    y_train,
    epochs = 20,
    batch_size = 32,
    validation_data = list(x_val, y_val),
    verbose = FALSE
  )
  
  m_results <- data.frame(Model = i, Loss = history$metrics$val_loss, Epoch = 1:history$params$epochs)
  results <- rbind(results, m_results)
}

readr::write_csv(results, path = "docs/data/model_variance_due_to_weights.csv")

ggplot(results, aes(Epoch, Loss, group = Model)) +
  geom_line(alpha = 0.5)

results %>%
  group_by(Model) %>%
  summarize(Min_loss = min(Loss)) %>%
  ggplot(aes(Min_loss)) +
  geom_histogram()


# Model variance due to different validation data ----------------------

results <- data.frame()
tensorflow::use_session_with_seed(42)

for (i in seq_len(100)) {
  
  cat("Starting model", i, "\n")
  
  network <- keras_model_sequential() %>% 
    layer_dense(units = 128, activation = "relu", input_shape = ncol(x_train)) %>% 
    layer_dense(units = 128, activation = "relu") %>%
    layer_dense(units = 1)
  
  network %>% compile(
    optimizer = "rmsprop",
    loss = "msle",
    metrics = c("mae")
  )
  
  history <- network %>% fit(
    x_train,
    y_train,
    epochs = 20,
    batch_size = 32,
    validation_split = 0.2,
    verbose = FALSE
  )
  
  m_results <- data.frame(Model = i, Loss = history$metrics$val_loss, Epoch = 1:history$params$epochs)
  results <- rbind(results, m_results)
}

readr::write_csv(results, path = "docs/data/model_variance_due_to_val_data.csv")

ggplot(results, aes(Epoch, Loss, group = Model)) +
  geom_line(alpha = 0.5)

results %>%
  group_by(Model) %>%
  summarize(Min_loss = min(Loss)) %>%
  ggplot(aes(Min_loss)) +
  geom_histogram()
