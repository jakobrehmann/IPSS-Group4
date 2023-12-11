enter_path_here <- "/Users/jakob/git/IPSS-Group4/data/2023-12-11T135715"
setwd(enter_path_here)

files <- list.files(path=enter_path_here, pattern="*infectious.csv", full.names=FALSE, recursive=FALSE)
files <- files[files != paste0(enter_path_here, "_info.csv")]
network_top <- "smallworld"
files <- files[grepl(network_top, files)]

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

dataSetGrouped <- dataSetFull %>% 
  group_by(BaseSuscep, DiseaseState, name) %>%
  summarise(maxInfected = max(value), timePointMax = which.max(value), sd = sd(value))
dataSetGrouped <- dataSetGrouped %>% ungroup() %>%
                  filter(maxInfected > 5)
dataSetGrouped <- dataSetGrouped %>% group_by(BaseSuscep, DiseaseState) %>%
                  summarise(mean = mean(maxInfected), meanTimePoint = mean(timePointMax))

ggplot(dataSetGrouped, aes(x=DiseaseState, y = mean)) +
  geom_point() + 
  xlab("weight") +
  theme_minimal() +
  facet_wrap(~ BaseSuscep) +
  #ggtitle(network_top) +
  xlab("Considered Scenario") +
  ylab("Maximum infected") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

#ggsave(paste0(str_split(file, "-")[[1]][[1]], "ScenarioVsMaxInfected.pdf"), dpi = 500, w = 9, h = 6)   

ggplot(dataSetGrouped, aes(x=DiseaseState, y = meanTimePoint)) +
geom_point() + 
xlab("weight") +
theme_minimal() +
facet_wrap(~ BaseSuscep) +
#ggtitle(network_top) +
xlab("Considered Scenario") +
ylab("Timing of peak") +
theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

#ggsave(paste0(str_split(file, "-")[[1]][[1]], "ScenarioVsPeakTiming.pdf"), dpi = 500, w = 9, h = 6)

dataSetGrouped <- dataSetFull %>%
  group_by(BaseSuscep, DiseaseState, name) %>%
  summarise(maxInfected = max(value), sd = sd(value)) %>%
  filter(maxInfected > 5)
#
ggplot(dataSetGrouped, aes(x=DiseaseState, y =maxInfected)) +
  geom_boxplot() +
  facet_wrap(~BaseSuscep) +
  theme_minimal()

dataSetGrouped$BaseSuscep <- as.numeric(dataSetGrouped$BaseSuscep)

dataSetGrouped <- dataSetGrouped %>% filter(DiseaseState != "local2")

ggplot(dataSetGrouped, aes(x=BaseSuscep, y = mean)) +
geom_line(aes(color=DiseaseState), size = 1.4) + 
ylab("Maximum infected") +
xlab("Base Infection Probability") +
theme_minimal() +
#ggtitle(network_top) +
scale_x_continuous(breaks = seq(from = 0.1, to = 0.3, by = 0.025)) +
theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
theme(text = element_text(size = 37)) +
theme(legend.position = "bottom", legend.title = element_blank()) +
theme(axis.ticks.x = element_line(),
      axis.ticks.y = element_line(),
      axis.ticks.length = unit(5, "pt"))

ggsave(paste0(str_split(file, "-")[[1]][[1]], "BaseSuscepVsMaxInfected.pdf"), dpi = 500, w = 9, h = 9)   

ggplot(dataSetGrouped, aes(x=BaseSuscep, y = meanTimePoint)) +
geom_line(aes(color=DiseaseState), size = 1.4) + 
ylab("Timing of peak") +
xlab("Base Infection Probability") +
theme_minimal() +
#ggtitle(network_top) +
theme(text = element_text(size = 37)) +
scale_x_continuous(breaks = seq(from = 0.1, to = 0.3, by = 0.025)) +
theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
theme(legend.position = "bottom", legend.title = element_blank()) +
theme(axis.ticks.x = element_line(),
      axis.ticks.y = element_line(),
      axis.ticks.length = unit(5, "pt"))

ggsave(paste0(str_split(file, "-")[[1]][[1]], "BaseSuscepVsPeakTiming.pdf"), dpi = 500, w = 9, h = 9)   
