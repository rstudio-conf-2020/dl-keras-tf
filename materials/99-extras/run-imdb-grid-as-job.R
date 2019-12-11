library(tfruns)

extras_dir <- here::here("materials", "99-extras")
runs_dr <- file.path(extras_dir, "imdb_runs")
grid_file <- file.path(extras_dir, "imdb-grid-search.R")

clean_runs(runs_dir = runs_dr, confirm = FALSE)

grid_search <- list(
  batch_size = c(128, 512),
  layers = c(1, 2, 3),
  units = c(16, 32, 64),
  learning_rate = c(0.001, 0.0001),
  dropout = c(0, 0.3, 0.5),
  weight_decay = c(0, 0.01, 0.001)
)

tuning_run(
  grid_file,
  flags = grid_search,
  runs_dir = runs_dr,
  confirm = FALSE,
  echo = FALSE
)