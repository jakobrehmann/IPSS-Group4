enter_path_here <- "/Users/sydney/Dropbox/JAKOB-SYDNEY/2023-12-04T141138-0.5"
setwd(enter_path_here)

files <- list.files(path=enter_path_here, pattern="*.csv", full.names=FALSE, recursive=FALSE)
files <- files[files != "_info.csv"]
files <- files[str_detect(files, "infectionChance")]
files <- files[!grepl("regular", files)]

dataSetFull <- data.frame()

for(i in 1:(length(files))){
  file <- files[i]
    dataSetNew <- read.csv(file)
    dataSetNew <- dataSetNew[-1,]
    dataSetNew$ID <- seq.int(nrow(dataSetNew))
    dataSetNew$DiseaseState <- str_split(file, "-")[[1]][[length(str_split(file, "-")[[1]])-1]]
    dataSetNew <- pivot_longer(dataSetNew, cols = seed1:seed100)
    dataSetFull <- rbind(dataSetFull, dataSetNew)
}

dataSetGrouped <- dataSetFull %>% group_by(ID, DiseaseState) %>% summarise(mean = mean(value, na.rm=TRUE), sd = sd(value))
dataSetGrouped <- dataSetGrouped %>% ungroup()
dataSetGrouped <- dataSetGrouped %>% mutate(ymin = case_when(mean-sd > 0 ~ mean-sd, 
                                                             .default = 0))
ggplot(dataSetGrouped, aes(x=ID, y = mean)) +
  geom_line(aes(color=DiseaseState)) +
  theme_minimal() +
  # scale_y_log10() +
  xlab("Time step") +
  ylab("Infections") +
  theme(legend.position = "bottom", legend.title = element_blank())
