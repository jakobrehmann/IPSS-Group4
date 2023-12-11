enter_path_here <- enter_path_here <- "/Users/sydney/Dropbox/JAKOB-SYDNEY/2023-12-04T140608-0.1"
setwd(enter_path_here)

files <- list.files(path=enter_path_here, pattern="*.csv", full.names=FALSE, recursive=FALSE)
files <- files[files != "_info.csv"]
files <- files[!str_detect(files, "infectionChance")]
files <- files[!grepl("regular", files)]

for(i in 1:(length(files)/4)){
lowerCounter <- 1+(i-1)*4
upperCounter <- 4*i
filesReduced <- files[lowerCounter:upperCounter]

dataSetFull <- data.frame()

for(file in filesReduced){
  dataSetNew <- read.csv(file)
  dataSetNew$ID <- seq.int(nrow(dataSetNew))
  dataSetNew$DiseaseState <- str_split(file, "-")[[1]][[length(str_split(file, "-")[[1]])]]
  dataSetNew$DiseaseState <- substr(dataSetNew$DiseaseState,1,nchar(dataSetNew$DiseaseState)-4)
  dataSetNew <- pivot_longer(dataSetNew, cols = seed1:seed100)
  dataSetFull <- rbind(dataSetFull, dataSetNew)
}

dataSetGrouped <- dataSetFull %>% group_by(DiseaseState, ID) %>% summarise(mean = mean(value), sd = sd(value))
dataSetGrouped <- dataSetGrouped %>% ungroup()
dataSetGrouped <- dataSetGrouped %>% mutate(ymin = case_when(mean-sd > 0 ~ mean-sd, 
                                                             .default = 0))

plot <- ggplot(dataSetGrouped, aes(x=ID, y = mean)) +
  geom_line(aes(color=DiseaseState)) +
  geom_ribbon(aes(y = mean, ymin= ymin, ymax = mean+sd, fill = DiseaseState), alpha = 0.2) +
  theme_minimal() +
 # scale_y_log10() +
  xlab("Time step") +
  ylab("Number of nodes") +
  theme(legend.position = "bottom", legend.title = element_blank())

file_name <- paste0(str_split(file, "-")[[1]][[1]],"-", str_split(file, "-")[[1]][[3]], "-SEIRcurve.pdf")
ggsave(file_name, plot, dpi = 500, w = 9, h = 4.5)
}
