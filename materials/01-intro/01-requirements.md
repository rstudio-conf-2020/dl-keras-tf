Installing Requirements
================

This notebook will help you install all the required packages and data
sets used throughout this workshop.

# Packages

Although this training focuses on the **keras** package, we will use
several additional packages throughout our modules. At the beginning of
each module I state the primary purpose of the packages used so if some
of these packages are not familiar, that is okay.

Run the following code chunk to install packages not already installed.
Within the RStudio workshop, this has already been taken care of for
you.

``` r
pkgs <- c(
  "AmesHousing",
  "caret",
  "crayon",
  "data.table",
  "fs",
  "glue",
  "here",
  "jpeg",
  "keras",
  "plotly",
  "recipes",
  "ROCR",
  "Rtsne",
  "rsample",
  "testthat",
  "text2vec",
  "tfruns",
  "tidyverse"
)

missing_pkgs <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]

if (length(missing_pkgs) > 0) {
  install.packages(missing_pkgs)
}
```

Depending on how often you update your packages you may also want to see
if any of these packages that you had installed previously need to be
updated to more recent versions. You can run the following to make
necessary
updates.

``` r
update.packages(oldPkgs = pkgs, ask = FALSE, repos = "https://cran.rstudio.com/")
```

# Datasets

We will use a variety of datasets throughout this workshop; many of
which are too large to hold within the github repository. The following
will help you download all necessary datasets and store them in the
`\data` folder. For those attending the RStudio workshop, this has
already been taken care of for you.

``` r
data_directory <- here::here("materials", "data")

if (!dir.exists(data_directory)) {
  dir.create(data_directory)
}
```

## Dogs vs cats

