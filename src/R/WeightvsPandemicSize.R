enter_path_here <- "/Users/sydney/Dropbox/JAKOB-SYDNEY/2023-12-05T223336"
setwd(enter_path_here)

files <- list.files(path=enter_path_here, pattern="*recovered.csv", full.names=FALSE, recursive=FALSE)
files <- files[files != paste0(enter_path_here, "_info.csv")]
files <- files[!grepl("smallworld", files)]

dataSetFull <- data.frame()

for(i in 1:(length(files))){
  filesReduced <- files[i]
  
  for(file in filesReduced){
    dataSetNew <- read.csv(file)
    dataSetNew$ID <- seq.int(nrow(dataSetNew))
    dataSetNew$BaseSuscep <- str_split(file, "-")[[1]][[2]]
    dataSetNew$DiseaseState <- str_split(file, "-")[[1]][[3]]
    dataSetNew <- pivot_longer(dataSetNew, cols = seed1:seed100)
    dataSetFull <- rbind(dataSetFull, dataSetNew)
  }
}

dataSetGrouped <- dataSetFull %>% group_by(BaseSuscep, DiseaseState, ID) %>% summarise(mean = mean(value), sd = sd(value))
dataSetGrouped <- dataSetGrouped %>% ungroup()

noTimeSteps <- max(dataSetGrouped$ID) 
dataSetGrouped <- dataSetGrouped %>% filter(ID == noTimeSteps)

ggplot(dataSetGrouped, aes(x=DiseaseState, y = mean)) +
  geom_point() + 
  xlab("w") +
  ylab("Pandemic size (# of recovered, afrer 100 steps") +
  theme_minimal() +
  facet_wrap(~BaseSuscep)


#ggsave(paste0(str_split(file, "-")[[1]][[1]], "WeightVsPandemicSize.pdf"), dpi = 500, w = 9, h = 3)   

