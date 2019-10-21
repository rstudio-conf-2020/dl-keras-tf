original_dataset_dir <- here::here("docs", "data", "project1", "full")
folders <- list.files(original_dataset_dir)

for (folder in folders) {
  
  # original & new path
  original_path <- file.path(original_dataset_dir, folder)
  
  # get number of images
  n_total_images <- length(list.files(file.path(original_dataset_dir, folder)))
  n_train_images <- floor(n_total_images * .60)
  n_valid_images <- floor(n_total_images * .20)
  n_test_images <- floor(n_total_images * .20)
  
  # save 60% of images to train
  first_train_image <- 0
  last_train_image <- n_train_images - 1
  train_ext <-  stringr::str_pad(first_train_image:last_train_image, 4, pad = "0")
  train_images <- paste0(folder, "_", train_ext, ".jpg")
  train_path <- here::here("docs", "data", "project1", "train", folder)
  file.copy(from = file.path(original_path, train_images), to = train_path)
  
  # save 20% of images to valid
  first_valid_image <- last_train_image + 1
  last_valid_image <- first_valid_image + n_valid_images - 1
  valid_ext <-  stringr::str_pad(first_valid_image:last_valid_image, 4, pad = "0")
  valid_images <- paste0(folder, "_", valid_ext, ".jpg")
  valid_path <- here::here("docs", "data", "project1", "validation", folder)
  file.copy(from = file.path(original_path, valid_images), to = valid_path)
  
  # save 20% of images to test
  first_test_image <- last_valid_image + 1
  last_test_image <- first_test_image + n_test_images - 1
  train_ext <- stringr::str_pad(first_test_image:last_test_image, 4, pad = "0")
  test_images <- paste0(folder, "_", train_ext, ".jpg")
  test_path <- here::here("docs", "data", "project1", "test", folder)
  file.copy(from = file.path(original_path, test_images), to = test_path)
  
}
