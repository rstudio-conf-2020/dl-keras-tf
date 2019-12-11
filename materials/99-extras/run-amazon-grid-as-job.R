library(tfruns)

extras_dir <- here::here("materials", "99-extras")
runs_dr <- file.path(extras_dir, "amazon_runs")
grid_file <- file.path(extras_dir, "amazon-embeddings-grid-search.R")

clean_runs(runs_dir = runs_dr, confirm = FALSE)

grid_search <- list(
  top_n_words = c(5000, 10000, 20000),
  max_len = c(75, 150, 200),
  output_dim = c(16, 32, 64),
  learning_rate = c(0.001, 0.0001),
  batch_size = c(32, 64, 128),
  layers = c(1, 2, 3),
  units = c(16, 32, 128),
  dropout = c(0, 0.5),
  weight_decay = c(0, 0.01)
)

tuning_run(
  grid_file,
  flags = grid_search,
  runs_dir = runs_dr,
  sample = 0.1,
  confirm = FALSE,
  echo = FALSE
)