Used for image classification. Contains 25,000 images of dogs and cats
from [Kaggle](https://www.kaggle.com/c/dogs-vs-cats/data). To download,
you will need to following these steps:

1.  Create a Kaggle account
2.  Install the [Kaggle API](https://github.com/Kaggle/kaggle-api) with…
      - Run `pip install kaggle` in the terminal or
      - Run `system("pip install kaggle")` in the RStudio console
3.  Go to your Kaggle Account settings and select “Create New API
    Token”. This will download a JSON file with your access token.
4.  Move the JSON token file to the `/Users/your_id/.kaggle` folder
    ([reference](https://github.com/Kaggle/kaggle-api/issues/15))

Now you should be able to execute the following code to download the
data. This will download all the data but only place a fraction of the
data in train, validation, and test folders.

``` r
dogs_cats <- file.path(data_directory, "dogs-vs-cats")

if (!dir.exists(dogs_cats)) {
  # create main directory for images
  dir.create(dogs_cats)
  all_images <- file.path(dogs_cats, "full")
  dir.create(all_images)

  # download & extract images
  system("kaggle competitions download -c dogs-vs-cats")
  fs::file_move("dogs-vs-cats.zip", dogs_cats)
  
  for (zip_file in c("train.zip", "test1.zip")) {

    unzip(file.path(dogs_cats, "dogs-vs-cats.zip"), 
        files = zip_file,
        exdir = all_images)
    
    unzip(file.path(all_images, zip_file), exdir = all_images)
    file.remove(file.path(all_images, zip_file))
  }

  # create new subdirectories that contain only a fraction of the entire dataset
  new_directories <- expand.grid(
    directory = c("train", "validation", "test"),
    animal = c("cats", "dogs"),
    stringsAsFactors = FALSE
    )
  
  for (ob in 1:nrow(new_directories)) {
    # create new directories to store subset of images
    directory <- new_directories[ob, "directory"]
    animal <- new_directories[ob, "animal"]
    top_dir <- file.path(dogs_cats, directory)
    sub_dir <- file.path(dogs_cats, directory, animal)
    if (!dir.exists(top_dir)) dir.create(top_dir)
    dir.create(sub_dir)
    
    # create image file names and copy to new location
    img_tag <- switch(animal,
                      cats = "cat.",
                      dogs = "dog."
                      )
    quantity <- switch(directory,
                       train = 1:1000,
                       validation = 1001:1500,
                       test = 1501:2000)
    fnames <- paste0(img_tag, quantity, ".jpg")
    invisible(
      file.copy(from = file.path(all_images, "train", fnames), to = sub_dir)
    )
  }

  # clean up
  invisible(file.remove(file.path(dogs_cats, "dogs-vs-cats.zip")))
}
```

## Natural images

Used for the image classification project for day 1. This dataset was
orginally created as a benchmark dataset for the work on [*Effects of
Degradations on Deep Neural Network
Architectures*](https://arxiv.org/abs/1807.10108). The source code is
publicly available on
[GitHub](https://github.com/prasunroy/cnn-on-degraded-images) but the
data was pulled from
[Kaggle](https://www.kaggle.com/prasunroy/natural-images).

This dataset contains 6,899 images from 8 distinct classes compiled from
various sources. The classes include airplane, car, cat, dog, flower,
fruit, motorbike and person.

Similar to the Dogs vs. Cats data, you will need a Kaggle account to
download and the Kaggle API to download this data.

``` r
natural_images <- file.path(data_directory, "natural_images")

if (!dir.exists(natural_images)) {
  system("kaggle datasets download -d prasunroy/natural-images")
  fs::file_move("natural-images.zip", data_directory)
  unzip(file.path(data_directory, "natural-images.zip"), exdir = data_directory)
  
  original_dataset_dir <- file.path(data_directory, "natural_images")
  folders <- list.files(original_dataset_dir)
  
  for (new_folder in c("train", "validation", "test", "full")) {
    dir.create(file.path(original_dataset_dir, new_folder))
  }
  
  for (folder in folders) {
  
    # original & new path
    original_path <- file.path(original_dataset_dir, folder)
    
    # get number of images
    # 60% will go to training, 20% to validation, and the rest to testing
    n_total_images <- length(list.files(file.path(original_dataset_dir, folder)))
    n_train_images <- floor(n_total_images * .60)
    n_valid_images <- floor(n_total_images * .20)
    
    # save 60% of images to train
    first_train_image <- 0
    last_train_image <- n_train_images - 1
    train_ext <-  stringr::str_pad(first_train_image:last_train_image, 4, pad = "0")
    train_images <- paste0(folder, "_", train_ext, ".jpg")
    train_path <- file.path(original_dataset_dir, "train", folder)
    dir.create(train_path)
    invisible(file.copy(from = file.path(original_path, train_images), to = train_path))
    
    # save 20% of images to valid
    first_valid_image <- last_train_image + 1
    last_valid_image <- first_valid_image + n_valid_images - 1
    valid_ext <-  stringr::str_pad(first_valid_image:last_valid_image, 4, pad = "0")
    valid_images <- paste0(folder, "_", valid_ext, ".jpg")
    valid_path <- file.path(original_dataset_dir, "validation", folder)
    dir.create(valid_path)
    invisible(file.copy(from = file.path(original_path, valid_images), to = valid_path))
    
    # save 20% of images to test
    first_test_image <- last_valid_image + 1
    last_test_image <- n_total_images - 1 
    test_ext <- stringr::str_pad(first_test_image:last_test_image, 4, pad = "0")
    test_images <- paste0(folder, "_", test_ext, ".jpg")
    test_path <- file.path(original_dataset_dir, "test", folder)
    dir.create(test_path)
    invisible(file.copy(from = file.path(original_path, test_images), to = test_path))
    
    fs::file_move(original_path, file.path(original_dataset_dir, "full"))
  }
  
  # clean up
  invisible(file.remove(file.path(data_directory, "natural-images.zip")))
}
```

## Yelp reviews

Used for sentiment classification. Contains 1,569,264 samples from the
[Yelp Dataset Challenge 2015](https://www.yelp.com/dataset/challenge).
This subset has 280,000 training samples and 19,000 test samples in each
polarity.

``` r
yelp_data <- file.path(data_directory, "yelp_review_polarity_csv")

if (!dir.exists(yelp_data)) {
  url <- "http://s3.amazonaws.com/fast-ai-nlp/yelp_review_polarity_csv.tgz"
  download.file(url, destfile = "materials/data/tmp.tar.gz")
  untar("materials/data/tmp.tar.gz", exdir = "materials/data/")
  invisible(file.remove("materials/data/tmp.tar.gz"))
}
```
