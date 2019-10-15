original_dataset_dir <- here::here("docs", "data", "dogs-vs-cats", "full")

train_cats <- here::here("docs", "data", "dogs-vs-cats", "train", "cats")
train_dogs <- here::here("docs", "data", "dogs-vs-cats", "train", "dogs")

validation_cats <- here::here("docs", "data", "dogs-vs-cats", "validation", "cats")
validation_dogs <- here::here("docs", "data", "dogs-vs-cats", "validation", "dogs")

test_cats <- here::here("docs", "data", "dogs-vs-cats", "test", "cats")
test_dogs <- here::here("docs", "data", "dogs-vs-cats", "test", "dogs")

# copy cat images to train, validation, and test folders
fnames <- paste0("cat.", 1:1000, ".jpg")
file.copy(from = file.path(original_dataset_dir, fnames), to = train_cats)

fnames <- paste0("cat.", 1001:1500, ".jpg")
file.copy(from = file.path(original_dataset_dir, fnames), to = validation_cats)

fnames <- paste0("cat.", 1501:2000, ".jpg")
file.copy(from = file.path(original_dataset_dir, fnames), to = test_cats)

# copy dog images to train, validation, and test folders
fnames <- paste0("dog.", 1:1000, ".jpg")
file.copy(from = file.path(original_dataset_dir, fnames), to = train_dogs)

fnames <- paste0("dog.", 1001:1500, ".jpg")
file.copy(from = file.path(original_dataset_dir, fnames), to = validation_dogs)

fnames <- paste0("dog.", 1501:2000, ".jpg")
file.copy(from = file.path(original_dataset_dir, fnames), to = test_dogs)

# check results
cat("total training cat images:", length(list.files(train_cats)), "\n")
cat("total validation cat images:", length(list.files(validation_cats)), "\n")
cat("total test cat images:", length(list.files(test_cats)), "\n")

cat("total training dog images:", length(list.files(train_dogs)), "\n")
cat("total validation dog images:", length(list.files(validation_dogs)), "\n")
cat("total test dog images:", length(list.files(test_dogs)), "\n")
