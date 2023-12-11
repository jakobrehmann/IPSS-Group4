enter_path_here <- "/Users/sydney/Dropbox/JAKOB-SYDNEY/2023-12-04T141138-0.5"
setwd(enter_path_here)

files <- list.files(path=enter_path_here, pattern="*.csv", full.names=FALSE, recursive=FALSE)
files <- files[files != "_info.csv"]
files <- files[!grepl("smallworld", files)]

for(i in 1:(length(files)/4)){
  lowerCounter <- 1+(i-1)*4
  upperCounter <- 4*i
  filesReduced <- files[lowerCounter:upperCounter]
  
  dataSetFull <- data.frame()
  
  for(file in filesReduced){
    dataSetNew <- read.csv(file)
    dataSetNew$ID <- seq.int(nrow(dataSetNew))
    dataSetNew$DiseaseState <- str_split(file, "-")[[1]][[4]]
    dataSetNew <- pivot_longer(dataSetNew, cols = seed1:seed100)
    dataSetFull <- rbind(dataSetFull, dataSetNew)
  }
 
noTimeSteps <- max(dataSetFull$ID) 
dataSetFull <- dataSetFull %>% filter(DiseaseState == "recovered.csv") %>% filter(ID == noTimeSteps)


plot <- ggplot(dataSetFull, aes(x=value)) + 
  geom_density(color="darkblue", fill="lightblue", alpha = 0.2) +
  theme_minimal() +
  xlab("Final size") +
  ylab("Density")


file_name <- paste0(str_split(file, "-")[[1]][[1]], "-DensityPlot.pdf")
ggsave(file_name, plot, dpi = 500, w = 9, h = 4.5)
}
  
