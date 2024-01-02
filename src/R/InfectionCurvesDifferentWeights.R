enter_path_here <- "/Users/sydney/Documents/data/2023-12-15T112657"
setwd(enter_path_here)

files <- list.files(path=enter_path_here, pattern="*infectious-0.csv", full.names=FALSE, recursive=FALSE)
files <- files[files != paste0(enter_path_here, "_info.csv")]
files <- files[grepl("smallworld", files)]

dataSetFull <- data.frame()

for(i in 1:(length(files))){
  filesReduced <- files[i]
  
  for(file in filesReduced){
    dataSetNew <- read.csv(file)
    dataSetNew$ID <- seq.int(nrow(dataSetNew))
    dataSetNew$DiseaseState <- str_split(file, "-")[[1]][[3]]
    dataSetNew <- pivot_longer(dataSetNew, cols = seed1:seed100)
    dataSetFull <- rbind(dataSetFull, dataSetNew)
  }
}
  
  dataSetGrouped <- dataSetFull %>% group_by(DiseaseState, ID) %>% summarise(mean = mean(value), sd = sd(value))
  dataSetGrouped <- dataSetGrouped %>% ungroup()
  dataSetGrouped <- dataSetGrouped %>% mutate(ymin = case_when(mean-sd > 0 ~ mean-sd, 
                                                               .default = 0))
  
plot <- ggplot(dataSetGrouped, aes(x=ID, y = mean)) +
    geom_line(aes(color=DiseaseState)) +
    theme_minimal() +
   # scale_y_log10() +
    xlab("Time step") +
    ylab("Infections") +
    theme(legend.position = "bottom", legend.title = element_blank())
  
ggsave(paste0(str_split(file, "-")[[1]][[1]], "InfectionsDifferentScenarios.pdf"), plot, dpi = 500, w = 9, h = 3)   
